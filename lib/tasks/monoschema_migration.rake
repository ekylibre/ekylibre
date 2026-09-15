# Migration des données vers le mono-schéma (seconde moitié du point 1.6).
#
# Elle se mène **dans la base du client**, à côté des schémas par ferme : le
# schéma `ekylibre` est créé par `SCOPE=inplace rake monoschema:schema`, les
# lignes y sont recopiées ferme par ferme, puis les anciens schémas peuvent
# partir. Rien n'est renuméroté sans nécessité.
#
#   rake monoschema:migrate TENANTS=alpha,beta [DATABASE=ekylibre_development]
#
# Trois choses méritent d'être sues avant de la lire :
#
#   — **les clés entières sont conservées telles quelles.** Deux fermes ont
#     toutes deux un `products.id = 1` ; la clé primaire composite
#     `(tenant_id, id)` l'accepte. 194 tables sur 234 ne demandent donc aucun
#     remappage — c'est ce qui rend cette migration abordable ;
#   — **les 40 tables à clé UUIDv7 en demandent un**, et avec elles les 132
#     colonnes qui les désignent. Une table de correspondance par table et par
#     ferme porte l'ancien entier et le nouvel uuid ;
#   — **l'uuid engendré porte la date de création de la ligne.** PostgreSQL 18
#     accepte un décalage : `uuidv7(created_at - now())` donne un identifiant
#     dont le préfixe temporel est celui de la ligne, et non celui de la
#     migration. Sans cela, dix ans d'historique s'entasseraient au même
#     endroit de l'index.
#
# Elle s'exécute avec un rôle qui contourne la RLS — superutilisateur, ou
# propriétaire après `DISABLE ROW LEVEL SECURITY`. C'est une raison de plus pour
# que l'application, elle, ne s'y connecte jamais ainsi.

