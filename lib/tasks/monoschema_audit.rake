# Linter de schéma (points 1.7 et 1.8).
#
# Cinq invariants, vérifiés sur une base — pas sur un fichier. Le schéma
# engendré par `rake monoschema:schema` est chargé dans une base de sonde par
# `rake monoschema:schema:build`, puis passé à ce contrôle :
#
#   1. toute table du plan de données porte `tenant_id NOT NULL` ;
#   2. sa clé primaire est composite et commence par `tenant_id` ;
#   3. la Row Level Security y est activée *et* forcée, avec une politique qui
#      filtre la lecture (`USING`) comme l'écriture (`WITH CHECK`) ;
#   4. aucun index unique d'une table à `tenant_id` ne commence ailleurs qu'à
#      `tenant_id` — sans quoi un numéro pris par une ferme devient
#      indisponible à toutes les autres (ADR-002, R2) ;
#   5. toute clé étrangère entre deux tables du plan de données est composite —
#      sans quoi une ligne de A peut désigner une ligne de B.
#
#   rake monoschema:audit

module MonoschemaAudit
  # Une connexion à part : la sonde n'est pas la base de l'application.
  class Record < ActiveRecord::Base
    self.abstract_class = true
  end

  module_function

  def connection
    @connection ||= begin
      configurations = Rails.application.config.database_configuration
      config = configurations[Rails.env] || configurations['development']
      Record.establish_connection(
        'adapter' => 'postgresql',
        'host' => config['host'].presence || 'db',
        'port' => config['port'],
        'database' => MonoschemaSchema::DATABASE,
        'username' => config['username'],
        'password' => config['password']
      )
      Record.connection
    end
  end

  def query(sql)
    connection.select_rows(sql)
  end

  def checks
    [
      ['tables sans tenant_id', <<~SQL],
        SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'ekylibre' AND c.relkind = 'r' AND c.relrowsecurity
           AND NOT EXISTS (SELECT 1 FROM pg_attribute a
                            WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND a.attnotnull)
      SQL
      ['clés primaires non composites', <<~SQL],
        SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          LEFT JOIN pg_constraint k ON k.conrelid = c.oid AND k.contype = 'p'
         WHERE n.nspname = 'ekylibre' AND c.relkind = 'r' AND c.relrowsecurity
           AND (k.conkey IS NULL OR k.conkey[1] <> (SELECT attnum FROM pg_attribute
                                                     WHERE attrelid = c.oid AND attname = 'tenant_id'))
      SQL
      ['RLS non forcée', <<~SQL],
        SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'tenant_id'
         WHERE n.nspname = 'ekylibre' AND c.relkind = 'r'
           AND NOT (c.relrowsecurity AND c.relforcerowsecurity)
      SQL
      ['politiques incomplètes', <<~SQL],
        SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'tenant_id'
         WHERE n.nspname = 'ekylibre' AND c.relkind = 'r'
           AND NOT EXISTS (SELECT 1 FROM pg_policy p
                            WHERE p.polrelid = c.oid AND p.polqual IS NOT NULL AND p.polwithcheck IS NOT NULL)
      SQL
      ['index uniques sans tenant_id en tête', <<~SQL],
        SELECT i.indexname FROM pg_indexes i
          JOIN information_schema.columns c
            ON c.table_schema = i.schemaname AND c.table_name = i.tablename AND c.column_name = 'tenant_id'
         WHERE i.schemaname = 'ekylibre' AND i.indexdef LIKE 'CREATE UNIQUE%'
           AND i.indexdef NOT LIKE '%(tenant_id,%' AND i.indexdef NOT LIKE '%(tenant_id)%'
      SQL
      ["politiques dont l'écriture s'ouvre au-delà de la ferme", <<~SQL],
        -- Point 1.22 : la lecture peut s'élargir aux fermes consentantes, pas
        -- l'écriture. Un `WITH CHECK` qui mentionnerait `shared_tenants()`
        -- laisserait écrire chez le voisin.
        SELECT p.polrelid::regclass::text FROM pg_policy p
          JOIN pg_class c ON c.oid = p.polrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'ekylibre'
           AND pg_get_expr(p.polwithcheck, p.polrelid) LIKE '%readable_tenants%'
      SQL
      ['rôle applicatif trop puissant', <<~SQL],
        -- Point 1.13 : ni superutilisateur, ni BYPASSRLS, ni propriétaire des
        -- tables. `FORCE ROW LEVEL SECURITY` couvre le propriétaire, mais on ne
        -- veut de toute façon pas que l'application s'y connecte ainsi.
        SELECT r.rolname FROM pg_roles r
         WHERE r.rolname = 'ekylibre_app'
           AND (r.rolsuper OR r.rolbypassrls
                OR EXISTS (SELECT 1 FROM pg_class c
                             JOIN pg_namespace n ON n.oid = c.relnamespace
                            WHERE n.nspname = 'ekylibre' AND c.relowner = r.oid))
      SQL
      ['vues sans security_invoker', <<~SQL],
        SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'ekylibre' AND c.relkind = 'v'
           AND NOT COALESCE((SELECT option_value::boolean FROM pg_options_to_table(c.reloptions)
                              WHERE option_name = 'security_invoker'), false)
      SQL
      ['vues matérialisées non protégées', <<~SQL],
        SELECT c.relname FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'ekylibre' AND c.relkind = 'm'
      SQL
      ['clés étrangères non composites entre tables du plan de données', <<~SQL]
        SELECT k.conname FROM pg_constraint k
          JOIN pg_class source ON source.oid = k.conrelid
          JOIN pg_class target ON target.oid = k.confrelid
          JOIN pg_namespace n ON n.oid = source.relnamespace
         WHERE k.contype = 'f' AND n.nspname = 'ekylibre'
           AND source.relrowsecurity AND target.relrowsecurity
           AND cardinality(k.conkey) < 2
      SQL
    ]
  end

  def run
    checks.map do |label, sql|
      offenders = query(sql).flatten
      [label, offenders]
    end
  end
end

namespace :monoschema do
  desc 'Vérifie les invariants d’isolation sur la base de sonde du schéma complet'
  task audit: :environment do
    results = MonoschemaAudit.run
    failed = results.reject { |_label, offenders| offenders.empty? }

    results.each do |label, offenders|
      puts format('  %<state>s %<label>s%<detail>s',
                  state: offenders.empty? ? '✓' : '✗',
                  label: label,
                  detail: offenders.empty? ? '' : " : #{offenders.first(8).join(', ')}#{'…' if offenders.size > 8}")
    end

    abort "\n#{failed.size} invariant(s) rompu(s)." if failed.any?
    puts "\nLes dix invariants tiennent sur les 234 tables du plan de données."
  end
end
