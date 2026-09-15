# Tests d'isolation engendrés (point 1.20).
#
# Deux affirmations, pour *chacune* des 234 tables du plan de données :
#
#   — sans contexte de ferme, la table ne rend aucune ligne ;
#   — sous la ferme A, elle n'en rend jamais une de la ferme B.
#
# Elles ne se démontrent pas en lisant le schéma : il faut des lignes, et les
# lire avec le rôle applicatif. La tâche sème donc une ligne par table et par
# ferme — en ne remplissant que les colonnes obligatoires, avec des valeurs
# quelconques du bon type — puis relit tout sous chaque contexte.
#
#   rake monoschema:isolation
#
# Les tables qu'elle n'arrive pas à semer (contrainte `CHECK` qu'une valeur
# quelconque ne satisfait pas, par exemple) sont **signalées, pas ignorées** :
# une table non couverte est une affirmation non vérifiée.

module MonoschemaIsolation
  ALPHA = '11111111-1111-7111-8111-111111111111'.freeze
  BETA = '22222222-2222-7222-8222-222222222222'.freeze

  module_function

  def plan
    @plan ||= YAML.load_file(Rails.root.join(MonoschemaPlan::PLAN_PATH))
  end

  def data_tables
    plan.select { |_table, entry| entry['plane'] == 'data' }.keys.sort
  end

  def owner
    MonoschemaAudit.connection
  end

  def application
    @application ||= begin
      configurations = Rails.application.config.database_configuration
      config = configurations[Rails.env] || configurations['development']
      ApplicationRole.establish_connection(
        'adapter' => 'postgresql',
        'host' => config['host'].presence || 'db',
        'port' => config['port'],
        'database' => MonoschemaSchema::DATABASE,
        'username' => MonoschemaSchema::APP_ROLE,
        'password' => MonoschemaSchema::APP_ROLE
      )
      ApplicationRole.connection
    end
  end

  class ApplicationRole < ActiveRecord::Base
    self.abstract_class = true
  end

  # Une valeur quelconque, mais du bon type. Ce qui compte n'est pas son sens :
  # c'est qu'elle existe, et qu'elle appartienne à une ferme.
  def value_for(type)
    case type
    when /^(integer|bigint|smallint)/ then '1'
    when /^numeric|^double|^real/ then '0'
    when /^boolean/ then 'false'
    when /^uuid/ then 'uuidv7()'
    when /^jsonb?/ then "'{}'"
    when /^timestamp/ then 'now()'
    when /^date/ then 'now()::date'
    when /^interval/ then "'0 seconds'"
    when /geometry\(Point/i then "postgis.ST_SetSRID(postgis.ST_MakePoint(0, 0), 4326)"
    when /geometry\(MultiPolygon/i then "postgis.ST_Multi(postgis.ST_MakeEnvelope(0, 0, 1, 1, 4326))"
    when /geometry|geography/i then "postgis.ST_SetSRID(postgis.ST_MakePoint(0, 0), 4326)"
    else "'x'"
    end
  end

  def required_columns(table)
    owner.select_rows(<<~SQL)
      SELECT column_name, COALESCE(domain_name, udt_name), data_type
        FROM information_schema.columns
       WHERE table_schema = 'ekylibre' AND table_name = #{owner.quote(table)}
         AND is_nullable = 'NO' AND column_default IS NULL
         AND is_identity = 'NO' AND column_name <> 'tenant_id'
       ORDER BY ordinal_position
    SQL
  end

  def column_types(table)
    owner.select_rows(<<~SQL).to_h
      SELECT a.attname, format_type(a.atttypid, a.atttypmod)
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'ekylibre' AND c.relname = #{owner.quote(table)} AND a.attnum > 0 AND NOT a.attisdropped
    SQL
  end

  def seed(table, tenant_id)
    types = column_types(table)
    columns = required_columns(table).map(&:first)
    values = columns.map { |column| value_for(types[column].to_s) }
    quoted = columns.map { |column| owner.quote_column_name(column) }

    owner.execute(<<~SQL)
      INSERT INTO ekylibre.#{table} (tenant_id#{', ' unless columns.empty?}#{quoted.join(', ')})
      VALUES (#{owner.quote(tenant_id)}#{', ' unless values.empty?}#{values.join(', ')})
    SQL
    true
  rescue StandardError => e
    @last_error ||= {}
    @last_error[table] = e.message.lines.first.strip
    false
  end

  def last_error
    @last_error ||= {}
  end

  def prepare
    owner.execute('SET session_replication_role = replica')
    [[ALPHA, 'isolation_alpha'], [BETA, 'isolation_beta']].each do |id, slug|
      owner.execute(<<~SQL)
        INSERT INTO ekylibre.tenants (id, slug) VALUES (#{owner.quote(id)}, #{owner.quote(slug)})
        ON CONFLICT (id) DO NOTHING
      SQL
    end
  end

  # Lecture avec le rôle applicatif : c'est le seul point de vue qui compte.
  def visible(table, tenant_id)
    application.transaction do
      application.execute("SET LOCAL app.tenant_id = #{application.quote(tenant_id.to_s)}")
      application.select_rows("SELECT DISTINCT tenant_id FROM ekylibre.#{table}").flatten
    end
  end

  def run
    prepare
    seeded = []
    skipped = []

    data_tables.each do |table|
      owner.execute("DELETE FROM ekylibre.#{table}")
      if seed(table, ALPHA) && seed(table, BETA)
        seeded << table
      else
        skipped << table
      end
    end

    leaks = seeded.reject { |table| visible(table, ALPHA) == [ALPHA] }
    open = seeded.reject { |table| visible(table, '').empty? }

    { seeded: seeded, skipped: skipped, leaks: leaks, open: open }
  end
end

namespace :monoschema do
  desc 'Engendre et joue les tests d’isolation sur les 234 tables du plan de données'
  task isolation: :environment do
    result = MonoschemaIsolation.run
    total = result[:seeded].size + result[:skipped].size

    puts "  #{result[:seeded].size} tables sur #{total} semées dans deux fermes et relues par le rôle applicatif"
    puts "  ✓ sous la ferme A, aucune ne rend une ligne de B" if result[:leaks].empty?
    puts "  ✓ sans contexte, aucune ne rend quoi que ce soit" if result[:open].empty?

    if result[:skipped].any?
      raisons = MonoschemaIsolation.last_error.values.tally.sort_by { |_message, count| -count }
      puts "\n  #{result[:skipped].size} tables n'ont pas pu être semées — affirmation non vérifiée :"
      raisons.first(5).each { |message, count| puts "    #{count} × #{message[0, 120]}" }
      puts
      result[:skipped].each_slice(4) { |slice| puts "    #{slice.join('  ')}" }
    end

    if result[:leaks].any? || result[:open].any?
      abort "\n  ✗ fuite : #{(result[:leaks] + result[:open]).uniq.first(10).join(', ')}"
    end
  end
end
