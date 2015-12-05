class SimplifyInterventions < ActiveRecord::Migration
  TASK_TABLES = [:product_enjoyments, :product_junctions, :product_links,
                 :product_linkages, :product_localizations, :product_memberships,
                 :product_ownerships, :product_phases, :product_reading_tasks]

  POLYMORPHIC_REFERENCES = [
    [:attachments, :resource],
    [:issues, :target],
    [:journal_entries, :resource],
    [:notifications, :target],
    [:observations, :subject],
    [:preferences, :record_value],
    [:product_enjoyments, :originator],
    [:product_junctions, :originator],
    [:product_linkages, :originator],
    [:product_links, :originator],
    [:product_localizations, :originator],
    [:product_memberships, :originator],
    [:product_ownerships, :originator],
    [:product_phases, :originator],
    [:product_reading_tasks, :originator],
    [:product_readings, :originator],
    [:versions, :item]
  ]

  TYPE_COLUMNS = [
    [:affairs, :type],
    [:products, :type],
    [:custom_fields, :customized_type]
  ]


  MULTI_POLYGON_COLUMNS = {
    # Generic
    activity_productions: [:support_shape],
    cultivable_zones: [:shape],
    # georeadings: [:content],
    intervention_casts: [:working_zone],
    inventory_items: [:actual_shape, :expected_shape],
    parcel_items: [:shape],
    products: [:initial_shape],
    # Reading mode
    analysis_items: [:geometry_value],
    intervention_cast_readings: [:geometry_value],
    product_nature_variant_readings: [:geometry_value],
    product_readings: [:geometry_value],
    # Polygons ?
    cap_islets: [:shape],
    cap_land_parcels: [:shape],
  }


  ALL_TYPE_COLUMNS = TYPE_COLUMNS +
                     POLYMORPHIC_REFERENCES.map { |a| [a.first, "#{a.second}_type".to_sym] }

  # Rename table and depending stuff
  def rename_model_and_co(old_model, new_model)
    old_table = old_model.to_s.tableize
    new_table = new_model.to_s.tableize
    old_record = old_table.to_s.singularize
    new_record = new_table.to_s.singularize
    # Type columns
    reversible do |dir|
      dir.up do
        ALL_TYPE_COLUMNS.each do |table, column|
          execute "UPDATE #{quote_table_name(table)} SET #{quote_column_name(column)}='#{new_model}' WHERE #{quote_column_name(column)}='#{old_model}'"
        end
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='#{new_record}' WHERE #{quote_column_name(:root_model)}='#{old_record}'"
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='#{new_table}' WHERE #{quote_column_name(:usage)}='#{old_table}'"
      end
      dir.down do
        ALL_TYPE_COLUMNS.each do |table, column|
          execute "UPDATE #{quote_table_name(table)} SET #{quote_column_name(column)}='#{old_model}' WHERE #{quote_column_name(column)}='#{new_model}'"
        end
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='#{old_record}' WHERE #{quote_column_name(:root_model)}='#{new_record}'"
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='#{old_table}' WHERE #{quote_column_name(:usage)}='#{new_table}'"
      end
    end
  end

  # Rename table and depending stuff
  def rename_table_and_co(old_table, new_table)
    old_model = old_table.to_s.classify
    new_model = new_table.to_s.classify
    rename_model_and_co(old_model, new_model)
    rename_table old_table, new_table
  end

  def change
    # Adds UUID on products to facilitate exchange
    add_column :products, :uuid, :uuid
    add_index :products, :uuid
    execute 'UPDATE products SET uuid = uuid_generate_v4()'

    # Merge operation into interventions
    TASK_TABLES.each do |table|
      add_reference table, :intervention, index: true
      reversible do |dir|
        dir.up do
          execute "UPDATE #{table} SET intervention_id = o.intervention_id FROM operations AS o WHERE o.id = operation_id"
        end
        # TODO: affect tasks to on operation created for all existing interventions
      end
      revert { add_reference table, :operation, index: true }
    end

    # Updates all polymorphic columns
    POLYMORPHIC_REFERENCES.each do |table, reference|
      reversible do |dir|
        dir.up do
          execute "UPDATE #{table} SET #{reference}_type = 'Intervention', #{reference}_id = o.intervention_id FROM operations AS o WHERE o.id = #{reference}_id AND #{reference}_type = 'Operation'"
        end
      end
    end

    create_table :cultivable_zones do |t|
      t.string :name, null: false
      t.string :work_number, null: false
      t.multi_polygon :shape, srid: 4326
      t.text :description
      t.uuid :uuid
      t.references :product
      t.stamps
    end

    rename_model_and_co 'CultivableZone', 'LandParcel'
    [:products, :product_natures, :product_nature_variants].each do |table|
      old_variety = 'cultivable_zone'
      new_variety = 'land_parcel'
      reversible do |dir|
        dir.up do
          execute "UPDATE #{table} SET variety = '#{new_variety}' WHERE variety = '#{old_variety}'"
          execute "UPDATE #{table} SET derivative_of = '#{new_variety}' WHERE derivative_of = '#{old_variety}'"
        end
        dir.down do
          execute "UPDATE #{table} SET derivative_of = '#{old_variety}' WHERE derivative_of = '#{new_variety}'"
          execute "UPDATE #{table} SET variety = '#{old_variety}' WHERE variety = '#{new_variety}'"
        end
      end
    end

    reversible do |dir|
      dir.up do
        # SELECT id, test, ST_GeometryN(poli, generate_series(1, ST_NumGeometries(geom))) AS geom FROM multi
        execute "INSERT INTO cultivable_zones (name, work_number, shape, uuid, product_id, created_at, creator_id, updated_at, updater_id, lock_version) SELECT name, work_number, ST_Multi(initial_shape), uuid_generate_v4(), id, created_at, creator_id, updated_at, updater_id, lock_version FROM products WHERE type = 'LandParcel'"
        execute 'UPDATE cultivable_zones SET shape = ST_Multi(geometry_value) FROM product_readings AS pr WHERE pr.product_id = cultivable_zones.product_id AND geometry_value IS NOT NULL'
        execute 'DELETE FROM cultivable_zones WHERE shape IS NULL'
      end
      dir.down do
        # TODO Adds revert of CultivableZone transfert
      end
    end
    change_column_null :cultivable_zones, :shape, false

    # Add campaign period
    add_column :campaigns, :started_on, :date
    add_column :campaigns, :stopped_on, :date
    reversible do |d|
      d.up do
        execute "UPDATE campaigns SET started_on = (COALESCE(harvest_year, 1500)::VARCHAR || '-09-01')::DATE, stopped_on = (COALESCE(harvest_year, 1500)::VARCHAR || '-08-31')::DATE"
      end
    end

    # Updates activities
    add_column :activities, :size_indicator, :string
    add_column :activities, :size_unit, :string
    add_column :activities, :suspended, :boolean, null: false, default: false
    reversible do |d|
      d.up do
        execute 'UPDATE activities SET size_indicator = support_variant_indicator, size_unit = support_variant_unit FROM productions WHERE activity_id = activities.id'
      end
    end

    # ActivityDistribution: Nothing to change

    # ActivityBudget
    rename_table_and_co :production_budgets, :activity_budgets
    add_reference :activity_budgets, :activity, index: true
    add_reference :activity_budgets, :campaign, index: true
    reversible do |d|
      d.up do
        execute "UPDATE activity_budgets SET computation_method = CASE WHEN computation_method = 'per_production' THEN 'per_campaign' WHEN computation_method = 'per_production_support' THEN 'per_production' ELSE computation_method END, activity_id = p.activity_id, campaign_id = p.campaign_id FROM productions AS p WHERE p.id = activity_budgets.production_id"
      end
    end
    change_column_null :activity_budgets, :activity_id, false
    change_column_null :activity_budgets, :campaign_id, false
    revert { add_reference :activity_budgets, :production, index: true }

    # ActivityProduction
    rename_table_and_co :production_supports, :activity_productions
    add_reference :activity_productions, :activity, index: true
    add_reference :activity_productions, :cultivable_zone, index: true
    add_column :activity_productions, :irrigated, :boolean, null: false, default: false
    add_column :activity_productions, :nitrate_fixing, :boolean, null: false, default: false
    add_column :activity_productions, :support_shape, :geometry, srid: 4326
    add_column :activity_productions, :started_at, :datetime
    add_column :activity_productions, :stopped_at, :datetime
    add_column :activity_productions, :state, :string
    add_column :activity_productions, :rank_number, :integer
    rename_column :activity_productions, :storage_id, :support_id
    rename_column :activity_productions, :production_usage, :usage
    rename_column :activity_productions, :quantity, :size_value
    rename_column :activity_productions, :quantity_indicator, :size_indicator
    rename_column :activity_productions, :quantity_unit, :size_unit
    reversible do |d|
      d.up do
        # Sets cultivable_zone column when possible
        execute 'UPDATE activity_productions SET cultivable_zone_id = support_id WHERE support_id IN (SELECT id FROM products WHERE type = \'CultivableZone\')'
        execute 'UPDATE activity_productions SET cultivable_zone_id = cultivable_zones.id FROM cultivable_zones WHERE support_id = product_id'

        # Updates attributes coming from old Production
        execute 'UPDATE activity_productions SET activity_id = p.activity_id, state = p.state, irrigated = p.irrigated, nitrate_fixing = p.nitrate_fixing, started_at = p.started_at, stopped_at = p.stopped_at FROM productions AS p LEFT JOIN campaigns AS c ON (p.campaign_id = c.id) WHERE p.id = activity_productions.production_id'
        # Updates support_shape
        execute 'UPDATE activity_productions SET support_shape = cz.shape FROM cultivable_zones AS cz WHERE activity_productions.cultivable_zone_id = cz.id'
        # Updates attributes coming from old Production
        execute 'UPDATE activity_productions SET rank_number = rank FROM (SELECT id, row_number() OVER (PARTITION BY activity_id ORDER BY id) AS rank FROM activity_productions) AS x WHERE x.id = activity_productions.id'
      end
    end
    change_column_null :activity_productions, :activity_id, false
    change_column_null :activity_productions, :rank_number, false
    revert { add_reference :activity_productions, :production, index: true }

    # ManureManagementPlan
    rename_column :manure_management_plan_zones, :support_id, :activity_production_id

    # InterventionWorkingPeriod
    create_table :intervention_working_periods do |t|
      t.references :intervention, null: false, index: true
      t.datetime :started_at, null: false
      t.datetime :stopped_at, null: false
      t.integer :duration, null: false
      t.stamps
    end
    add_column :interventions, :working_duration, :integer
    add_column :interventions, :whole_duration, :integer

    reversible do |d|
      d.up do
        execute "INSERT INTO intervention_working_periods (intervention_id, started_at, stopped_at, duration, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, started_at, stopped_at, date_part('epoch', stopped_at - started_at), created_at, creator_id, updated_at, updater_id, lock_version FROM interventions"
        execute "UPDATE interventions SET working_duration = date_part('epoch', stopped_at - started_at), whole_duration = date_part('epoch', stopped_at - started_at)"
      end
    end

    # TargetDistribution
    create_table :target_distributions do |t|
      t.references :target, null: false, index: true
      t.references :activity_production, null: false, index: true
      t.references :activity, null: false, index: true
      t.datetime :started_at
      t.datetime :stopped_at
      t.stamps
    end

    # Intervention(Cast|Doer|Input|Output|Target|Tool)
    add_reference :intervention_casts, :source_product, index: true
    add_column :intervention_casts, :type, :string
    add_index :intervention_casts, :type

    # - Localization
    add_reference :intervention_casts, :new_container, index: true

    # - Group
    add_reference :intervention_casts, :new_group, index: true

    # - Phase
    add_reference :intervention_casts, :new_variant, index: true

    # - Readings: InterventionCastReading
    rename_table_and_co :product_reading_tasks, :intervention_cast_readings
    add_reference :intervention_cast_readings, :intervention_cast, index: true
    reversible do |d|
      d.up do
        puts select_value('SELECT count(*) FROM intervention_cast_readings WHERE intervention_cast_id IS NULL').inspect.green
        # Try to find cast with cast as originator
        execute "UPDATE intervention_cast_readings SET intervention_cast_id = originator_id WHERE intervention_cast_id IS NULL AND intervention_id IS NULL AND originator_type = 'InterventionCast'"
        puts select_value('SELECT count(*) FROM intervention_cast_readings WHERE intervention_cast_id IS NULL').inspect.green

        # Try to find cast within casts of same intervention
        execute 'UPDATE intervention_cast_readings SET intervention_cast_id = c.id FROM intervention_casts AS c WHERE intervention_cast_id IS NULL AND c.intervention_id = intervention_cast_readings.intervention_id AND c.actor_id = intervention_cast_readings.product_id'
        puts select_value('SELECT count(*) FROM intervention_cast_readings WHERE intervention_cast_id IS NULL').inspect.green

        # Try to find cast with intervention as originator
        execute "UPDATE intervention_cast_readings SET intervention_cast_id = c.id FROM intervention_casts AS c WHERE intervention_cast_id IS NULL AND c.intervention_id = intervention_cast_readings.originator_id AND intervention_cast_readings.originator_type = 'Intervention' AND c.actor_id = intervention_cast_readings.product_id"
        puts select_value('SELECT count(*) FROM intervention_cast_readings WHERE intervention_cast_id IS NULL').inspect.green

        # Try to find first cast within casts of intervention
        execute 'UPDATE intervention_cast_readings SET intervention_cast_id = c.id FROM intervention_casts AS c WHERE intervention_cast_id IS NULL AND c.intervention_id = intervention_cast_readings.intervention_id'

        removed_ids = select_rows('SELECT id FROM intervention_cast_readings WHERE intervention_cast_id IS NULL')
        if removed_ids.any?
          say "Following reading task will be removed: #{removed_ids.join(', ')}"
          execute('DELETE FROM intervention_cast_readings WHERE intervention_cast_id IS NULL')
        end
      end
    end
    change_column_null :intervention_cast_readings, :intervention_cast_id, false
    revert do
      add_column :intervention_cast_readings, :started_at, :datetime
      add_column :intervention_cast_readings, :stopped_at, :datetime
      add_reference :intervention_cast_readings, :originator, polymorphic: true, index: true
      add_reference :intervention_cast_readings, :reporter, index: true
      add_reference :intervention_cast_readings, :tool, index: true
      add_reference :intervention_cast_readings, :intervention
      add_reference :intervention_cast_readings, :product
    end

    # - Quantity
    add_column :intervention_casts, :quantity_handler, :string
    add_column :intervention_casts, :quantity_value, :decimal, precision: 19, scale: 4
    add_column :intervention_casts, :quantity_unit, :string
    add_column :intervention_casts, :quantity_indicator, :string
    rename_column :intervention_casts, :population, :quantity_population

    # - Working zone
    rename_column :intervention_casts, :shape, :working_zone

    # - Product
    rename_column :intervention_casts, :actor_id, :product_id

    # Remove interventions administrative_task
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-administrative_task-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-administrative_task-0'"
    # Rename interventions animal_treatment with animal_antibiotic_treatment
    execute "UPDATE interventions SET reference_name = 'base-animal_antibiotic_treatment-0' WHERE reference_name = 'base-animal_treatment-0'"
    # Remove interventions attach
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-attach-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-attach-0'"
    # Rename interventions calving_one with parturition
    execute "UPDATE interventions SET reference_name = 'base-parturition-0' WHERE reference_name = 'base-calving_one-0'"
    # Merge interventions calving_twin into parturition
    execute "UPDATE interventions SET reference_name = 'base-parturition-0' WHERE reference_name = 'base-calving_twin-0'"
    # Merge interventions chemical_weed_killing into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-chemical_weed_killing-0'"
    # Remove interventions detach
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-detach-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-detach-0'"
    # Remove interventions double_chemical_mixing
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-double_chemical_mixing-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-double_chemical_mixing-0'"
    # Rename interventions double_food_mixing with food_preparation
    execute "UPDATE interventions SET reference_name = 'base-food_preparation-0' WHERE reference_name = 'base-double_food_mixing-0'"
    # Remove interventions double_seed_mixing
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-double_seed_mixing-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-double_seed_mixing-0'"
    # Merge interventions double_spraying_on_cultivation into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-double_spraying_on_cultivation-0'"
    # Merge interventions double_spraying_on_land_parcel into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-double_spraying_on_land_parcel-0'"
    # Rename interventions egg_production with egg_collecting
    execute "UPDATE interventions SET reference_name = 'base-egg_collecting-0' WHERE reference_name = 'base-egg_production-0'"
    # Remove interventions filling
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-filling-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-filling-0'"
    # Remove interventions grain_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-grain_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-grain_transport-0'"
    # Rename interventions grains_harvest with mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-grains_harvest-0'"
    # Remove interventions grape_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-grape_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-grape_transport-0'"
    # Rename interventions grinding with crop_residues_grinding
    execute "UPDATE interventions SET reference_name = 'base-crop_residues_grinding-0' WHERE reference_name = 'base-grinding-0'"
    # Remove interventions group_exclusion
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-group_exclusion-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-group_exclusion-0'"
    # Remove interventions group_inclusion
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-group_inclusion-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-group_inclusion-0'"
    # Merge interventions harvest_helping into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-harvest_helping-0'"
    # Merge interventions hazelnuts_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-hazelnuts_harvest-0'"
    # Remove interventions hazelnuts_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-hazelnuts_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-hazelnuts_transport-0'"
    # Merge interventions implant_helping into mechanical_planting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_planting-0' WHERE reference_name = 'base-implant_helping-0'"
    # Rename interventions implanting with mechanical_planting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_planting-0' WHERE reference_name = 'base-implanting-0'"
    # Rename interventions item_replacement with equipment_item_replacement
    execute "UPDATE interventions SET reference_name = 'base-equipment_item_replacement-0' WHERE reference_name = 'base-item_replacement-0'"
    # Remove interventions maintenance_task
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-maintenance_task-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-maintenance_task-0'"
    # Merge interventions mammal_herd_milking into milking
    execute "UPDATE interventions SET reference_name = 'base-milking-0' WHERE reference_name = 'base-mammal_herd_milking-0'"
    # Rename interventions mammal_milking with milking
    execute "UPDATE interventions SET reference_name = 'base-milking-0' WHERE reference_name = 'base-mammal_milking-0'"
    # Rename interventions mineral_fertilizing with mechanical_fertilizing
    execute "UPDATE interventions SET reference_name = 'base-mechanical_fertilizing-0' WHERE reference_name = 'base-mineral_fertilizing-0'"
    # Merge interventions organic_fertilizing into mechanical_fertilizing
    execute "UPDATE interventions SET reference_name = 'base-mechanical_fertilizing-0' WHERE reference_name = 'base-organic_fertilizing-0'"
    # Merge interventions plant_grinding into crop_residues_grinding
    execute "UPDATE interventions SET reference_name = 'base-crop_residues_grinding-0' WHERE reference_name = 'base-plant_grinding-0'"
    # Merge interventions plants_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-plants_harvest-0'"
    # Rename interventions plastic_mulching with plant_mulching
    execute "UPDATE interventions SET reference_name = 'base-plant_mulching-0' WHERE reference_name = 'base-plastic_mulching-0'"
    # Merge interventions plums_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-plums_harvest-0'"
    # Remove interventions product_evolution
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-product_evolution-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-product_evolution-0'"
    # Remove interventions product_moving
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-product_moving-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-product_moving-0'"
    # Remove interventions silage_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-silage_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-silage_transport-0'"
    # Rename interventions sorting with animal_sorting
    execute "UPDATE interventions SET reference_name = 'base-animal_sorting-0' WHERE reference_name = 'base-sorting-0'"
    # Rename interventions sowing_with_insecticide_and_molluscicide with sowing_with_spraying
    execute "UPDATE interventions SET reference_name = 'base-sowing_with_spraying-0' WHERE reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'"
    # Merge interventions spraying_on_cultivation into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-spraying_on_cultivation-0'"
    # Merge interventions spraying_on_land_parcel into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-spraying_on_land_parcel-0'"
    # Remove interventions straw_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-straw_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-straw_transport-0'"
    # Remove interventions technical_task
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-technical_task-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-technical_task-0'"
    # Merge interventions triple_food_mixing into food_preparation
    execute "UPDATE interventions SET reference_name = 'base-food_preparation-0' WHERE reference_name = 'base-triple_food_mixing-0'"
    # Remove interventions triple_seed_mixing
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-triple_seed_mixing-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-triple_seed_mixing-0'"
    # Merge interventions triple_spraying_on_cultivation into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-triple_spraying_on_cultivation-0'"
    # Merge interventions vine_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-vine_harvest-0'"
    # Merge interventions walnuts_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-walnuts_harvest-0'"
    # Remove interventions walnuts_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-walnuts_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-walnuts_transport-0'"
    # Rename interventions watering with plant_watering
    execute "UPDATE interventions SET reference_name = 'base-plant_watering-0' WHERE reference_name = 'base-watering-0'"
    # input
    execute "UPDATE intervention_casts SET type = 'InterventionInput' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('seeds', 'fertilizer', 'insecticide', 'molluscicide', 'vial', 'straw_to_mulch', 'animal_medicine', 'oenological_intrant', 'first_food_input', 'first_food_input_to_use', 'second_food_input', 'second_food_input_to_use', 'fuel', 'fuel_to_input', 'grape', 'plants', 'straw_to_bunch', 'item', 'item_to_change', 'oil', 'oil_to_input', 'plastic', 'stakes', 'wire_fence', 'water', 'adding_wine', 'wine_to_pack', 'bottles_to_use', 'corks_to_use') OR (intervention_casts.reference_name = 'animal' AND i.reference_name = 'base-animal_group_changing-0') OR (intervention_casts.reference_name = 'silage' AND i.reference_name IN ('base-manual_feeding-0', 'base-silage_unload-0')) OR (intervention_casts.reference_name = 'wine' AND i.reference_name = 'base-wine_blending-0'))"
    # tool
    execute "UPDATE intervention_casts SET type = 'InterventionTool' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('sower', 'tractor', 'cleaner', 'tank', 'cutter', 'forager', 'cropper', 'tank_for_residue', 'press', 'grinder', 'cultivator', 'implanter_tool', 'spreader', 'mower', 'compressor', 'implanter', 'plow', 'harrow', 'silage_unloader', 'baler', 'hand_drawn', 'corker') OR (intervention_casts.reference_name = 'herd' AND i.reference_name = 'base-pasturing-0'))"
    # doer
    execute "UPDATE intervention_casts SET type = 'InterventionDoer' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('driver', 'inseminator', 'caregiver', 'wine_man', 'doer', 'forager_driver', 'worker', 'mechanic', 'cropper_driver', 'implanter_man', 'mower_driver', 'baler_driver'))"
    # target
    execute "UPDATE intervention_casts SET type = 'InterventionTarget' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('land_parcel', 'animal_housing', 'mother', 'wine_to_treat', 'bird_band', 'juice_to_ferment', 'equipment', 'tank_for_wine', 'mammal_to_milk', 'wine_to_move', 'sortable_to_sort') OR (intervention_casts.reference_name = 'animal' AND i.reference_name IN ('base-animal_artificial_insemination-0', 'base-animal_treatment-0')) OR (intervention_casts.reference_name = 'herd' AND i.reference_name IN ('base-animal_group_changing-0', 'base-manual_feeding-0', 'base-silage_unload-0')) OR (intervention_casts.reference_name = 'wine' AND i.reference_name IN ('base-complete_wine_transfer-0', 'base-wine_bottling-0')) OR (intervention_casts.reference_name = 'cultivation' AND i.reference_name IN ('base-cutting-0', 'base-detasseling-0', 'base-direct_silage-0', 'base-grains_harvest-0', 'base-pasturing-0', 'base-plant_mowing-0', 'base-plantation_unfixing-0', 'base-watering-0')))"
    # output
    execute "UPDATE intervention_casts SET type = 'InterventionOutput' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('excrement', 'child', 'food_mix', 'eggs', 'fermented_juice', 'grains', 'straws', 'juice', 'residue', 'milk', 'grass', 'straw', 'straw_bales', 'wine_blended', 'wine_bottles') OR (intervention_casts.reference_name = 'cultivation' AND i.reference_name IN ('base-all_in_one_sowing-0', 'base-implanting-0', 'base-sowing-0', 'base-sowing_with_insecticide_and_molluscicide-0')) OR (intervention_casts.reference_name = 'silage' AND i.reference_name IN ('base-direct_silage-0', 'base-indirect_silage-0')))"

    # Simplifies procedure name. No namespace. No version.
    execute "UPDATE interventions SET reference_name = REPLACE(REPLACE(reference_name, 'base-', ''), '-0', '')"

    # TODO: Update intervention_casts#type column with existings procedure
    # TODO: Removes 'variant' intervention_casts records

    remove_reference :cultivable_zones, :product

    reversible do |d|
      d.up do
        remove_column :intervention_casts, :nature
      end
      d.down do
        add_column :intervention_casts, :nature, :string
        execute "UPDATE intervention_casts SET nature = 'product'"
        # TODO: Set variant if old cast is variant
        change_column_null :intervention_casts, :nature, false
      end
    end

    revert do
      # add_reference :intervention_casts, :event_participation, index: true
      add_column :intervention_casts, :roles, :string
      # TODO: restore roles values

      add_reference :interventions, :production, index: true
      add_reference :interventions, :production_support, index: true
      add_column :interventions, :parameters, :text
      add_column :interventions, :natures, :string
      # TODO: restore natures
      add_column :interventions, :provisional, :boolean, null: false, default: false
      add_reference :interventions, :provisional_intervention
      add_column :interventions, :recommended, :boolean, null: false, default: false
      add_reference :interventions, :recommender

      create_table 'operations' do |t|
        t.reference :intervention, null: false, index: true
        t.datetime 'started_at',                  null: false, index: true
        t.datetime 'stopped_at',                  null: false, index: true
        t.integer 'duration'
        t.string 'reference_name', null: false
        t.stamps
        t.index :reference_name
      end

      create_table 'productions' do |t|
        t.references :activity,                               null: false, index: true
        t.references :campaign,                               null: false, index: true
        t.references :cultivation_variant, index: true
        t.string 'name',                                      null: false
        t.string 'state',                                     null: false
        t.datetime 'started_at'
        t.datetime 'stopped_at'
        t.integer :position
        t.stamps
        t.string 'support_variant_indicator'
        t.string 'support_variant_unit'
        t.references :support_variant, index: true
        t.boolean 'irrigated',                 default: false, null: false
        t.boolean 'nitrate_fixing',            default: false, null: false
        t.index :name
        t.index :started_at
        t.index :stopped_at
      end

      create_table 'production_distributions', force: :cascade do |t|
        t.references :production,                                               null: false
        t.decimal :affectation_percentage, precision: 19, scale: 4,             null: false
        t.references :main_production,                                          null: false
        t.stamps
      end
    end

    # Radius of big corn plant
    radius = 0.0000097
    MULTI_POLYGON_COLUMNS.each do |table, columns|
      columns.each do |column|
        reversible do |dir|
          dir.up do
            # Transform Points and Linestrings to Polygons with ST_Buffer function
            execute "UPDATE #{table} SET #{column} = ST_Multi(ST_Union(ARRAY[ST_Buffer(ST_CollectionExtract(#{column}, 1), #{radius}), ST_Buffer(ST_CollectionExtract(#{column}, 2), #{radius}), ST_CollectionExtract(#{column}, 3)]))"
            change_column table, column, :geometry, limit: 'MULTIPOLYGON,4326'
            execute "UPDATE #{table} SET #{column} = ST_Multi(#{column})"
          end
          dir.down do
            change_column table, column, :geometry, limit: 'GEOMETRY,4326'
          end
        end
      end
    end

    [:analysis_items, :intervention_cast_readings, :product_nature_variant_readings, :product_readings].each do |table|
      rename_column table, :geometry_value, :multi_polygon_value
      add_column table, :geometry_value, :geometry, srid: 4326
    end

  end
end
