# coding: utf-8

class AtomizeInterventions < ActiveRecord::Migration
  TASK_TABLES = %i[product_enjoyments product_junctions product_links product_linkages product_localizations product_memberships product_ownerships product_phases product_reading_tasks].freeze
  POLYMORPHIC_REFERENCES = [
    %i[attachments resource],
    # [:interventions, :resource],
    %i[issues target],
    %i[journal_entries resource],
    %i[observations subject],
    %i[preferences record_value],
    %i[product_enjoyments originator],
    %i[product_junctions originator],
    %i[product_linkages originator],
    %i[product_links originator],
    %i[product_localizations originator],
    %i[product_memberships originator],
    %i[product_ownerships originator],
    %i[product_phases originator],
    %i[product_reading_tasks originator],
    %i[product_readings originator],
    %i[versions item]
  ].freeze

  def change
    revert { add_reference :interventions, :resource, polymorphic: true, index: true }

    add_reference :interventions, :main_operation

    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-administrative_task-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '1000' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-all_in_one_sowing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-animal_artificial_insemination-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-animal_group_changing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-animal_housing_cleaning-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-animal_housing_mulching-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-animal_treatment-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-attach-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-calving_one-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-calving_twin-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-chaptalization-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '700' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-chemical_weed_killing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-complete_wine_transfer-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '400' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-cutting-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-detach-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-detasseling-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '200' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-direct_silage-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-double_chemical_mixing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-double_food_mixing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-double_seed_mixing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '800' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-double_spraying_on_cultivation-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '800' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-egg_production-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-enzyme_addition-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-fermentation-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-filling-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-fuel_up-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-grain_transport-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '200' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-grains_harvest-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-grape_pressing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-grape_transport-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '400' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-grinding-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '400' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-ground_destratification-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-group_inclusion-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-group_exclusion-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '700' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-harvest_helping-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-hazelnuts_harvest-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-hazelnuts_transport-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-hoeing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '700' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-implant_helping-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '700' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-implanting-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-indirect_silage-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-item_replacement-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-land_parcel_grinding-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-maintenance_task-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-mammal_herd_milking-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-mammal_milking-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '400' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-manual_feeding-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '800' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-mineral_fertilizing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-oil_replacement-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '800' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-organic_fertilizing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-partial_wine_transfer-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-pasturing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-plant_grinding-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '300' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-plant_mowing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '700' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-plantation_unfixing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '800' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-plastic_mulching-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-plowing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-product_evolution-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-product_moving-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-raking-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-silage_transport-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-silage_unload-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '700' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-sowing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '700' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-spraying_on_cultivation-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '700' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-spraying_on_land_parcel-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '400' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-standard_enclosing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-straw_bunching-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-straw_transport-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-sulfur_addition-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '500' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-superficial_plowing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-technical_task-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-triple_seed_mixing-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '800' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-uncompacting-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-vine_harvest-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-walnuts_harvest-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-walnuts_transport-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '400' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-watering-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-wine_blending-0'"
    execute "UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE o.reference_name = '100' AND o.intervention_id = interventions.id and interventions.reference_name = 'base-wine_bottling-0'"

    # Set default main operation if null
    execute 'UPDATE interventions SET main_operation_id = o.id FROM operations AS o WHERE main_operation_id IS NULL AND o.intervention_id = interventions.id'

    TASK_TABLES.each do |table|
      reversible do |dir|
        dir.up do
          execute "UPDATE #{table} SET operation_id = i.main_operation_id FROM operations AS o JOIN interventions AS i ON (o.intervention_id = i.id) WHERE o.id = operation_id"
        end
      end
    end

    # Updates all polymorphic columns
    POLYMORPHIC_REFERENCES.each do |table, reference|
      reversible do |dir|
        dir.up do
          execute "UPDATE #{table} SET #{reference}_id = i.main_operation_id FROM operations AS o JOIN interventions AS i ON (o.intervention_id = i.id) WHERE o.id = #{reference}_id AND #{reference}_type = 'Operation'"
        end
      end
    end

    # Remove useless operations
    execute 'DELETE FROM operations WHERE intervention_id IS NOT NULL AND id NOT IN (SELECT main_operation_id FROM interventions WHERE main_operation_id IS NOT NULL)'

    execute "UPDATE operations SET reference_name = '1' WHERE reference_name != '1'"

    remove_reference :interventions, :main_operation
  end
end
