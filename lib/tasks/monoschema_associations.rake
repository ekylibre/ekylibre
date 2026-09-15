# Inventaire des associations (point 1.16).
#
# Le mono-schéma change la clé : une association qui traverse deux tables du
# plan de données doit passer par `(tenant_id, colonne)`, ce qui se déclare en
# `foreign_key: %i[tenant_id …]` — `query_constraints:` étant refusé sur une
# association depuis Rails 8.1, le prototype l'a mesuré.
#
# Cette tâche ne modifie rien. Elle dit, association par association, ce qu'il
# faudra en faire, et surtout combien résistent à la mécanisation.
#
#   rake monoschema:associations

module MonoschemaAssociations
  OUTPUT_PATH = 'db/monoschema/associations.yml'.freeze

  module_function

  def plan
    @plan ||= YAML.load_file(Rails.root.join(MonoschemaPlan::PLAN_PATH))
  end

  def models
    @models ||= begin
      Rails.application.eager_load!
      ActiveRecord::Base.descendants.reject { |model| model.abstract_class? || model.name.nil? }
                        .select { |model| plan.dig(model.table_name, 'plane') == 'data' }
                        .sort_by(&:name)
    end
  end

  def plane_of(model)
    plan.dig(model.table_name, 'plane') || 'hors schéma'
  rescue StandardError
    'hors schéma'
  end

  # Ce qu'il faut faire de chaque association, et pourquoi.
  def verdict(reflection)
    return %w[through rien] if reflection.options[:through]
    return %w[polymorphe manuel] if reflection.polymorphic?
    return %w[habtm manuel] if reflection.macro == :has_and_belongs_to_many

    target = begin
      reflection.klass
    rescue StandardError
      nil
    end
    return ['cible inconnue', 'manuel'] if target.nil?
    return ['cible hors tenant', 'rien'] if plane_of(target) != 'data'

    ['clé composite', 'mécanisable']
  end

  def build
    inventory = models.to_h do |model|
      associations = model.reflect_on_all_associations.to_h do |reflection|
        kind, action = verdict(reflection)
        [reflection.name.to_s, { 'macro' => reflection.macro.to_s, 'cas' => kind, 'traitement' => action }]
      end
      [model.name, associations]
    end

    path = Rails.root.join(OUTPUT_PATH)
    path.write(<<~HEADER + inventory.to_yaml.sub(/\A---\n/, ''))
      # ENGENDRÉ PAR `rake monoschema:associations` — NE PAS MODIFIER À LA MAIN.
      #
      # Ce que devient chaque association des modèles du plan de données :
      #
      #   mécanisable -> `foreign_key: %i[tenant_id …]` posé par script
      #   rien        -> la cible n'a pas de tenant_id, ou l'association passe
      #                  par une autre (`:through`) qui porte déjà la contrainte
      #   manuel      -> polymorphe, HABTM, ou cible que le modèle ne dit pas
      #
    HEADER
    inventory
  end

  def summary(inventory)
    counts = Hash.new(0)
    inventory.each_value { |associations| associations.each_value { |entry| counts[entry['traitement']] += 1 } }
    cases = Hash.new(0)
    inventory.each_value { |associations| associations.each_value { |entry| cases[entry['cas']] += 1 } }
    [counts, cases]
  end

  def manual(inventory)
    inventory.flat_map do |model, associations|
      associations.filter_map { |name, entry| "#{model}##{name} (#{entry['cas']})" if entry['traitement'] == 'manuel' }
    end
  end
end

namespace :monoschema do
  desc 'Inventorie les associations à annoter et celles qui résistent'
  task associations: :environment do
    inventory = MonoschemaAssociations.build
    counts, cases = MonoschemaAssociations.summary(inventory)
    total = counts.values.sum

    puts "#{MonoschemaAssociations::OUTPUT_PATH} engendré : " \
         "#{inventory.size} modèles, #{total} associations."
    counts.sort_by { |_key, value| -value }.each { |key, value| puts format('  %<key>-14s %<value>d', key: key, value: value) }
    puts '  --'
    cases.sort_by { |_key, value| -value }.each { |key, value| puts format('  %<key>-18s %<value>d', key: key, value: value) }

    manual = MonoschemaAssociations.manual(inventory)
    puts "\n#{manual.size} associations à reprendre à la main :"
    manual.first(20).each { |line| puts "  #{line}" }
    puts "  … et #{manual.size - 20} autres" if manual.size > 20
  end
end
