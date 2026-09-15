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
      note: "Le Lexicon porte `registered_administrative_areas` (régions et départements) : un district y correspond peut-être déjà."
    },
    'postal_zones' => {
      columns: %w[postal_code city_name city code country],
      key: %w[country postal_code city_name],
      lexicon: 'registered_postal_codes',
      note: "Le Lexicon porte `registered_postal_codes`, mais partiellement — à compléter plutôt qu'à dupliquer."
    },
    'vegetative_stages' => {
      columns: %w[bbch_number variety label],
      key: %w[variety bbch_number],
      lexicon: 'master_phenological_stages',
      note: "Le Lexicon porte `master_phenological_stages`, orientée vigne (biaggiolini, eichhorn_lorenz, chasselas). Les stades des autres variétés y manquent."
    },
    'net_services' => {
      columns: %w[reference_name],
      key: %w[reference_name],
      lexicon: nil,
      note: "Aucun équivalent au Lexicon : table à créer, ou à supprimer si les six lignes ne servent plus."
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
      CSV.open(path, 'w') do |csv|
        csv << spec[:columns]
        rows.each { |row| csv << spec[:columns].map { |column| row[column] } }
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
