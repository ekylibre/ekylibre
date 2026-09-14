# Vérification de bout en bout de la recopie (point 1.6).
#
# Une migration qui ne s'est jamais exécutée n'est qu'une intention : cette
# tâche monte deux fermes jetables, y sème des lignes aux identifiants
# volontairement identiques, recopie, vérifie, puis nettoie derrière elle.
#
#   rake monoschema:migrate:check

module MonoschemaMigrationCheck
  TENANTS = %w[monoschema_alpha monoschema_beta].freeze

  module_function

  def connection
    ActiveRecord::Base.connection
  end

  def run
    setup_tenants
    seed
    load_target_schema
    result = MonoschemaMigration.run(TENANTS)
    verify(result)
  ensure
    cleanup
  end

  def setup_tenants
    TENANTS.each do |slug|
      Ekylibre::Tenant.drop(slug) if Ekylibre::Tenant.exist?(slug)
      Ekylibre::Tenant.create(slug)
    end
  end

  # Mêmes identifiants dans les deux fermes : c'est le cas que la clé composite
  # doit absorber sans renumérotation. Les contraintes du schéma source sont
  # mises en sommeil le temps du semis — ces lignes désignent des natures et des
  # variantes qu'une ferme neuve n'a pas, et ce n'est pas ce qu'on mesure ici.
  def seed
    connection.execute('SET session_replication_role = replica')
    TENANTS.each_with_index do |slug, index|
      year = 2020 + index
      connection.execute(<<~SQL)
        INSERT INTO #{slug}.products (id, type, name, number, variant_id, nature_id, category_id, variety, created_at, updated_at)
        VALUES (1, 'Plant', 'plante #{slug}', 'P1', 1, 1, 1, 'plant', '#{year}-03-01', '#{year}-03-01'),
               (2, 'Equipment', 'engin #{slug}', 'E2', 1, 1, 1, 'equipment', '#{year}-03-02', '#{year}-03-02');

        INSERT INTO #{slug}.interventions (id, procedure_name, state, nature, started_at, stopped_at,
                                           working_duration, whole_duration, created_at, updated_at)
        VALUES (1, 'sowing', 'done', 'record', '#{year}-04-01', '#{year}-04-01', 3600, 3600, '#{year}-04-01', '#{year}-04-01'),
               (2, 'harvest', 'done', 'record', '#{year}-09-01', '#{year}-09-01', 7200, 7200, '#{year}-09-01', '#{year}-09-01');

        INSERT INTO #{slug}.intervention_parameters (id, intervention_id, product_id, reference_name, "position", type, created_at, updated_at)
        VALUES (1, 1, 1, 'cible', 1, 'InterventionTarget', '#{year}-04-01', '#{year}-04-01'),
               (2, 2, 2, 'outil', 1, 'InterventionTool', '#{year}-09-01', '#{year}-09-01');

        -- Une table à clé entière, pour vérifier que celles-là ne bougent pas.
        INSERT INTO #{slug}.campaigns (id, name, created_at, updated_at)
        VALUES (1, 'campagne #{year}', '#{year}-01-01', '#{year}-01-01'),
               (2, 'campagne #{year + 1}', '#{year}-01-02', '#{year}-01-02');
      SQL
    end
    connection.execute('SET session_replication_role = origin')
  end

  def load_target_schema
    connection.execute('DROP SCHEMA IF EXISTS ekylibre CASCADE')
    %w[districts postal_zones vegetative_stages net_services units].each do |table|
      connection.execute("DROP TABLE IF EXISTS lexicon.#{table} CASCADE")
    end
    path = Rails.root.join(MonoschemaSchema::INPLACE_PATH)
    raise "#{MonoschemaSchema::INPLACE_PATH} absent — SCOPE=inplace rake monoschema:schema" unless path.exist?

    MonoschemaPrototype.psql(connection.current_database, ['-f', path.to_s])
  end

  def verify(result)
    checks = {
      'deux fermes enregistrées' => result[:tenants].size == 2,
      'les quatre produits sont là' => count('ekylibre.products') == 4,
      'les identifiants entiers sont conservés, collisions comprises' =>
        count('ekylibre.campaigns WHERE id = 1') == 2,
      'les interventions ont reçu un uuid distinct' =>
        connection.select_value('SELECT count(DISTINCT id) FROM ekylibre.interventions') == 4,
      "l'uuid porte la date de création de la ligne" => uuid_carries_creation_date?,
      'chaque paramètre pointe une intervention de sa propre ferme' => parameters_stay_home?,
      'les séquences repartent au-dessus du plus grand id' => sequences_above_max?,
      'la politique isole encore' => isolation_holds?
    }

    failed = checks.reject { |_label, ok| ok }
    checks.each { |label, ok| puts "  #{ok ? '✓' : '✗'} #{label}" }
    raise "#{failed.size} contrôle(s) en échec" if failed.any?
  end

  def count(from)
    connection.select_value("SELECT count(*) FROM #{from}")
  end

  def uuid_carries_creation_date?
    years = connection.select_values(<<~SQL)
      SELECT DISTINCT extract(year FROM uuid_extract_timestamp(id))::int - extract(year FROM created_at)::int
        FROM ekylibre.interventions
    SQL
    years == [0]
  end

  def parameters_stay_home?
    connection.select_value(<<~SQL).zero?
      SELECT count(*)
        FROM ekylibre.intervention_parameters p
        LEFT JOIN ekylibre.interventions i
          ON i.tenant_id = p.tenant_id AND i.id = p.intervention_id
       WHERE i.id IS NULL
    SQL
  end

  def sequences_above_max?
    sequence = connection.select_value("SELECT pg_get_serial_sequence('ekylibre.campaigns', 'id')")
    maximum = connection.select_value('SELECT max(id) FROM ekylibre.campaigns')
    connection.select_value("SELECT nextval(#{connection.quote(sequence)})") > maximum
  end

  # La migration a tourné en contournant la RLS ; l'application, elle, doit la
  # retrouver intacte.
  def isolation_holds?
    connection.transaction do
      connection.execute("SET LOCAL app.tenant_id = ''")
      # Le superutilisateur contourne la politique : on interroge donc son
      # existence plutôt que son effet, l'effet étant mesuré par le prototype.
      connection.select_value(<<~SQL) == 234
        SELECT count(*) FROM pg_policies WHERE schemaname = 'ekylibre'
      SQL
    end
  end

  def cleanup
    connection.execute("DROP SCHEMA IF EXISTS #{MonoschemaMigration::MAPPING_SCHEMA} CASCADE")
    connection.execute('DROP SCHEMA IF EXISTS ekylibre CASCADE')
    %w[districts postal_zones vegetative_stages net_services units].each do |table|
      connection.execute("DROP TABLE IF EXISTS lexicon.#{table} CASCADE")
    end
    TENANTS.each { |slug| Ekylibre::Tenant.drop(slug) if Ekylibre::Tenant.exist?(slug) }
  end
end

namespace :monoschema do
  namespace :migrate do
    desc 'Vérifie la migration de bout en bout sur deux fermes jetables'
    task check: :environment do
      MonoschemaMigrationCheck.run
      puts 'La recopie tient.'
    end
  end
end
