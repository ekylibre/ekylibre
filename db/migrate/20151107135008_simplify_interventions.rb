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
    cap_land_parcels: [:shape]
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
        # TODO: Adds revert of CultivableZone transfert
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
    add_column :activity_productions, :support_nature, :string
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
        execute "UPDATE activity_productions SET support_nature = CASE WHEN usage = 'fallow_land' THEN 'fallow_land' ELSE 'cultivation' END, usage = CASE WHEN usage = 'fallow_land' THEN 'none' ELSE usage END"
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
    # Remove interventions attach
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-attach-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-attach-0'"
    # Remove interventions detach
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-detach-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-detach-0'"
    # Remove interventions double_chemical_mixing
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-double_chemical_mixing-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-double_chemical_mixing-0'"
    # Remove interventions double_seed_mixing
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-double_seed_mixing-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-double_seed_mixing-0'"
    # Remove interventions filling
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-filling-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-filling-0'"
    # Remove interventions group_exclusion
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-group_exclusion-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-group_exclusion-0'"
    # Remove interventions group_inclusion
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-group_inclusion-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-group_inclusion-0'"
    # Remove interventions maintenance_task
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-maintenance_task-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-maintenance_task-0'"
    # Remove interventions product_evolution
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-product_evolution-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-product_evolution-0'"
    # Remove interventions product_moving
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-product_moving-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-product_moving-0'"
    # Remove interventions technical_task
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-technical_task-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-technical_task-0'"
    # Remove interventions triple_seed_mixing
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-triple_seed_mixing-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-triple_seed_mixing-0'"
    # Merge interventions calving_twin casts into parturition's
    execute "UPDATE intervention_casts SET reference_name = 'child' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_child' AND i.reference_name = 'base-calving_twin-0'"
    execute "UPDATE intervention_casts SET reference_name = 'child' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_child' AND i.reference_name = 'base-calving_twin-0'"
    # Merge interventions calving_twin into parturition
    execute "UPDATE interventions SET reference_name = 'base-parturition-0' WHERE reference_name = 'base-calving_twin-0'"
    # Merge interventions chemical_weed_killing casts into spraying's
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'weedkiller' AND i.reference_name = 'base-chemical_weed_killing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'weedkiller_to_spray' AND i.reference_name = 'base-chemical_weed_killing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'cultivation' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'land_parcel' AND i.reference_name = 'base-chemical_weed_killing-0'"
    # Merge interventions chemical_weed_killing into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-chemical_weed_killing-0'"
    # Merge interventions double_food_mixing casts into food_preparation's
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'food_storage' AND i.reference_name = 'base-double_food_mixing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_food_input' AND i.reference_name = 'base-double_food_mixing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_food_input_to_use' AND i.reference_name = 'base-double_food_mixing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_food_input' AND i.reference_name = 'base-double_food_mixing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_food_input_to_use' AND i.reference_name = 'base-double_food_mixing-0'"
    # Merge interventions double_food_mixing into food_preparation
    execute "UPDATE interventions SET reference_name = 'base-food_preparation-0' WHERE reference_name = 'base-double_food_mixing-0'"
    # Merge interventions double_spraying_on_cultivation casts into spraying's
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_plant_medicine' AND i.reference_name = 'base-double_spraying_on_cultivation-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_plant_medicine_to_spray' AND i.reference_name = 'base-double_spraying_on_cultivation-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_plant_medicine' AND i.reference_name = 'base-double_spraying_on_cultivation-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_plant_medicine_to_spray' AND i.reference_name = 'base-double_spraying_on_cultivation-0'"
    # Merge interventions double_spraying_on_cultivation into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-double_spraying_on_cultivation-0'"
    # Merge interventions double_spraying_on_land_parcel casts into spraying's
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_plant_medicine' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_plant_medicine_to_spray' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_plant_medicine' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_plant_medicine_to_spray' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE intervention_casts SET reference_name = 'cultivation' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'land_parcel' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    # Merge interventions double_spraying_on_land_parcel into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-double_spraying_on_land_parcel-0'"
    # Merge interventions harvest_helping casts into mechanical_harvesting's
    # Merge interventions harvest_helping into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-harvest_helping-0'"
    # Merge interventions hazelnuts_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_casts SET reference_name = 'cropper_driver' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'driver' AND i.reference_name = 'base-hazelnuts_harvest-0'"
    execute "UPDATE intervention_casts SET reference_name = 'cropper' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'nuts_harvester' AND i.reference_name = 'base-hazelnuts_harvest-0'"
    execute "UPDATE intervention_casts SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'hazelnuts' AND i.reference_name = 'base-hazelnuts_harvest-0'"
    # Merge interventions hazelnuts_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-hazelnuts_harvest-0'"
    # Merge interventions implant_helping into mechanical_planting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_planting-0' WHERE reference_name = 'base-implant_helping-0'"
    # Merge interventions mammal_herd_milking casts into milking's
    execute "UPDATE intervention_casts SET reference_name = 'mammal_to_milk' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'mammal_herd_to_milk' AND i.reference_name = 'base-mammal_herd_milking-0'"
    # Merge interventions mammal_herd_milking into milking
    execute "UPDATE interventions SET reference_name = 'base-milking-0' WHERE reference_name = 'base-mammal_herd_milking-0'"
    # Merge interventions organic_fertilizing casts into mechanical_fertilizing's
    execute "UPDATE intervention_casts SET reference_name = 'fertilizer' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'manure' AND i.reference_name = 'base-organic_fertilizing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'fertilizer_to_spread' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'manure_to_spread' AND i.reference_name = 'base-organic_fertilizing-0'"
    # Merge interventions organic_fertilizing into mechanical_fertilizing
    execute "UPDATE interventions SET reference_name = 'base-mechanical_fertilizing-0' WHERE reference_name = 'base-organic_fertilizing-0'"
    # Merge interventions plant_grinding casts into crop_residues_grinding's
    # Merge interventions plant_grinding into crop_residues_grinding
    execute "UPDATE interventions SET reference_name = 'base-crop_residues_grinding-0' WHERE reference_name = 'base-plant_grinding-0'"
    # Merge interventions plants_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_casts SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'plants' AND i.reference_name = 'base-plants_harvest-0'"
    # Merge interventions plants_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-plants_harvest-0'"
    # Merge interventions plums_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_casts SET reference_name = 'cropper_driver' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'driver' AND i.reference_name = 'base-plums_harvest-0'"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'tractor' AND i.reference_name = 'base-plums_harvest-0')"
    execute "UPDATE intervention_casts SET reference_name = 'cropper' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'fruit_harvester' AND i.reference_name = 'base-plums_harvest-0'"
    execute "UPDATE intervention_casts SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'fruits' AND i.reference_name = 'base-plums_harvest-0'"
    # Merge interventions plums_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-plums_harvest-0'"
    # Merge interventions spraying_on_land_parcel casts into spraying's
    execute "UPDATE intervention_casts SET reference_name = 'cultivation' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'land_parcel' AND i.reference_name = 'base-spraying_on_land_parcel-0'"
    # Merge interventions spraying_on_land_parcel into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-spraying_on_land_parcel-0'"
    # Merge interventions triple_food_mixing casts into food_preparation's
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'food_storage' AND i.reference_name = 'base-triple_food_mixing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_food_input' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_food_input_to_use' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_food_input' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_food_input_to_use' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'third_food_input' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_casts SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'third_food_input_to_use' AND i.reference_name = 'base-triple_food_mixing-0'"
    # Merge interventions triple_food_mixing into food_preparation
    execute "UPDATE interventions SET reference_name = 'base-food_preparation-0' WHERE reference_name = 'base-triple_food_mixing-0'"
    # Merge interventions triple_spraying_on_cultivation casts into spraying's
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_plant_medicine' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'first_plant_medicine_to_spray' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_plant_medicine' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'second_plant_medicine_to_spray' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'third_plant_medicine' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'third_plant_medicine_to_spray' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    # Merge interventions triple_spraying_on_cultivation into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-triple_spraying_on_cultivation-0'"
    # Merge interventions vine_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_casts SET reference_name = 'cropper_driver' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'grape_reaper_driver' AND i.reference_name = 'base-vine_harvest-0'"
    execute "UPDATE intervention_casts SET reference_name = 'cropper' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'grape_reaper' AND i.reference_name = 'base-vine_harvest-0'"
    execute "UPDATE intervention_casts SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'fruits' AND i.reference_name = 'base-vine_harvest-0'"
    # Merge interventions vine_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-vine_harvest-0'"
    # Merge interventions walnuts_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_casts SET reference_name = 'cropper_driver' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'driver' AND i.reference_name = 'base-walnuts_harvest-0'"
    execute "UPDATE intervention_casts SET reference_name = 'cropper' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'nuts_harvester' AND i.reference_name = 'base-walnuts_harvest-0'"
    execute "UPDATE intervention_casts SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'walnuts' AND i.reference_name = 'base-walnuts_harvest-0'"
    # Merge interventions walnuts_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-walnuts_harvest-0'"
    # Rename interventions animal_treatment with animal_antibiotic_treatment
    execute "UPDATE interventions SET reference_name = 'base-animal_antibiotic_treatment-0' WHERE reference_name = 'base-animal_treatment-0'"
    # Merge animal_medicine infos into animal_medicine_to_give and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'animal_medicine' AND intervention_casts.reference_name = 'animal_medicine_to_give' AND oi.reference_name = 'base-animal_antibiotic_treatment-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'animal_medicine' AND i.reference_name = 'base-animal_antibiotic_treatment-0')"
    execute "UPDATE intervention_casts SET reference_name = 'animal_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'animal_medicine_to_give' AND i.reference_name = 'base-animal_antibiotic_treatment-0'"
    # Rename interventions calving_one with parturition
    execute "UPDATE interventions SET reference_name = 'base-parturition-0' WHERE reference_name = 'base-calving_one-0'"
    # Rename interventions egg_production with egg_collecting
    execute "UPDATE interventions SET reference_name = 'base-egg_collecting-0' WHERE reference_name = 'base-egg_production-0'"
    # Remove casts container from egg_collecting interventions
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'container' AND i.reference_name = 'base-egg_collecting-0')"
    # Rename interventions grains_harvest with mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-grains_harvest-0'"
    # Rename interventions grinding with crop_residues_grinding
    execute "UPDATE interventions SET reference_name = 'base-crop_residues_grinding-0' WHERE reference_name = 'base-grinding-0'"
    # Rename interventions implanting with mechanical_planting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_planting-0' WHERE reference_name = 'base-implanting-0'"
    # Merge plants infos into plants_to_fix and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'plants' AND intervention_casts.reference_name = 'plants_to_fix' AND oi.reference_name = 'base-mechanical_planting-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'plants' AND i.reference_name = 'base-mechanical_planting-0')"
    execute "UPDATE intervention_casts SET reference_name = 'plants' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'plants_to_fix' AND i.reference_name = 'base-mechanical_planting-0'"
    # Rename interventions item_replacement with equipment_item_replacement
    execute "UPDATE interventions SET reference_name = 'base-equipment_item_replacement-0' WHERE reference_name = 'base-item_replacement-0'"
    # Merge item infos into item_to_change and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'item' AND intervention_casts.reference_name = 'item_to_change' AND oi.reference_name = 'base-equipment_item_replacement-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'item' AND i.reference_name = 'base-equipment_item_replacement-0')"
    execute "UPDATE intervention_casts SET reference_name = 'item' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'item_to_change' AND i.reference_name = 'base-equipment_item_replacement-0'"
    # Rename interventions mammal_milking with milking
    execute "UPDATE interventions SET reference_name = 'base-milking-0' WHERE reference_name = 'base-mammal_milking-0'"
    # Remove casts container from milking interventions
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'container' AND i.reference_name = 'base-milking-0')"
    # Rename interventions mineral_fertilizing with mechanical_fertilizing
    execute "UPDATE interventions SET reference_name = 'base-mechanical_fertilizing-0' WHERE reference_name = 'base-mineral_fertilizing-0'"
    # Merge fertilizer infos into fertilizer_to_spread and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'fertilizer' AND intervention_casts.reference_name = 'fertilizer_to_spread' AND oi.reference_name = 'base-mechanical_fertilizing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'fertilizer' AND i.reference_name = 'base-mechanical_fertilizing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'fertilizer' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'fertilizer_to_spread' AND i.reference_name = 'base-mechanical_fertilizing-0'"
    # Rename interventions plastic_mulching with plant_mulching
    execute "UPDATE interventions SET reference_name = 'base-plant_mulching-0' WHERE reference_name = 'base-plastic_mulching-0'"
    # Merge plastic infos into plastic_to_mulch and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'plastic' AND intervention_casts.reference_name = 'plastic_to_mulch' AND oi.reference_name = 'base-plant_mulching-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'plastic' AND i.reference_name = 'base-plant_mulching-0')"
    execute "UPDATE intervention_casts SET reference_name = 'plastic' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'plastic_to_mulch' AND i.reference_name = 'base-plant_mulching-0'"
    # Rename interventions sorting with field_plant_sorting
    execute "UPDATE interventions SET reference_name = 'base-field_plant_sorting-0' WHERE reference_name = 'base-sorting-0'"
    # Merge sortable infos into sortable_to_sort and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'sortable' AND intervention_casts.reference_name = 'sortable_to_sort' AND oi.reference_name = 'base-field_plant_sorting-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'sortable' AND i.reference_name = 'base-field_plant_sorting-0')"
    execute "UPDATE intervention_casts SET reference_name = 'sortable' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'sortable_to_sort' AND i.reference_name = 'base-field_plant_sorting-0'"
    # Rename interventions sowing_with_insecticide_and_molluscicide with sowing_with_spraying
    execute "UPDATE interventions SET reference_name = 'base-sowing_with_spraying-0' WHERE reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'"
    # Merge seeds infos into seeds_to_sow and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'seeds' AND intervention_casts.reference_name = 'seeds_to_sow' AND oi.reference_name = 'base-sowing_with_spraying-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'seeds' AND i.reference_name = 'base-sowing_with_spraying-0')"
    execute "UPDATE intervention_casts SET reference_name = 'seeds' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'seeds_to_sow' AND i.reference_name = 'base-sowing_with_spraying-0'"
    # Merge insecticide infos into insecticide_to_input and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'insecticide' AND intervention_casts.reference_name = 'insecticide_to_input' AND oi.reference_name = 'base-sowing_with_spraying-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'insecticide' AND i.reference_name = 'base-sowing_with_spraying-0')"
    execute "UPDATE intervention_casts SET reference_name = 'insecticide' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'insecticide_to_input' AND i.reference_name = 'base-sowing_with_spraying-0'"
    # Merge molluscicide infos into molluscicide_to_input and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'molluscicide' AND intervention_casts.reference_name = 'molluscicide_to_input' AND oi.reference_name = 'base-sowing_with_spraying-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'molluscicide' AND i.reference_name = 'base-sowing_with_spraying-0')"
    execute "UPDATE intervention_casts SET reference_name = 'molluscicide' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'molluscicide_to_input' AND i.reference_name = 'base-sowing_with_spraying-0'"
    # Rename interventions spraying_on_cultivation with spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-spraying_on_cultivation-0'"
    # Merge plant_medicine infos into plant_medicine_to_spray and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'plant_medicine' AND intervention_casts.reference_name = 'plant_medicine_to_spray' AND oi.reference_name = 'base-spraying-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'plant_medicine' AND i.reference_name = 'base-spraying-0')"
    execute "UPDATE intervention_casts SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'plant_medicine_to_spray' AND i.reference_name = 'base-spraying-0'"
    # Rename interventions watering with plant_watering
    execute "UPDATE interventions SET reference_name = 'base-plant_watering-0' WHERE reference_name = 'base-watering-0'"
    # Merge water infos into water_to_spread and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'water' AND intervention_casts.reference_name = 'water_to_spread' AND oi.reference_name = 'base-plant_watering-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'water' AND i.reference_name = 'base-plant_watering-0')"
    execute "UPDATE intervention_casts SET reference_name = 'water' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'water_to_spread' AND i.reference_name = 'base-plant_watering-0'"
    # Merge seeds infos into seeds_to_sow and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'seeds' AND intervention_casts.reference_name = 'seeds_to_sow' AND oi.reference_name = 'base-all_in_one_sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'seeds' AND i.reference_name = 'base-all_in_one_sowing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'seeds' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'seeds_to_sow' AND i.reference_name = 'base-all_in_one_sowing-0'"
    # Merge fertilizer infos into fertilizer_to_spread and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'fertilizer' AND intervention_casts.reference_name = 'fertilizer_to_spread' AND oi.reference_name = 'base-all_in_one_sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'fertilizer' AND i.reference_name = 'base-all_in_one_sowing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'fertilizer' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'fertilizer_to_spread' AND i.reference_name = 'base-all_in_one_sowing-0'"
    # Merge insecticide infos into insecticide_to_input and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'insecticide' AND intervention_casts.reference_name = 'insecticide_to_input' AND oi.reference_name = 'base-all_in_one_sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'insecticide' AND i.reference_name = 'base-all_in_one_sowing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'insecticide' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'insecticide_to_input' AND i.reference_name = 'base-all_in_one_sowing-0'"
    # Merge molluscicide infos into molluscicide_to_input and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'molluscicide' AND intervention_casts.reference_name = 'molluscicide_to_input' AND oi.reference_name = 'base-all_in_one_sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'molluscicide' AND i.reference_name = 'base-all_in_one_sowing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'molluscicide' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'molluscicide_to_input' AND i.reference_name = 'base-all_in_one_sowing-0'"
    # Merge vial infos into vial_to_give and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'vial' AND intervention_casts.reference_name = 'vial_to_give' AND oi.reference_name = 'base-animal_artificial_insemination-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'vial' AND i.reference_name = 'base-animal_artificial_insemination-0')"
    execute "UPDATE intervention_casts SET reference_name = 'vial' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'vial_to_give' AND i.reference_name = 'base-animal_artificial_insemination-0'"
    # Remove casts excrement_zone from animal_housing_cleaning interventions
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'excrement_zone' AND i.reference_name = 'base-animal_housing_cleaning-0')"
    # Merge straw infos into straw_to_mulch and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'straw' AND intervention_casts.reference_name = 'straw_to_mulch' AND oi.reference_name = 'base-animal_housing_mulching-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'straw' AND i.reference_name = 'base-animal_housing_mulching-0')"
    execute "UPDATE intervention_casts SET reference_name = 'straw' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'straw_to_mulch' AND i.reference_name = 'base-animal_housing_mulching-0'"
    # Merge oenological_intrant infos into oenological_intrant_to_put and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oenological_intrant' AND intervention_casts.reference_name = 'oenological_intrant_to_put' AND oi.reference_name = 'base-chaptalization-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oenological_intrant' AND i.reference_name = 'base-chaptalization-0')"
    execute "UPDATE intervention_casts SET reference_name = 'oenological_intrant' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'oenological_intrant_to_put' AND i.reference_name = 'base-chaptalization-0'"
    # Merge oenological_intrant infos into oenological_intrant_to_put and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oenological_intrant' AND intervention_casts.reference_name = 'oenological_intrant_to_put' AND oi.reference_name = 'base-enzyme_addition-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oenological_intrant' AND i.reference_name = 'base-enzyme_addition-0')"
    execute "UPDATE intervention_casts SET reference_name = 'oenological_intrant' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'oenological_intrant_to_put' AND i.reference_name = 'base-enzyme_addition-0'"
    # Merge oenological_intrant infos into oenological_intrant_to_put and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oenological_intrant' AND intervention_casts.reference_name = 'oenological_intrant_to_put' AND oi.reference_name = 'base-fermentation-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oenological_intrant' AND i.reference_name = 'base-fermentation-0')"
    execute "UPDATE intervention_casts SET reference_name = 'oenological_intrant' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'oenological_intrant_to_put' AND i.reference_name = 'base-fermentation-0'"
    # Merge fuel infos into fuel_to_input and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'fuel' AND intervention_casts.reference_name = 'fuel_to_input' AND oi.reference_name = 'base-fuel_up-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'fuel' AND i.reference_name = 'base-fuel_up-0')"
    execute "UPDATE intervention_casts SET reference_name = 'fuel' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'fuel_to_input' AND i.reference_name = 'base-fuel_up-0'"
    # Remove interventions grain_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-grain_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-grain_transport-0'"
    # Merge grape infos into grape_to_press and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'grape' AND intervention_casts.reference_name = 'grape_to_press' AND oi.reference_name = 'base-grape_pressing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'grape' AND i.reference_name = 'base-grape_pressing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'grape' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'grape_to_press' AND i.reference_name = 'base-grape_pressing-0'"
    # Remove interventions grape_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-grape_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-grape_transport-0'"
    # Remove interventions hazelnuts_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-hazelnuts_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-hazelnuts_transport-0'"
    # Merge silage infos into silage_to_give and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'silage' AND intervention_casts.reference_name = 'silage_to_give' AND oi.reference_name = 'base-manual_feeding-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'silage' AND i.reference_name = 'base-manual_feeding-0')"
    execute "UPDATE intervention_casts SET reference_name = 'silage' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'silage_to_give' AND i.reference_name = 'base-manual_feeding-0'"
    # Merge oil infos into oil_to_input and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oil' AND intervention_casts.reference_name = 'oil_to_input' AND oi.reference_name = 'base-oil_replacement-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oil' AND i.reference_name = 'base-oil_replacement-0')"
    execute "UPDATE intervention_casts SET reference_name = 'oil' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'oil_to_input' AND i.reference_name = 'base-oil_replacement-0'"
    # Merge wine infos into wine_to_move and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'wine' AND intervention_casts.reference_name = 'wine_to_move' AND oi.reference_name = 'base-partial_wine_transfer-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wine' AND i.reference_name = 'base-partial_wine_transfer-0')"
    execute "UPDATE intervention_casts SET reference_name = 'wine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'wine_to_move' AND i.reference_name = 'base-partial_wine_transfer-0'"
    # Remove interventions silage_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-silage_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-silage_transport-0'"
    # Merge silage infos into silage_to_give and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'silage' AND intervention_casts.reference_name = 'silage_to_give' AND oi.reference_name = 'base-silage_unload-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'silage' AND i.reference_name = 'base-silage_unload-0')"
    execute "UPDATE intervention_casts SET reference_name = 'silage' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'silage_to_give' AND i.reference_name = 'base-silage_unload-0'"
    # Merge seeds infos into seeds_to_sow and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'seeds' AND intervention_casts.reference_name = 'seeds_to_sow' AND oi.reference_name = 'base-sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'seeds' AND i.reference_name = 'base-sowing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'seeds' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'seeds_to_sow' AND i.reference_name = 'base-sowing-0'"
    # Merge stakes infos into stakes_to_plant and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'stakes' AND intervention_casts.reference_name = 'stakes_to_plant' AND oi.reference_name = 'base-standard_enclosing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'stakes' AND i.reference_name = 'base-standard_enclosing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'stakes' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'stakes_to_plant' AND i.reference_name = 'base-standard_enclosing-0'"
    # Merge wire_fence infos into wire_fence_to_put and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'wire_fence' AND intervention_casts.reference_name = 'wire_fence_to_put' AND oi.reference_name = 'base-standard_enclosing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wire_fence' AND i.reference_name = 'base-standard_enclosing-0')"
    execute "UPDATE intervention_casts SET reference_name = 'wire_fence' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'wire_fence_to_put' AND i.reference_name = 'base-standard_enclosing-0'"
    # Remove interventions straw_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-straw_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-straw_transport-0'"
    # Merge oenological_intrant infos into oenological_intrant_to_put and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oenological_intrant' AND intervention_casts.reference_name = 'oenological_intrant_to_put' AND oi.reference_name = 'base-sulfur_addition-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oenological_intrant' AND i.reference_name = 'base-sulfur_addition-0')"
    execute "UPDATE intervention_casts SET reference_name = 'oenological_intrant' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'oenological_intrant_to_put' AND i.reference_name = 'base-sulfur_addition-0'"
    # Remove interventions walnuts_transport
    execute "DELETE FROM intervention_casts WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name = 'base-walnuts_transport-0')"
    execute "DELETE FROM interventions WHERE reference_name = 'base-walnuts_transport-0'"
    # Merge wine infos into wine_to_blend and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'wine' AND intervention_casts.reference_name = 'wine_to_blend' AND oi.reference_name = 'base-wine_blending-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wine' AND i.reference_name = 'base-wine_blending-0')"
    execute "UPDATE intervention_casts SET reference_name = 'wine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'wine_to_blend' AND i.reference_name = 'base-wine_blending-0'"
    # Merge adding_wine infos into adding_wine_to_blend and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'adding_wine' AND intervention_casts.reference_name = 'adding_wine_to_blend' AND oi.reference_name = 'base-wine_blending-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'adding_wine' AND i.reference_name = 'base-wine_blending-0')"
    execute "UPDATE intervention_casts SET reference_name = 'adding_wine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'adding_wine_to_blend' AND i.reference_name = 'base-wine_blending-0'"
    # Merge wine infos into wine_to_pack and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'wine' AND intervention_casts.reference_name = 'wine_to_pack' AND oi.reference_name = 'base-wine_bottling-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wine' AND i.reference_name = 'base-wine_bottling-0')"
    execute "UPDATE intervention_casts SET reference_name = 'wine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'wine_to_pack' AND i.reference_name = 'base-wine_bottling-0'"
    # Merge bottles infos into bottles_to_use and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'bottles' AND intervention_casts.reference_name = 'bottles_to_use' AND oi.reference_name = 'base-wine_bottling-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'bottles' AND i.reference_name = 'base-wine_bottling-0')"
    execute "UPDATE intervention_casts SET reference_name = 'bottles' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'bottles_to_use' AND i.reference_name = 'base-wine_bottling-0'"
    # Merge corks infos into corks_to_use and rename it
    execute "UPDATE intervention_casts SET source_product_id = origin.product_id FROM interventions AS i, intervention_casts AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'corks' AND intervention_casts.reference_name = 'corks_to_use' AND oi.reference_name = 'base-wine_bottling-0' AND oi.reference_name = i.reference_name AND i.id = intervention_casts.intervention_id"
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'corks' AND i.reference_name = 'base-wine_bottling-0')"
    execute "UPDATE intervention_casts SET reference_name = 'corks' FROM interventions AS i WHERE i.id = intervention_id AND intervention_casts.reference_name = 'corks_to_use' AND i.reference_name = 'base-wine_bottling-0'"
    # Remove casts wine_storage from wine_bottling interventions
    execute "DELETE FROM intervention_casts WHERE id IN (SELECT c.id FROM intervention_casts AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wine_storage' AND i.reference_name = 'base-wine_bottling-0')"
    # target
    execute "UPDATE intervention_casts SET type = 'InterventionTarget' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('mother', 'bird_band', 'land_parcel', 'equipment', 'mammal_to_milk', 'sortable', 'animal_housing', 'wine_to_treat', 'juice_to_ferment', 'tank_for_wine') OR (intervention_casts.reference_name = 'animal' AND i.reference_name IN ('base-animal_antibiotic_treatment-0', 'base-animal_artificial_insemination-0')) OR (intervention_casts.reference_name = 'cultivation' AND i.reference_name IN ('base-mechanical_harvesting-0', 'base-spraying-0', 'base-plant_watering-0', 'base-cutting-0', 'base-detasseling-0', 'base-direct_silage-0', 'base-pasturing-0', 'base-plant_mowing-0', 'base-plantation_unfixing-0')) OR (intervention_casts.reference_name = 'herd' AND i.reference_name IN ('base-animal_group_changing-0', 'base-manual_feeding-0', 'base-silage_unload-0')) OR (intervention_casts.reference_name = 'wine' AND i.reference_name IN ('base-complete_wine_transfer-0', 'base-partial_wine_transfer-0', 'base-wine_bottling-0')))"
    # input
    execute "UPDATE intervention_casts SET type = 'InterventionInput' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('animal_medicine', 'plants', 'item', 'fertilizer', 'plastic', 'seeds', 'insecticide', 'molluscicide', 'plant_medicine', 'water', 'vial', 'oenological_intrant', 'fuel', 'grape', 'straw_to_bunch', 'oil', 'stakes', 'wire_fence', 'adding_wine', 'bottles', 'corks') OR (intervention_casts.reference_name = 'animal' AND i.reference_name = 'base-animal_group_changing-0') OR (intervention_casts.reference_name = 'straw' AND i.reference_name = 'base-animal_housing_mulching-0') OR (intervention_casts.reference_name = 'silage' AND i.reference_name IN ('base-manual_feeding-0', 'base-silage_unload-0')) OR (intervention_casts.reference_name = 'wine' AND i.reference_name IN ('base-wine_blending-0', 'base-wine_bottling-0')))"
    # doer
    execute "UPDATE intervention_casts SET type = 'InterventionDoer' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('caregiver', 'doer', 'cropper_driver', 'driver', 'implanter_man', 'mechanic', 'inseminator', 'wine_man', 'forager_driver', 'mower_driver', 'baler_driver'))"
    # output
    execute "UPDATE intervention_casts SET type = 'InterventionOutput' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('child', 'eggs', 'grains', 'straws', 'milk', 'excrement', 'fermented_juice', 'juice', 'residue', 'grass', 'straw_bales', 'wine_blended', 'wine_bottles') OR (intervention_casts.reference_name = 'cultivation' AND i.reference_name IN ('base-mechanical_planting-0', 'base-sowing_with_spraying-0', 'base-all_in_one_sowing-0', 'base-sowing-0')) OR (intervention_casts.reference_name = 'silage' AND i.reference_name IN ('base-direct_silage-0', 'base-indirect_silage-0')) OR (intervention_casts.reference_name = 'straw' AND i.reference_name = 'base-plant_mowing-0'))"
    # tool
    execute "UPDATE intervention_casts SET type = 'InterventionTool' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_casts.reference_name IN ('cropper', 'tractor', 'grinder', 'implanter_tool', 'spreader', 'implanter', 'container', 'variant', 'sower', 'sprayer', 'cleaner', 'tank', 'destination_tank', 'cutter', 'forager', 'tank_for_residue', 'press', 'cultivator', 'mower', 'compressor', 'plow', 'harrow', 'silage_unloader', 'baler', 'hand_drawn', 'corker') OR (intervention_casts.reference_name = 'herd' AND i.reference_name = 'base-pasturing-0'))"

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
