# Ce que `units` porte et que le lexicon n'a pas (préalable de la fusion
# décidée au point 1.5).
#
# Les fermes créent leurs propres unités : conditionnements, unités de travail,
# variantes locales. Les passer au référentiel partagé suppose de savoir
# lesquelles y manquent — et de les proposer au dépôt Lexicon plutôt que de les
# perdre.
#
#   rake monoschema:units_gap TENANTS=demo,autre
#
# Le résultat est un fichier prêt à relire, pas une migration : c'est une
# proposition d'ajout au référentiel, à valider par qui en a la charge.

module MonoschemaUnits
  OUTPUT_PATH = 'db/monoschema/units-absentes-du-lexicon.yml'.freeze

  module_function

  def connection
    ActiveRecord::Base.connection
  end

  def tenants
    ENV.fetch('TENANTS', '').split(',').map(&:strip).reject(&:empty?).presence ||
      Ekylibre::Tenant.list
  end

  def known_reference_names
    @known_reference_names ||= connection.select_values('SELECT reference_name FROM lexicon.master_units').to_set
  end

  # Une unité manque si son `reference_name` n'est pas au référentiel. Celles
  # qui n'ont pas de `reference_name` du tout manquent aussi : ce sont des
  # créations locales, et c'est précisément ce qu'on cherche.
  def gaps_for(tenant)
    connection.select_all(<<~SQL).to_a
      SELECT u.reference_name, u.name, u.symbol, u.dimension, u.type, u.coefficient, u.work_code,
             (SELECT b.reference_name FROM #{tenant}.units b WHERE b.id = u.base_unit_id) AS base_unit,
             -- Les dix colonnes qui désignent une unité, mesurées au point 1.5.
             -- En compter moins ferait passer une unité employée pour morte.
             (SELECT count(*) FROM #{tenant}.products p WHERE p.conditioning_unit_id = u.id) AS produits,
             (SELECT count(*) FROM #{tenant}.product_nature_variants v WHERE v.default_unit_id = u.id) AS variantes,
             (SELECT count(*) FROM #{tenant}.catalog_items c WHERE c.unit_id = u.id) AS articles_catalogue,
             (SELECT count(*) FROM #{tenant}.activity_budget_items b WHERE b.unit_id = u.id) AS lignes_budget,
             (SELECT count(*) FROM #{tenant}.daily_charges d WHERE d.quantity_unit_id = u.id) AS charges,
             (SELECT count(*) FROM #{tenant}.parcel_items pi WHERE pi.conditioning_unit_id = u.id) AS lignes_livraison,
             (SELECT count(*) FROM #{tenant}.parcel_item_storings ps WHERE ps.conditioning_unit_id = u.id) AS stockages,
             (SELECT count(*) FROM #{tenant}.units b2 WHERE b2.base_unit_id = u.id) AS unites_derivees,
             (SELECT count(*) FROM #{tenant}.sale_items s WHERE s.conditioning_unit_id = u.id) AS lignes_de_vente,
             (SELECT count(*) FROM #{tenant}.purchase_items a WHERE a.conditioning_unit_id = u.id) AS lignes_achat
        FROM #{tenant}.units u
       ORDER BY u.reference_name NULLS FIRST, u.name
    SQL
  rescue StandardError => e
    warn "  #{tenant} : #{e.message.lines.first.strip}"
    []
  end

  def build
    inventory = {}
    tenants.each do |tenant|
      gaps_for(tenant).each do |row|
        reference = row['reference_name']
        next if reference.present? && known_reference_names.include?(reference)

        key = reference.presence || "sans_reference/#{row['name']}"
        entry = inventory[key] ||= {
          'reference_name' => reference,
          'name' => row['name'],
          'symbol' => row['symbol'],
          'dimension' => row['dimension'],
          'type' => row['type'],
          'coefficient' => row['coefficient'].to_f,
          'base_unit' => row['base_unit'],
          'fermes' => [],
          'usages' => 0
        }
        entry['fermes'] |= [tenant]
        entry['usages'] += row.values_at('produits', 'variantes', 'articles_catalogue', 'lignes_budget',
                                         'charges', 'lignes_livraison', 'stockages', 'unites_derivees',
                                         'lignes_de_vente', 'lignes_achat').sum(&:to_i)
      end
    end

    path = Rails.root.join(OUTPUT_PATH)
    path.write(<<~HEADER + inventory.values.sort_by { |entry| [-entry['usages'], entry['name'].to_s] }.to_yaml.sub(/\A---\n/, ''))
      # ENGENDRÉ PAR `rake monoschema:units_gap` — à relire, puis à proposer au
      # dépôt Lexicon.
      #
      # Les unités que portent les fermes et que `lexicon.master_units` ne
      # connaît pas. Deux familles : celles qui ont un `reference_name` inconnu
      # du référentiel, et celles qui n'en ont aucun — créations locales.
      #
      # `usages` compte les lignes qui les emploient, sur les dix colonnes du
      # schéma qui désignent une unité — produits, variantes, catalogue,
      # budgets, charges, livraisons, stockages, ventes, achats, et les unités
      # qui en dérivent. C'est ce qui dit lesquelles comptent vraiment : une
      # unité à zéro usage peut disparaître sans rien casser.
      #
      # Ce fichier ne migre rien. Il dit ce qu'il faudrait ajouter au
      # référentiel pour que la fusion ne perde aucune donnée.
      #
    HEADER
    inventory
  end
end

namespace :monoschema do
  desc 'Recense les unités des fermes absentes du lexicon (TENANTS=a,b)'
  task units_gap: :environment do
    inventory = MonoschemaUnits.build
    puts "#{MonoschemaUnits::OUTPUT_PATH} engendré : #{inventory.size} unités absentes du référentiel."
    sans_reference = inventory.values.count { |entry| entry['reference_name'].blank? }
    employees = inventory.values.count { |entry| entry['usages'].positive? }
    puts "  #{sans_reference} sans `reference_name` — créations locales"
    puts "  #{employees} réellement employées par des lignes"
    inventory.values.sort_by { |entry| -entry['usages'] }.first(12).each do |entry|
      puts format('  %<usages>6d usages  %<name>-32s %<reference>s',
                  usages: entry['usages'], name: entry['name'].to_s[0, 32],
                  reference: entry['reference_name'] || '(sans référence)')
    end
  end
end
