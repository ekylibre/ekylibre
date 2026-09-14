# Résolution des références (préalable du point 1.6).
#
# Le schéma ne déclare que 159 clés étrangères là où 880 colonnes en `_id`
# désignent une ligne. Le générateur de migrations ne peut donc pas savoir, du
# seul schéma, ce que `intervention_parameters.intervention_id` référence. Les
# modèles le savent : c'est ce que `belongs_to` déclare.
#
# Cette tâche lit les réflexions d'ActiveRecord et écrit
# `db/monoschema/references.yml` : pour chaque colonne, la table visée et le
# plan de cette table. Ce que les modèles ne savent pas non plus est listé à
# part — c'est ce qui restera à traiter à la main.
#
#   rake monoschema:references
#
# Les associations polymorphes sont relevées séparément : une clé étrangère
# composite ne peut pas les porter, puisque la cible change d'une ligne à
# l'autre. Elles auront quand même leur `tenant_id`, mais pas de contrainte.

module MonoschemaReferences
  OUTPUT_PATH = 'db/monoschema/references.yml'.freeze

  module_function

  def plan
    @plan ||= YAML.load_file(Rails.root.join(MonoschemaPlan::PLAN_PATH))
  end

  def models
    @models ||= begin
      Rails.application.eager_load!
      ActiveRecord::Base.descendants.reject { |model| model.abstract_class? || model.name.nil? }
    end
  end

  def models_for(table)
    models.select { |model| model.table_name == table }
  end

  # Une table, ses colonnes de référence, et ce que les modèles en disent.
  def resolve(table, entry)
    columns = entry['implicit_references'] + entry['references'].map { |reference| reference['columns'] }
    declared = entry['references'].to_h { |reference| [reference['columns'], reference['table']] }
    reflections = reflections_for(table)

    columns.uniq.sort.filter_map do |column|
      next if column.include?(', ')

      target = declared[column] || reflections[column]
      [column, describe(column, target)]
    end.to_h
  end

  def reflections_for(table)
    models_for(table).each_with_object({}) do |model, index|
      model.reflect_on_all_associations(:belongs_to).each do |reflection|
        key = reflection.foreign_key.to_s
        index[key] = reflection.polymorphic? ? :polymorphic : safe_table_name(reflection)
      rescue StandardError
        index[key] ||= nil
      end
    end
  end

  def safe_table_name(reflection)
    reflection.klass.table_name
  rescue StandardError
    nil
  end

  def describe(_column, target)
    return { 'target' => nil, 'plane' => 'inconnu' } if target.nil?
    return { 'target' => 'polymorphe', 'plane' => 'polymorphe' } if target == :polymorphic

    { 'target' => target, 'plane' => plan.dig(target, 'plane') || 'hors schéma' }
  end

  def build
    resolved = plan.filter_map do |table, entry|
      next unless entry['plane'] == 'data'

      [table, resolve(table, entry)]
    end.to_h

    path = Rails.root.join(OUTPUT_PATH)
    path.write(<<~HEADER + resolved.to_yaml.sub(/\A---\n/, ''))
      # ENGENDRÉ PAR `rake monoschema:references` — NE PAS MODIFIER À LA MAIN.
      #
      # Pour chaque colonne de référence d'une table du plan de données, la table
      # visée telle que les `belongs_to` des modèles la déclarent, et le plan de
      # cette table :
      #
      #   data        -> la clé étrangère devient composite (tenant_id, colonne)
      #   reference   -> elle reste simple : la cible n'a pas de tenant_id
      #   control     -> idem
      #   polymorphe  -> aucune contrainte possible, la cible change par ligne
      #   inconnu     -> aucun modèle ne le dit ; à traiter à la main
      #
    HEADER
    resolved
  end

  def summary(resolved)
    counts = Hash.new(0)
    resolved.each_value { |columns| columns.each_value { |entry| counts[entry['plane']] += 1 } }
    counts
  end

  def unknowns(resolved)
    resolved.flat_map do |table, columns|
      columns.filter_map { |column, entry| "#{table}.#{column}" if entry['plane'] == 'inconnu' }
    end
  end
end

namespace :monoschema do
  desc 'Résout les références des modèles et engendre db/monoschema/references.yml'
  task references: :environment do
    resolved = MonoschemaReferences.build
    puts "#{MonoschemaReferences::OUTPUT_PATH} engendré."
    MonoschemaReferences.summary(resolved).sort_by { |_plane, count| -count }.each do |plane, count|
      puts format('  %<plane>-14s %<count>d colonnes', plane: plane, count: count)
    end

    unknowns = MonoschemaReferences.unknowns(resolved)
    puts "\n#{unknowns.size} colonnes qu'aucun modèle ne résout :" if unknowns.any?
    unknowns.each_slice(4) { |slice| puts "  #{slice.join('  ')}" }
  end
end
