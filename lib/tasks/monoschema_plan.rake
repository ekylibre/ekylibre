# Classification des tables en trois plans (point 1.5 de la feuille de route v6).
#
#   contrôle    — global, hors RLS : infrastructure et identité inter-fermes ;
#   données     — une ferme, une ligne : `tenant_id` et RLS ;
#   référentiel — partagé et lu seulement : le schéma `lexicon`.
#
# Le plan est *engendré*, jamais tenu à la main : `db/monoschema/plan.yml` naît
# de `db/structure.sql` et de `db/monoschema/classification.yml`, qui ne porte
# que les décisions — les exceptions au plan de données, le choix de clé, et les
# questions restées ouvertes. Tout le reste se mesure.
#
#   rake monoschema:classify   # (re)engendre db/monoschema/plan.yml et résume
#   rake monoschema:check      # échoue si une table n'est pas classée
#
# `check` est la graine du linter de schéma du point 1.7 : une migration qui
# ajoute une table sans la classer met la CI au rouge, au lieu de laisser la
# table sans `tenant_id` jusqu'à ce qu'un client voie les données d'un autre.

require 'yaml'

module MonoschemaPlan
  CLASSIFICATION_PATH = 'db/monoschema/classification.yml'.freeze
  PLAN_PATH = 'db/monoschema/plan.yml'.freeze
  REFERENCE_SCHEMA = 'lexicon'.freeze

  module_function

  def structure
    @structure ||= Rails.root.join('db', 'structure.sql').read
  end

  def classification
    @classification ||= YAML.load_file(Rails.root.join(CLASSIFICATION_PATH))
  end

  def tables
    structure.scan(/^CREATE TABLE (\w+)\.(\w+) \(/).map { |schema, table| [schema, table] }
  end

  # --- Mesures tirées de db/structure.sql ---------------------------------

  def columns(schema, table)
    body = structure[/CREATE TABLE #{schema}\.#{table} \((.*?)\n\);/m, 1]
    body.strip.lines.filter_map do |line|
      line = line.strip.chomp(',')
      next if line.start_with?('CONSTRAINT')

      name = line[/\A"?([a-z_0-9]+)"?\s/, 1]
      next if name.nil?

      [name, line.sub(/\A"?#{name}"?\s+/, '')]
    end.to_h
  end

  def indexes(schema, table)
    structure.scan(/^CREATE (UNIQUE )?INDEX (\S+) ON #{schema}\.#{table} USING (\w+) \((.*)\);$/)
             .map { |unique, name, method, cols| { 'name' => name, 'unique' => !unique.nil?, 'method' => method, 'columns' => cols } }
  end

  def foreign_keys(schema, table)
    pattern = /ALTER TABLE ONLY #{schema}\.#{table}\n    ADD CONSTRAINT (\S+) FOREIGN KEY \((.*?)\) REFERENCES (\w+)\.(\w+)\((.*?)\)/
    structure.scan(pattern).map do |name, columns, target_schema, target_table, target_columns|
      { 'name' => name, 'columns' => columns, 'references' => "#{target_schema}.#{target_table}", 'target' => target_columns }
    end
  end

  def primary_key(schema, table)
    constraint = structure[/ALTER TABLE ONLY #{schema}\.#{table}\n    ADD CONSTRAINT \S+ PRIMARY KEY \((.*?)\)/, 1]
    constraint&.split(', ')
  end

  def geometry_columns(columns)
    columns.select { |_name, type| type.start_with?('postgis.geometry', 'postgis.geography') }.keys
  end

  # --- Plan ----------------------------------------------------------------

  def plane_of(schema, table)
    return 'reference' if schema == REFERENCE_SCHEMA
    return 'control' if classification.fetch('control', {}).key?(table)

    'data'
  end

  def id_type_of(table, columns)
    return 'none' unless columns.key?('id')
    return 'uuid' if classification.fetch('uuid_v7', {}).key?(table)

    'bigint'
  end

  def entry(schema, table)
    cols = columns(schema, table)
    plane = plane_of(schema, table)
    all_indexes = indexes(schema, table)
    declared = foreign_keys(schema, table)
    {
      'schema' => schema,
      'plane' => plane,
      'reason' => reason_for(plane, table),
      'id' => id_type_of(table, cols),
      'primary_key' => primary_key(schema, table),
      'sti' => cols.key?('type'),
      'geometry' => geometry_columns(cols),
      'unique_indexes' => all_indexes.select { |index| index['unique'] }.map { |index| index['name'] },
      'indexes' => all_indexes.size,
      # Les clés étrangères *déclarées*, avec le plan de leur cible : une
      # référence vers le plan de données devient composite, une référence vers
      # le référentiel ou le contrôle ne le peut pas — ces tables-là n'ont pas
      # de `tenant_id`.
      'references' => declared.map { |fk| reference_entry(fk) },
      # Et celles qui ne sont pas déclarées. Le schéma ne porte que 171 clés
      # étrangères là où plus de mille colonnes en `_id` désignent une ligne :
      # `intervention_parameters.intervention_id` n'a aucune contrainte
      # aujourd'hui. Le générateur du point 1.6 doit savoir qu'il travaille
      # surtout à l'aveugle.
      'implicit_references' => implicit_references(cols, declared, integer: true),
      # Les colonnes en `_id` qui ne portent pas un entier désignent un
      # référentiel par son code — `usage_id` pointe une ligne du `lexicon`.
      # Elles ne deviennent *pas* composites : leur cible n'a pas de `tenant_id`.
      'code_references' => implicit_references(cols, declared, integer: false),
      'columns' => cols.size
    }.compact
  end

  def reference_entry(foreign_key)
    target_schema, target_table = foreign_key['references'].split('.')
    {
      'columns' => foreign_key['columns'],
      'table' => target_table,
      'plane' => plane_of(target_schema, target_table)
    }
  end

  def implicit_references(columns, declared, integer:)
    declared_columns = declared.flat_map { |fk| fk['columns'].split(', ') }
    columns.filter_map do |name, type|
      next unless name.end_with?('_id')
      next if declared_columns.include?(name)
      next if type.start_with?('integer', 'bigint') != integer

      name
    end
  end

  def reason_for(plane, table)
    case plane
    when 'control' then classification.fetch('control')[table]
    when 'reference' then 'schéma lexicon : référentiel partagé, lu seulement'
    end
  end

  def build
    plan = tables.sort.to_h { |schema, table| [table, entry(schema, table)] }
    path = Rails.root.join(PLAN_PATH)
    path.dirname.mkpath
    path.write(<<~HEADER + plan.to_yaml.sub(/\A---\n/, ''))
      # ENGENDRÉ PAR `rake monoschema:classify` — NE PAS MODIFIER À LA MAIN.
      #
      # Les décisions sont dans #{CLASSIFICATION_PATH} ; tout ce qui est ici en
      # découle ou se mesure sur db/structure.sql. Ce fichier est ce que lira le
      # générateur de migrations du point 1.6.
      #
      #   plane   : control (global, hors RLS) | data (tenant, RLS) | reference (lexicon)
      #   id      : type visé pour la clé primaire — uuid pour ce que le terrain
      #             crée hors ligne (ADR-003), bigint sinon, none si la table n'a
      #             pas de colonne `id`
      #
    HEADER
    plan
  end

  def summary(plan)
    data = plan.select { |_table, entry| entry['plane'] == 'data' }
    {
      'tables' => plan.size,
      'contrôle' => plan.count { |_t, e| e['plane'] == 'control' },
      'données' => data.size,
      'référentiel' => plan.count { |_t, e| e['plane'] == 'reference' },
      'clés uuidv7' => data.count { |_t, e| e['id'] == 'uuid' },
      'clés bigint' => data.count { |_t, e| e['id'] == 'bigint' },
      'sans clé primaire' => plan.count { |_t, e| e['primary_key'].nil? },
      'PK composites à poser' => data.count { |_t, e| e['id'] != 'none' },
      'index uniques à préfixer' => data.sum { |_t, e| e['unique_indexes'].size },
      'FK déclarées, cible au plan de données' => data.sum { |_t, e| e['references'].count { |r| r['plane'] == 'data' } },
      'FK déclarées, cible hors tenant' => data.sum { |_t, e| e['references'].count { |r| r['plane'] != 'data' } },
      'références implicites (entier, sans FK)' => data.sum { |_t, e| e['implicit_references'].size },
      'références par code (référentiel)' => data.sum { |_t, e| e['code_references'].size },
      'colonnes géométriques' => data.sum { |_t, e| e['geometry'].size },
      'tables STI' => data.count { |_t, e| e['sti'] },
      'tables géométriques' => data.count { |_t, e| e['geometry'].any? }
    }
  end

  # Une table nouvelle est une table non classée : elle doit passer par une
  # décision, pas par un défaut silencieux. Les tables du plan de données sont
  # le défaut assumé, mais le fichier de décisions doit les avoir vues — c'est
  # ce que vérifie `known`.
  def unknown_tables
    known = classification.fetch('control', {}).keys +
            classification.fetch('data', []) +
            classification.fetch('review', {}).keys
    tables.filter_map { |schema, table| table if schema != REFERENCE_SCHEMA && known.exclude?(table) }
  end
end

namespace :monoschema do
  desc 'Classe les tables en trois plans et engendre db/monoschema/plan.yml'
  task classify: :environment do
    plan = MonoschemaPlan.build
    puts "#{MonoschemaPlan::PLAN_PATH} engendré."
    MonoschemaPlan.summary(plan).each { |label, value| puts format('  %<label>-38s %<value>s', label: label, value: value) }

    open_questions = MonoschemaPlan.classification.fetch('review', {})
    puts "\n#{open_questions.size} tables restent à trancher :" if open_questions.any?
    open_questions.each { |table, question| puts "  #{table} — #{question}" }
  end

  desc "Échoue si une table de db/structure.sql n'est classée nulle part"
  task check: :environment do
    unknown = MonoschemaPlan.unknown_tables
    if unknown.any?
      abort <<~TEXT
        #{unknown.size} table(s) ne sont classées dans aucun plan :
          #{unknown.join("\n  ")}

        Ajouter chacune à #{MonoschemaPlan::CLASSIFICATION_PATH} — `data:` si elle
        porte les données d'une ferme, `control:` si elle est globale, `review:`
        si la question n'est pas tranchée. Le plan de données est le défaut, mais
        il doit être choisi : une table oubliée est une table sans `tenant_id`.
      TEXT
    end
    puts "Toutes les tables de db/structure.sql sont classées (#{MonoschemaPlan.tables.size})."
  end
end