module MonoschemaMigration
  MAPPING_SCHEMA = 'monoschema_migration'.freeze

  module_function

  def plan
    @plan ||= YAML.load_file(Rails.root.join(MonoschemaPlan::PLAN_PATH))
  end

  def references
    @references ||= YAML.load_file(Rails.root.join(MonoschemaReferences::OUTPUT_PATH))
  end

  def data_tables
    @data_tables ||= plan.select { |_table, entry| entry['plane'] == 'data' }
  end

  def uuid_tables
    @uuid_tables ||= data_tables.select { |_table, entry| entry['id'] == 'uuid' }.keys
  end

  def connection
    ActiveRecord::Base.connection
  end

  def quote(value)
    connection.quote(value)
  end

  def columns_of(schema, table)
    connection.select_values(<<~SQL)
      SELECT column_name FROM information_schema.columns
       WHERE table_schema = #{quote(schema)} AND table_name = #{quote(table)}
       ORDER BY ordinal_position
    SQL
  end

  # --- Étapes --------------------------------------------------------------

  def register_tenants(tenants)
    tenants.to_h do |slug|
      existing = connection.select_value("SELECT id FROM ekylibre.tenants WHERE slug = #{quote(slug)}")
      id = existing || connection.select_value(
        "INSERT INTO ekylibre.tenants (slug) VALUES (#{quote(slug)}) RETURNING id"
      )
      [slug, id]
    end
  end

  # Une correspondance par table à clé uuid et par ferme. `created_at` sert de
  # préfixe temporel quand la table en porte un.
  def build_mappings(tenants)
    connection.execute("DROP SCHEMA IF EXISTS #{MAPPING_SCHEMA} CASCADE")
    connection.execute("CREATE SCHEMA #{MAPPING_SCHEMA}")

    uuid_tables.each do |table|
      connection.execute(<<~SQL)
        CREATE TABLE #{MAPPING_SCHEMA}.#{table} (
          tenant_id uuid NOT NULL, old_id bigint NOT NULL, new_id uuid NOT NULL,
          PRIMARY KEY (tenant_id, old_id)
        )
      SQL

      tenants.each do |slug, tenant_id|
        next unless table_exists?(slug, table)

        stamp = columns_of(slug, table).include?('created_at') ? 'uuidv7(created_at - now())' : 'uuidv7()'
        connection.execute(<<~SQL)
          INSERT INTO #{MAPPING_SCHEMA}.#{table} (tenant_id, old_id, new_id)
          SELECT #{quote(tenant_id)}, id, #{stamp} FROM #{slug}.#{table}
        SQL
      end
    end
  end

  def table_exists?(schema, table)
    connection.select_value(<<~SQL).present?
      SELECT 1 FROM information_schema.tables
       WHERE table_schema = #{quote(schema)} AND table_name = #{quote(table)}
    SQL
  end

  # La requête de recopie d'une table pour une ferme. Chaque colonne qui désigne
  # une table à clé uuid passe par sa correspondance ; les autres sont reprises
  # telles quelles.
  def copy_statement(slug, tenant_id, table, entry)
    source_columns = columns_of(slug, table)
    target_columns = columns_of('ekylibre', table) - ['tenant_id']
    shared = target_columns & source_columns

    joins = +''
    selects = shared.map do |column|
      quoted = connection.quote_column_name(column)
      target = column == 'id' ? table : references.dig(table, column, 'target')
      next "s.#{quoted}" unless uuid_tables.include?(target)

      alias_name = "m_#{column}"
      joins << <<~SQL
        LEFT JOIN #{MAPPING_SCHEMA}.#{target} #{alias_name}
               ON #{alias_name}.tenant_id = #{quote(tenant_id)} AND #{alias_name}.old_id = s.#{quoted}
      SQL
      "#{alias_name}.new_id"
    end

    # Les noms sont cités : `position`, `default`, `order` et quelques autres
    # sont des mots réservés, et le schéma en porte.
    quoted_columns = shared.map { |column| connection.quote_column_name(column) }

    <<~SQL
      INSERT INTO ekylibre.#{table} (tenant_id, #{quoted_columns.join(', ')})
      SELECT #{quote(tenant_id)}, #{selects.join(', ')}
        FROM #{slug}.#{table} s
        #{joins}
    SQL
  end

  def copy_tenant(slug, tenant_id)
    copied = 0
    data_tables.each do |table, entry|
      next unless table_exists?(slug, table)

      result = connection.execute(copy_statement(slug, tenant_id, table, entry))
      copied += result.cmd_tuples
    end
    copied
  end

  # Les colonnes d'identité partagent une séquence par table, tous tenants
  # confondus : elle doit repartir au-dessus du plus grand `id` recopié, sinon
  # la première création dans une ferme heurte une ligne existante (point 1.11).
  def reset_sequences
    reset = 0
    data_tables.each do |table, entry|
      next unless entry['id'] == 'bigint'

      sequence = connection.select_value(<<~SQL)
        SELECT pg_get_serial_sequence('ekylibre.#{table}', 'id')
      SQL
      next if sequence.blank?

      connection.execute(<<~SQL)
        SELECT setval(#{quote(sequence)}, COALESCE((SELECT max(id) FROM ekylibre.#{table}), 0) + 1, false)
      SQL
      reset += 1
    end
    reset
  end

  # Une transaction pour tout : une ferme à moitié restaurée serait pire qu'une
  # ferme absente. Mesuré sur le jeu de démonstration, la recopie tient en
  # quelques secondes — la durée d'une transaction n'est pas le problème ici,
  # et c'est un import, pas un chemin applicatif.
  def run(tenants)
    result = nil
    connection.transaction do
      connection.execute('SET LOCAL session_replication_role = replica')
      registered = register_tenants(tenants)
      build_mappings(registered)
      counts = registered.to_h { |slug, tenant_id| [slug, copy_tenant(slug, tenant_id)] }
      result = { tenants: registered, counts: counts, sequences: reset_sequences }
    end
    result
  end
end

namespace :monoschema do
  desc 'Recopie les schémas par ferme dans le schéma mono-base (TENANTS=a,b)'
  task migrate: :environment do
    tenants = ENV.fetch('TENANTS', '').split(',').map(&:strip).reject(&:empty?)
    abort 'TENANTS=alpha,beta attendu' if tenants.empty?

    result = MonoschemaMigration.run(tenants)
    result[:counts].each { |slug, rows| puts format('  %<slug>-24s %<rows>d lignes', slug: slug, rows: rows) }
    puts "  #{result[:sequences]} séquences replacées au-dessus du plus grand id"
  end
end
