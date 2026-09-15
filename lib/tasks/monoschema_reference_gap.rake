# Ce que les quatre référentiels des fermes porteraient au Lexicon (suite de la
# décision du 15 septembre : « les autres référentiels doivent être intégrés au
# Lexicon également »).
#
# `districts`, `postal_zones`, `vegetative_stages` et `net_services` vivent
# aujourd'hui dans chaque ferme. Les porter au référentiel partagé demande
# d'abord de savoir ce qu'ils contiennent, et si le Lexicon ne le porte pas déjà
# sous un autre nom.
#
#   rake monoschema:reference_gap TENANTS=demo
#
# Le résultat est un CSV par table, dédupliqué sur l'ensemble des fermes
# passées, dans la forme que le Lexicon charge. Ce n'est pas une migration :
# c'est de la matière pour une spec.

module MonoschemaReferenceGap
  OUTPUT_DIR = 'db/monoschema/referentiels'.freeze

  # Ce que chaque table deviendrait, et ce que le Lexicon porte déjà de
  # comparable. Les colonnes retenues sont celles qui ont un sens partagé : ni
  # `id`, ni `creator_id`, ni `lock_version`.
  TABLES = {
    'districts' => {
      columns: %w[code name],
      key: %w[code],
      lexicon: 'registered_administrative_areas',
      note: "Couvert par `registered_administrative_areas`. Le faible recouvrement mesuré ici vient du paquet Lexicon *allégé* de la base de développement, pas d'un manque du référentiel."
    },
    'postal_zones' => {
      columns: %w[postal_code city_name city code country],
      key: %w[country postal_code city_name],
      lexicon: 'registered_postal_codes',
      note: "Couvert par `registered_postal_codes`, qui porte toutes les communes dans le paquet complet. Les 86 lignes vues ici sont celles du paquet allégé."
    },
    'vegetative_stages' => {
      # Le format de `master_phenological_stages`, que la décision du
      # 15 septembre étend à toutes les variétés : un identifiant
      # `<code bbch>-<variété>`, comme la vigne l'emploie déjà, et un libellé
      # traduit. Les colonnes propres à la vigne — biaggiolini,
      # eichhorn_lorenz, chasselas_date — restent vides.
      columns: %w[bbch_number variety label],
      key: %w[variety bbch_number],
      lexicon: 'master_phenological_stages',
      lexicon_shape: true,
      note: "À verser dans `master_phenological_stages`, étendue au format générique (décision du 15 septembre)."
    },
    'net_services' => {
      columns: %w[reference_name],
      key: %w[reference_name],
      lexicon: nil,
      note: "Ne sert plus (décision du 15 septembre) : table supprimée plutôt que portée au référentiel."
    }
  }.freeze

  module_function

  def connection
    ActiveRecord::Base.connection
  end

  def tenants
    ENV.fetch('TENANTS', '').split(',').map(&:strip).reject(&:empty?).presence || Ekylibre::Tenant.list
  end

  def rows_for(table, spec)
    tenants.flat_map do |tenant|
      connection.select_all(
        "SELECT #{spec[:columns].join(', ')} FROM #{tenant}.#{table}"
      ).to_a
    rescue StandardError => e
      warn "  #{tenant}.#{table} : #{e.message.lines.first.strip}"
      []
    end
  end

  # Déduplication sur la clé métier : deux fermes qui portent la même ligne n'en
  # font qu'une. Ce que le point 1.5 appelait « conserver les données de base »
  # se traduit ici par : la première occurrence gagne, et les divergences sont
  # comptées pour qu'on les voie.
  def deduplicate(rows, key)
    seen = {}
    divergences = 0
    rows.each do |row|
      signature = row.values_at(*key)
      if seen.key?(signature)
        divergences += 1 if seen[signature] != row
      else
        seen[signature] = row
      end
    end
    [seen.values, divergences]
  end

  # Au format de la table du Lexicon, prête à y être versée : l'identifiant
  # suit la convention de la vigne (`00-vitis`), et le libellé est un objet
  # traduit. Les stades que le référentiel connaît déjà sont écartés.
  def write_phenological_stages(path, rows)
    known = connection.select_values('SELECT id FROM lexicon.master_phenological_stages').to_set
    CSV.open(path, 'w') do |csv|
      csv << %w[id bbch_code variety label_fra]
      rows.each do |row|
        identifier = "#{row['bbch_number']}-#{row['variety']}"
        next if known.include?(identifier)

        csv << [identifier, row['bbch_number'], row['variety'], row['label']]
      end
    end
  end

  def lexicon_count(table)
    return nil if table.nil?

    connection.select_value("SELECT count(*) FROM lexicon.#{table}")
  rescue StandardError
    nil
  end

  def build
    directory = Rails.root.join(OUTPUT_DIR)
    directory.mkpath

    TABLES.map do |table, spec|
      rows, divergences = deduplicate(rows_for(table, spec), spec[:key])
      path = directory.join("#{table}.csv")
      if spec[:lexicon_shape]
        write_phenological_stages(path, rows)
      else
        CSV.open(path, 'w') do |csv|
          csv << spec[:columns]
          rows.each { |row| csv << spec[:columns].map { |column| row[column] } }
        end
      end

      { table: table, rows: rows.size, divergences: divergences,
        lexicon: spec[:lexicon], lexicon_rows: lexicon_count(spec[:lexicon]), note: spec[:note] }
    end
  end
end

namespace :monoschema do
  desc 'Extrait les quatre référentiels des fermes pour le Lexicon (TENANTS=a,b)'
  task reference_gap: :environment do
    require 'csv'
    results = MonoschemaReferenceGap.build

    puts "#{MonoschemaReferenceGap::OUTPUT_DIR}/ — un CSV par table, dédupliqué sur #{MonoschemaReferenceGap.tenants.size} ferme(s)."
    results.each do |result|
      comparison = if result[:lexicon]
                     "#{result[:lexicon]} en porte #{result[:lexicon_rows]}"
                   else
                     'aucun équivalent au Lexicon'
                   end
      puts format('  %<table>-20s %<rows>5d lignes  (%<comparison>s)',
                  table: result[:table], rows: result[:rows], comparison: comparison)
      puts "      divergences entre fermes : #{result[:divergences]}" if result[:divergences].positive?
      puts "      #{result[:note]}"
    end
  end
end
