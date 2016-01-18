class SimplifyInterventions < ActiveRecord::Migration
  TASK_TABLES = [:product_enjoyments, :product_junctions, :product_links,
                 :product_linkages, :product_localizations, :product_memberships,
                 :product_ownerships, :product_phases, :product_reading_tasks].freeze

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
  ].freeze

  TYPE_COLUMNS = [
    [:affairs, :type],
    [:products, :type],
    [:custom_fields, :customized_type]
  ].freeze

  MULTI_POLYGON_COLUMNS = {
    # Generic
    activity_productions: [:support_shape],
    cultivable_zones: [:shape],
    # georeadings: [:content],
    intervention_parameters: [:working_zone],
    inventory_items: [:actual_shape, :expected_shape],
    parcel_items: [:shape],
    products: [:initial_shape],
    # Reading mode
    analysis_items: [:geometry_value],
    intervention_parameter_readings: [:geometry_value],
    product_nature_variant_readings: [:geometry_value],
    product_readings: [:geometry_value],
    # Polygons ?
    cap_islets: [:shape],
    cap_land_parcels: [:shape]
  }.freeze

  ALL_TYPE_COLUMNS = TYPE_COLUMNS +
                     POLYMORPHIC_REFERENCES.map { |a| [a.first, "#{a.second}_type".to_sym] }

  PROCEDURES = {
    animal_artificial_insemination: { mandatory: [:animal_artificial_insemination] },
    parturition: { mandatory: [:parturition] },
    manual_feeding: { mandatory: [:animal_feeding] },
    pasturing: { mandatory: [:animal_feeding] },
    silage_unload: { mandatory: [:animal_feeding] },
    egg_collecting: { mandatory: [:egg_collecting] },
    milking: { mandatory: [:milking] },
    animal_antibiotic_treatment: { mandatory: [:disease_treatment] },
    animal_group_changing: { mandatory: [:animal_group_changing] },
    crop_residues_grinding: {
      mandatory: [:residue_destruction, :organic_matter_burying],
      optional: [:organic_fertilization]
    },
    cutting: { mandatory: [:cutting] },
    detasseling: { mandatory: [:detasseling] },
    field_plant_sorting: { mandatory: [:field_plant_sorting] },
    hoeing: { optional: [:weeding, :loosening] },
    plantation_unfixing: { mandatory: [:plantation_unfixing] },
    plant_mulching: { optional: [:organic_fertilization] },
    spraying: {
      optional: [:herbicide, :fungicide, :insecticide, :growth_regulator,
                 :molluscicide, :nematicide, :acaricide, :bactericide,
                 :rodenticide, :talpicide, :corvicide, :game_repellent]
    },
    fuel_up: { mandatory: [:fuel_up] },
    equipment_item_replacement: { mandatory: [:troubleshooting] },
    oil_replacement: { mandatory: [:oil_replacement] },
    mechanical_fertilizing: {
      mandatory: [:fertilization],
      optional: [:biostimulation, :organic_fertilization, :mineral_fertilization,
                 :micronutrient_fertilization, :liming]
    },
    animal_housing_cleaning: { mandatory: [:hygiene] },
    animal_housing_mulching: { mandatory: [:animal_housing_mulching] },
    direct_silage: { mandatory: [:harvest] },
    mechanical_harvesting: { mandatory: [:harvest] },
    plant_mowing: { mandatory: [:harvest] },
    straw_bunching: { mandatory: [:straw_bunching] },
    standard_enclosing: { optional: [:animal_penning, :game_protection] },
    plant_watering: { mandatory: [:irrigation] },
    ground_destratification: { mandatory: [:loosening] },
    mechanical_planting: { mandatory: [:planting] },
    sowing: { mandatory: [:sowing] },
    sowing_with_spraying: {
      mandatory: [:sowing],
      optional: [:herbicide, :fungicide, :insecticide, :growth_regulator,
                 :molluscicide, :nematicide, :acaricide, :bactericide,
                 :rodenticide, :talpicide, :corvicide, :game_repellent]
    },
    all_in_one_sowing: {
      mandatory: [:sowing, :fertilization],
      optional: [:herbicide, :fungicide, :insecticide, :growth_regulator,
                 :molluscicide, :nematicide, :acaricide, :bactericide,
                 :rodenticide, :talpicide, :corvicide, :game_repellent]
    },
    indirect_silage: { mandatory: [:indirect_silage] },
    land_parcel_grinding: { mandatory: [:land_parcel_grinding] },
    raking: { mandatory: [:loosening], optional: [:sowing_burying] },
    uncompacting: { mandatory: [:loosening] },
    plowing: {
      mandatory: [:plowing, :loosening],
      optional: [:herbicide, :organic_matter_burying, :water_flow_improvement]
    },
    superficial_plowing: {
      mandatory: [:plowing, :loosening],
      optional: [:herbicide, :organic_matter_burying]
    },
    chaptalization: { mandatory: [:chaptalization] },
    complete_wine_transfer: { mandatory: [:complete_wine_transfer] },
    enzyme_addition: { mandatory: [:enzyme_addition] },
    fermentation: { mandatory: [:fermentation] },
    grape_pressing: { mandatory: [:grape_pressing] },
    partial_wine_transfer: { mandatory: [:partial_wine_transfer] },
    sulfur_addition: { mandatory: [:sulfur_addition] },
    wine_blending: { mandatory: [:wine_blending] },
    wine_bottling: { mandatory: [:wine_bottling] }
  }.freeze

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
        execute "UPDATE campaigns SET started_on = ((COALESCE(harvest_year, 1500)-1)::VARCHAR || '-09-01')::DATE, stopped_on = (COALESCE(harvest_year, 1500)::VARCHAR || '-08-31')::DATE"
      end
    end

    # Updates activities
    add_column :activities, :size_indicator_name, :string
    add_column :activities, :size_unit_name, :string
    add_column :activities, :suspended, :boolean, null: false, default: false
    reversible do |d|
      d.up do
        execute "UPDATE activities SET size_indicator_name = support_variant_indicator, size_unit_name = support_variant_unit FROM productions WHERE activity_id = activities.id AND support_variant_indicator != 'population'"
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
    add_column :activity_productions, :started_on, :date
    add_column :activity_productions, :stopped_on, :date
    add_column :activity_productions, :state, :string
    add_column :activity_productions, :rank_number, :integer
    rename_column :activity_productions, :storage_id, :support_id
    rename_column :activity_productions, :production_usage, :usage
    rename_column :activity_productions, :quantity, :size_value
    rename_column :activity_productions, :quantity_indicator, :size_indicator_name
    rename_column :activity_productions, :quantity_unit, :size_unit_name
    reversible do |d|
      d.up do
        # Sets cultivable_zone column when possible
        execute 'UPDATE activity_productions SET cultivable_zone_id = support_id WHERE support_id IN (SELECT id FROM products WHERE type = \'CultivableZone\')'
        execute 'UPDATE activity_productions SET cultivable_zone_id = cultivable_zones.id FROM cultivable_zones WHERE support_id = product_id'

        # Updates attributes coming from old Production
        execute 'UPDATE activity_productions SET activity_id = p.activity_id, state = p.state, irrigated = p.irrigated, nitrate_fixing = p.nitrate_fixing, started_on = COALESCE(p.started_at, c.started_on), stopped_on = COALESCE(p.stopped_at, c.stopped_on) FROM productions AS p LEFT JOIN campaigns AS c ON (p.campaign_id = c.id) WHERE p.id = activity_productions.production_id'
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

    rename_table_and_co :intervention_casts, :intervention_parameters
    revert do
      add_column :intervention_parameters, :roles, :string
    end
    # TODO: restore roles values
    reversible do |d|
      d.up do
        remove_column :intervention_parameters, :nature
      end
      d.down do
        add_column :intervention_parameters, :nature, :string
        execute "UPDATE intervention_parameters SET nature = 'product'"
        # TODO: Set variant if old cast is variant
        change_column_null :intervention_parameters, :nature, false
      end
    end
    rename_column :crumbs, :intervention_cast_id, :intervention_parameter_id

    # Intervention(Cast|Doer|Input|Output|Target|Tool)
    # add_reference :intervention_parameters, :source_product, index: true
    add_reference :intervention_parameters, :outcoming_product, index: true
    add_column :intervention_parameters, :type, :string
    add_index :intervention_parameters, :type

    # - Localization
    add_reference :intervention_parameters, :new_container, index: true

    # - Group
    add_reference :intervention_parameters, :new_group, index: true

    # - Phase
    add_reference :intervention_parameters, :new_variant, index: true

    # - Readings: InterventionCastReading
    rename_table_and_co :product_reading_tasks, :intervention_parameter_readings
    add_reference :intervention_parameter_readings, :parameter, index: true
    reversible do |d|
      d.up do
        puts select_value('SELECT count(*) FROM intervention_parameter_readings WHERE parameter_id IS NULL').inspect.green
        # Try to find cast with cast as originator
        execute "UPDATE intervention_parameter_readings SET parameter_id = originator_id WHERE parameter_id IS NULL AND intervention_id IS NULL AND originator_type = 'InterventionCast'"
        puts select_value('SELECT count(*) FROM intervention_parameter_readings WHERE parameter_id IS NULL').inspect.green

        # Try to find cast within casts of same intervention
        execute 'UPDATE intervention_parameter_readings SET parameter_id = c.id FROM intervention_parameters AS c WHERE parameter_id IS NULL AND c.intervention_id = intervention_parameter_readings.intervention_id AND c.actor_id = intervention_parameter_readings.product_id'
        puts select_value('SELECT count(*) FROM intervention_parameter_readings WHERE parameter_id IS NULL').inspect.green

        # Try to find cast with intervention as originator
        execute "UPDATE intervention_parameter_readings SET parameter_id = c.id FROM intervention_parameters AS c WHERE parameter_id IS NULL AND c.intervention_id = intervention_parameter_readings.originator_id AND intervention_parameter_readings.originator_type = 'Intervention' AND c.actor_id = intervention_parameter_readings.product_id"
        puts select_value('SELECT count(*) FROM intervention_parameter_readings WHERE parameter_id IS NULL').inspect.green

        # Try to find first cast within casts of intervention
        execute 'UPDATE intervention_parameter_readings SET parameter_id = c.id FROM intervention_parameters AS c WHERE parameter_id IS NULL AND c.intervention_id = intervention_parameter_readings.intervention_id'

        removed_ids = select_rows('SELECT id FROM intervention_parameter_readings WHERE parameter_id IS NULL')
        if removed_ids.any?
          say "Following reading task will be removed: #{removed_ids.join(', ')}"
          execute('DELETE FROM intervention_parameter_readings WHERE parameter_id IS NULL')
        end
      end
    end
    change_column_null :intervention_parameter_readings, :parameter_id, false
    revert do
      add_column :intervention_parameter_readings, :started_at, :datetime
      add_column :intervention_parameter_readings, :stopped_at, :datetime
      add_reference :intervention_parameter_readings, :originator, polymorphic: true, index: true
      add_reference :intervention_parameter_readings, :reporter, index: true
      add_reference :intervention_parameter_readings, :tool, index: true
      add_reference :intervention_parameter_readings, :intervention
      add_reference :intervention_parameter_readings, :product
    end

    # - Quantity
    add_column :intervention_parameters, :quantity_handler, :string
    add_column :intervention_parameters, :quantity_value, :decimal, precision: 19, scale: 4
    add_column :intervention_parameters, :quantity_unit_name, :string
    add_column :intervention_parameters, :quantity_indicator_name, :string
    rename_column :intervention_parameters, :population, :quantity_population

    # - Working zone
    rename_column :intervention_parameters, :shape, :working_zone

    # - Product
    rename_column :intervention_parameters, :actor_id, :product_id

    # Add InterventionGroupParameter model
    add_reference :intervention_parameters, :group, index: true
    # create_table :intervention_parameter_groups do |t|
    #   t.references :intervention, null: false, index: true
    #   t.references :group, index: true
    #   t.string :parameter_group_name, null: false
    #   t.stamps
    #   t.index :parameter_group_name
    # end
    # add_reference :intervention_parameters, :group, index: true

    update_interventions

    # Simplifies procedure name. No namespace. No version.
    execute "UPDATE interventions SET reference_name = REPLACE(REPLACE(reference_name, 'base-', ''), '-0', '')"

    # TODO: Update intervention_parameters#type column with existings procedure
    # TODO: Removes 'variant' intervention_parameters records

    remove_reference :cultivable_zones, :product

    rename_column :interventions, :reference_name, :procedure_name
    add_column :interventions, :actions, :string

    reversible do |d|
      d.up do
        # Sets a default actions with procedure_name
        cases = PROCEDURES.map do |procedure, attrs|
          if attrs[:mandatory]
            "WHEN procedure_name = '#{procedure}' THEN '#{attrs[:mandatory].join(', ')}'"
          elsif attrs[:optional]
            "WHEN procedure_name = '#{procedure}' THEN '#{attrs[:optional].first}'"
          end
        end.compact
        execute 'UPDATE interventions SET actions = CASE ' + cases.join + ' ELSE procedure_name END'
      end
    end

    revert do
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
        t.references :intervention, null: false, index: true
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

    [:analysis_items, :intervention_parameter_readings, :product_nature_variant_readings,
     :product_readings].each do |table|
      rename_column table, :geometry_value, :multi_polygon_value
      add_column table, :geometry_value, :geometry, srid: 4326
    end

    # ProductJunction becomes useless since Operation disappear because only
    # operations could write junctions.
    # Data because fully useless because procedures determine how products
    # are born, lives and dies. Information would be accessible later if needed
    revert do
      add_column :products, :extjuncted, :boolean, null: false, default: false
      add_reference :parcel_items, :source_product_division, index: true

      create_table :product_junction_ways do |t|
        t.references :junction, null: false, index: true
        t.string 'role',                     null: false
        t.string 'nature',                   null: false
        t.references :product, null: false, index: true
        t.stamps
        t.index :nature
        t.index :role
      end

      create_table :product_junctions do |t|
        t.references :originator, polymorphic: true, index: true
        t.string 'nature', null: false
        t.references :tool, index: true
        t.datetime 'started_at'
        t.datetime 'stopped_at'
        t.stamps
        t.references :intervention, index: true
        t.index :started_at
        t.index :stopped_at
      end
    end

    execute "UPDATE product_readings SET originator_type = NULL, originator_id = NULL WHERE originator_type = 'ProductJunction'"

    create_table :product_movements do |t|
      t.references :reading, index: true
      t.references :product, null: false, index: true
      t.references :intervention, index: true
      t.references :originator, polymorphic: true, index: true
      t.decimal :delta,      precision: 19, scale: 4, null: false
      t.decimal :population, precision: 19, scale: 4, null: false
      t.datetime :started_at, null: false
      t.datetime :stopped_at
      t.stamps
      t.index :started_at
      t.index :stopped_at
    end

    # Move population values to product_movements
    execute "INSERT INTO product_movements (reading_id, product_id, population, delta, started_at, originator_id, originator_type, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, product_id, decimal_value, decimal_value, read_at, originator_id, originator_type, created_at, creator_id, updated_at, updater_id, lock_version FROM product_readings WHERE indicator_name = 'population' ORDER BY product_id, read_at"

    # Product
    add_reference :products, :initial_movement, index: true
    execute 'UPDATE products SET born_at = initial_born_at WHERE born_at IS NULL AND initial_born_at IS NOT NULL'
    execute 'UPDATE products SET initial_movement_id = m.id FROM product_movements AS m WHERE m.started_at = born_at AND products.id = m.product_id'
    execute 'INSERT INTO product_movements (product_id, population, delta, started_at, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, initial_population, initial_population, born_at, created_at, creator_id, updated_at, updater_id, lock_version FROM products WHERE initial_movement_id IS NULL AND initial_population IS NOT NULL AND born_at IS NOT NULL'
    execute 'UPDATE products SET initial_movement_id = m.id FROM product_movements AS m WHERE initial_movement_id IS NULL AND m.started_at = born_at AND products.id = m.product_id'

    # Updates population values
    execute 'UPDATE product_movements SET delta = product_movements.population - previous.population FROM product_movements AS previous WHERE previous.id = product_movements.id - 1 AND previous.product_id = product_movements.product_id'
    execute 'UPDATE product_movements SET stopped_at = following.started_at FROM product_movements AS following WHERE following.id = product_movements.id + 1 AND following.product_id = product_movements.product_id'

    # ParcelItem
    add_reference :parcel_items, :product_movement, index: true
    add_reference :parcel_items, :source_product_movement, index: true
    execute 'UPDATE parcel_items SET source_product_movement_id = m.id FROM product_movements AS m WHERE m.reading_id = source_product_population_reading_id'
    execute 'UPDATE parcel_items SET product_movement_id = m.id FROM product_movements AS m WHERE m.reading_id = product_population_reading_id'
    remove_reference :parcel_items, :product_population_reading
    remove_reference :parcel_items, :source_product_population_reading

    # InventoryItem
    add_reference :inventory_items, :product_movement, index: true
    execute "UPDATE inventory_items SET product_movement_id = m.id FROM product_movements AS m WHERE m.originator_type = 'InventoryItem' AND m.originator_id = inventory_items.id"
    remove_column :inventory_items, :actual_shape
    remove_column :inventory_items, :expected_shape

    # ProductNature
    execute "UPDATE product_natures SET frozen_indicators_list = NULLIF(ARRAY_TO_STRING(ARRAY_REMOVE(STRING_TO_ARRAY(frozen_indicators_list, ', '), 'population'), ', '), ''), variable_indicators_list = NULLIF(ARRAY_TO_STRING(ARRAY_REMOVE(STRING_TO_ARRAY(variable_indicators_list, ', '), 'population'), ', '), '')"

    # Removes all population indicator data
    %w(product_readings analysis_items intervention_parameter_readings product_nature_variant_readings).each do |table|
      execute "DELETE FROM #{table} WHERE indicator_name = 'population'"
    end

    remove_reference :product_movements, :reading
  end

  protected

  def update_interventions
    # Remove not wanted interventions
    execute "DELETE FROM intervention_parameters WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name IN ('base-administrative_task-0', 'base-attach-0', 'base-detach-0', 'base-double_chemical_mixing-0', 'base-double_seed_mixing-0', 'base-filling-0', 'base-group_exclusion-0', 'base-group_inclusion-0', 'base-maintenance_task-0', 'base-product_evolution-0', 'base-product_moving-0', 'base-technical_task-0', 'base-triple_seed_mixing-0'))"
    execute "DELETE FROM interventions WHERE reference_name IN ('base-administrative_task-0', 'base-attach-0', 'base-detach-0', 'base-double_chemical_mixing-0', 'base-double_seed_mixing-0', 'base-filling-0', 'base-group_exclusion-0', 'base-group_inclusion-0', 'base-maintenance_task-0', 'base-product_evolution-0', 'base-product_moving-0', 'base-technical_task-0', 'base-triple_seed_mixing-0')"
    # Merge interventions calving_twin casts into parturition's
    execute "UPDATE intervention_parameters SET reference_name = 'child' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_child' AND i.reference_name = 'base-calving_twin-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'child' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_child' AND i.reference_name = 'base-calving_twin-0'"
    # Merge interventions calving_twin into parturition
    execute "UPDATE interventions SET reference_name = 'base-parturition-0' WHERE reference_name = 'base-calving_twin-0'"
    # Merge interventions chemical_weed_killing casts into spraying's
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'weedkiller' AND i.reference_name = 'base-chemical_weed_killing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'weedkiller_to_spray' AND i.reference_name = 'base-chemical_weed_killing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'cultivation' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'land_parcel' AND i.reference_name = 'base-chemical_weed_killing-0'"
    # Merge interventions chemical_weed_killing into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-chemical_weed_killing-0'"
    # Merge interventions double_food_mixing casts into food_preparation's
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'food_storage' AND i.reference_name = 'base-double_food_mixing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_food_input' AND i.reference_name = 'base-double_food_mixing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_food_input_to_use' AND i.reference_name = 'base-double_food_mixing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_food_input' AND i.reference_name = 'base-double_food_mixing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_food_input_to_use' AND i.reference_name = 'base-double_food_mixing-0'"
    # Merge interventions double_food_mixing into food_preparation
    execute "UPDATE interventions SET reference_name = 'base-food_preparation-0' WHERE reference_name = 'base-double_food_mixing-0'"
    # Merge interventions double_spraying_on_cultivation casts into spraying's
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_plant_medicine' AND i.reference_name = 'base-double_spraying_on_cultivation-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray' AND i.reference_name = 'base-double_spraying_on_cultivation-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_plant_medicine' AND i.reference_name = 'base-double_spraying_on_cultivation-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray' AND i.reference_name = 'base-double_spraying_on_cultivation-0'"
    # Merge interventions double_spraying_on_cultivation into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-double_spraying_on_cultivation-0'"
    # Merge interventions double_spraying_on_land_parcel casts into spraying's
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_plant_medicine' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_plant_medicine' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'cultivation' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'land_parcel' AND i.reference_name = 'base-double_spraying_on_land_parcel-0'"
    # Merge interventions double_spraying_on_land_parcel into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-double_spraying_on_land_parcel-0'"
    # Merge interventions harvest_helping casts into mechanical_harvesting's
    # Merge interventions harvest_helping into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-harvest_helping-0'"
    # Merge interventions hazelnuts_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_parameters SET reference_name = 'cropper_driver' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'driver' AND i.reference_name = 'base-hazelnuts_harvest-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'cropper' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'nuts_harvester' AND i.reference_name = 'base-hazelnuts_harvest-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'hazelnuts' AND i.reference_name = 'base-hazelnuts_harvest-0'"
    # Merge interventions hazelnuts_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-hazelnuts_harvest-0'"
    # Merge interventions implant_helping into mechanical_planting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_planting-0' WHERE reference_name = 'base-implant_helping-0'"
    # Merge interventions mammal_herd_milking casts into milking's
    execute "UPDATE intervention_parameters SET reference_name = 'mammal_to_milk' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'mammal_herd_to_milk' AND i.reference_name = 'base-mammal_herd_milking-0'"
    # Merge interventions mammal_herd_milking into milking
    execute "UPDATE interventions SET reference_name = 'base-milking-0' WHERE reference_name = 'base-mammal_herd_milking-0'"
    # Merge interventions organic_fertilizing casts into mechanical_fertilizing's
    execute "UPDATE intervention_parameters SET reference_name = 'fertilizer' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'manure' AND i.reference_name = 'base-organic_fertilizing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'fertilizer_to_spread' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'manure_to_spread' AND i.reference_name = 'base-organic_fertilizing-0'"
    # Merge interventions organic_fertilizing into mechanical_fertilizing
    execute "UPDATE interventions SET reference_name = 'base-mechanical_fertilizing-0' WHERE reference_name = 'base-organic_fertilizing-0'"
    # Merge interventions plant_grinding casts into crop_residues_grinding's
    # Merge interventions plant_grinding into crop_residues_grinding
    execute "UPDATE interventions SET reference_name = 'base-crop_residues_grinding-0' WHERE reference_name = 'base-plant_grinding-0'"
    # Merge interventions plants_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_parameters SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'plants' AND i.reference_name = 'base-plants_harvest-0'"
    # Merge interventions plants_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-plants_harvest-0'"
    # Merge interventions plums_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_parameters SET reference_name = 'cropper_driver' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'driver' AND i.reference_name = 'base-plums_harvest-0'"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'tractor' AND i.reference_name = 'base-plums_harvest-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'cropper' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'fruit_harvester' AND i.reference_name = 'base-plums_harvest-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'fruits' AND i.reference_name = 'base-plums_harvest-0'"
    # Merge interventions plums_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-plums_harvest-0'"
    # Merge interventions spraying_on_land_parcel casts into spraying's
    execute "UPDATE intervention_parameters SET reference_name = 'cultivation' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'land_parcel' AND i.reference_name = 'base-spraying_on_land_parcel-0'"
    # Merge interventions spraying_on_land_parcel into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-spraying_on_land_parcel-0'"
    # Merge interventions triple_food_mixing casts into food_preparation's
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'food_storage' AND i.reference_name = 'base-triple_food_mixing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_food_input' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_food_input_to_use' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_food_input' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_food_input_to_use' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'third_food_input' AND i.reference_name = 'base-triple_food_mixing-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'food' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'third_food_input_to_use' AND i.reference_name = 'base-triple_food_mixing-0'"
    # Merge interventions triple_food_mixing into food_preparation
    execute "UPDATE interventions SET reference_name = 'base-food_preparation-0' WHERE reference_name = 'base-triple_food_mixing-0'"
    # Merge interventions triple_spraying_on_cultivation casts into spraying's
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_plant_medicine' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_plant_medicine' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'third_plant_medicine' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine_to_spray' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'third_plant_medicine_to_spray' AND i.reference_name = 'base-triple_spraying_on_cultivation-0'"
    # Merge interventions triple_spraying_on_cultivation into spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-triple_spraying_on_cultivation-0'"
    # Merge interventions vine_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_parameters SET reference_name = 'cropper_driver' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'grape_reaper_driver' AND i.reference_name = 'base-vine_harvest-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'cropper' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'grape_reaper' AND i.reference_name = 'base-vine_harvest-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'fruits' AND i.reference_name = 'base-vine_harvest-0'"
    # Merge interventions vine_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-vine_harvest-0'"
    # Merge interventions walnuts_harvest casts into mechanical_harvesting's
    execute "UPDATE intervention_parameters SET reference_name = 'cropper_driver' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'driver' AND i.reference_name = 'base-walnuts_harvest-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'cropper' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'nuts_harvester' AND i.reference_name = 'base-walnuts_harvest-0'"
    execute "UPDATE intervention_parameters SET reference_name = 'grains' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'walnuts' AND i.reference_name = 'base-walnuts_harvest-0'"
    # Merge interventions walnuts_harvest into mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-walnuts_harvest-0'"
    # Rename interventions animal_treatment with animal_antibiotic_treatment
    execute "UPDATE interventions SET reference_name = 'base-animal_antibiotic_treatment-0' WHERE reference_name = 'base-animal_treatment-0'"
    # Merge animal_medicine infos into animal_medicine_to_give and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'animal_medicine' AND intervention_parameters.reference_name = 'animal_medicine_to_give' AND oi.reference_name = 'base-animal_antibiotic_treatment-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'animal_medicine' AND i.reference_name = 'base-animal_antibiotic_treatment-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'animal_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'animal_medicine_to_give' AND i.reference_name = 'base-animal_antibiotic_treatment-0'"
    # Rename interventions calving_one with parturition
    execute "UPDATE interventions SET reference_name = 'base-parturition-0' WHERE reference_name = 'base-calving_one-0'"
    # Rename interventions egg_production with egg_collecting
    execute "UPDATE interventions SET reference_name = 'base-egg_collecting-0' WHERE reference_name = 'base-egg_production-0'"
    # Remove casts container from egg_collecting interventions
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'container' AND i.reference_name = 'base-egg_collecting-0')"
    # Rename interventions grains_harvest with mechanical_harvesting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_harvesting-0' WHERE reference_name = 'base-grains_harvest-0'"
    # Rename interventions grinding with crop_residues_grinding
    execute "UPDATE interventions SET reference_name = 'base-crop_residues_grinding-0' WHERE reference_name = 'base-grinding-0'"
    # Rename interventions implanting with mechanical_planting
    execute "UPDATE interventions SET reference_name = 'base-mechanical_planting-0' WHERE reference_name = 'base-implanting-0'"
    # Merge plants infos into plants_to_fix and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'plants' AND intervention_parameters.reference_name = 'plants_to_fix' AND oi.reference_name = 'base-mechanical_planting-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'plants' AND i.reference_name = 'base-mechanical_planting-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'plants' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'plants_to_fix' AND i.reference_name = 'base-mechanical_planting-0'"
    # Rename interventions item_replacement with equipment_item_replacement
    execute "UPDATE interventions SET reference_name = 'base-equipment_item_replacement-0' WHERE reference_name = 'base-item_replacement-0'"
    # Merge item infos into item_to_change and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'item' AND intervention_parameters.reference_name = 'item_to_change' AND oi.reference_name = 'base-equipment_item_replacement-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'item' AND i.reference_name = 'base-equipment_item_replacement-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'item' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'item_to_change' AND i.reference_name = 'base-equipment_item_replacement-0'"
    # Rename interventions mammal_milking with milking
    execute "UPDATE interventions SET reference_name = 'base-milking-0' WHERE reference_name = 'base-mammal_milking-0'"
    # Remove casts container from milking interventions
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'container' AND i.reference_name = 'base-milking-0')"
    # Rename interventions mineral_fertilizing with mechanical_fertilizing
    execute "UPDATE interventions SET reference_name = 'base-mechanical_fertilizing-0' WHERE reference_name = 'base-mineral_fertilizing-0'"
    # Merge fertilizer infos into fertilizer_to_spread and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'fertilizer' AND intervention_parameters.reference_name = 'fertilizer_to_spread' AND oi.reference_name = 'base-mechanical_fertilizing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'fertilizer' AND i.reference_name = 'base-mechanical_fertilizing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'fertilizer' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'fertilizer_to_spread' AND i.reference_name = 'base-mechanical_fertilizing-0'"
    # Rename interventions plastic_mulching with plant_mulching
    execute "UPDATE interventions SET reference_name = 'base-plant_mulching-0' WHERE reference_name = 'base-plastic_mulching-0'"
    # Merge plastic infos into plastic_to_mulch and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'plastic' AND intervention_parameters.reference_name = 'plastic_to_mulch' AND oi.reference_name = 'base-plant_mulching-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'plastic' AND i.reference_name = 'base-plant_mulching-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'plastic' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'plastic_to_mulch' AND i.reference_name = 'base-plant_mulching-0'"
    # Rename interventions sorting with field_plant_sorting
    execute "UPDATE interventions SET reference_name = 'base-field_plant_sorting-0' WHERE reference_name = 'base-sorting-0'"
    # Merge sortable infos into sortable_to_sort and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'sortable' AND intervention_parameters.reference_name = 'sortable_to_sort' AND oi.reference_name = 'base-field_plant_sorting-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'sortable' AND i.reference_name = 'base-field_plant_sorting-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'sortable' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'sortable_to_sort' AND i.reference_name = 'base-field_plant_sorting-0'"
    # Rename interventions sowing_with_insecticide_and_molluscicide with sowing_with_spraying
    execute "UPDATE interventions SET reference_name = 'base-sowing_with_spraying-0' WHERE reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'"
    # Add group zone for sowing_with_spraying
    execute "INSERT INTO intervention_parameters (intervention_id, type, reference_name, position, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, 'InterventionGroupParameter', 'zone', 999, created_at, creator_id, updated_at, updater_id, lock_version FROM interventions WHERE reference_name = 'base-sowing_with_spraying-0'"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-sowing_with_spraying-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-sowing_with_spraying-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id"
    # Merge seeds infos into seeds_to_sow and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'seeds' AND intervention_parameters.reference_name = 'seeds_to_sow' AND oi.reference_name = 'base-sowing_with_spraying-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'seeds' AND i.reference_name = 'base-sowing_with_spraying-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'seeds' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'seeds_to_sow' AND i.reference_name = 'base-sowing_with_spraying-0'"
    # Merge insecticide infos into insecticide_to_input and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'insecticide' AND intervention_parameters.reference_name = 'insecticide_to_input' AND oi.reference_name = 'base-sowing_with_spraying-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'insecticide' AND i.reference_name = 'base-sowing_with_spraying-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'insecticide' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'insecticide_to_input' AND i.reference_name = 'base-sowing_with_spraying-0'"
    # Merge molluscicide infos into molluscicide_to_input and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'molluscicide' AND intervention_parameters.reference_name = 'molluscicide_to_input' AND oi.reference_name = 'base-sowing_with_spraying-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'molluscicide' AND i.reference_name = 'base-sowing_with_spraying-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'molluscicide' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'molluscicide_to_input' AND i.reference_name = 'base-sowing_with_spraying-0'"
    # Rename interventions spraying_on_cultivation with spraying
    execute "UPDATE interventions SET reference_name = 'base-spraying-0' WHERE reference_name = 'base-spraying_on_cultivation-0'"
    # Merge plant_medicine infos into plant_medicine_to_spray and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'plant_medicine' AND intervention_parameters.reference_name = 'plant_medicine_to_spray' AND oi.reference_name = 'base-spraying-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'plant_medicine' AND i.reference_name = 'base-spraying-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'plant_medicine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'plant_medicine_to_spray' AND i.reference_name = 'base-spraying-0'"
    # Rename interventions watering with plant_watering
    execute "UPDATE interventions SET reference_name = 'base-plant_watering-0' WHERE reference_name = 'base-watering-0'"
    # Merge water infos into water_to_spread and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'water' AND intervention_parameters.reference_name = 'water_to_spread' AND oi.reference_name = 'base-plant_watering-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'water' AND i.reference_name = 'base-plant_watering-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'water' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'water_to_spread' AND i.reference_name = 'base-plant_watering-0'"
    # Add group zone for all_in_one_sowing
    execute "INSERT INTO intervention_parameters (intervention_id, type, reference_name, position, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, 'InterventionGroupParameter', 'zone', 999, created_at, creator_id, updated_at, updater_id, lock_version FROM interventions WHERE reference_name = 'base-all_in_one_sowing-0'"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-all_in_one_sowing-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-all_in_one_sowing-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id"
    # Merge seeds infos into seeds_to_sow and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'seeds' AND intervention_parameters.reference_name = 'seeds_to_sow' AND oi.reference_name = 'base-all_in_one_sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'seeds' AND i.reference_name = 'base-all_in_one_sowing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'seeds' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'seeds_to_sow' AND i.reference_name = 'base-all_in_one_sowing-0'"
    # Merge fertilizer infos into fertilizer_to_spread and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'fertilizer' AND intervention_parameters.reference_name = 'fertilizer_to_spread' AND oi.reference_name = 'base-all_in_one_sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'fertilizer' AND i.reference_name = 'base-all_in_one_sowing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'fertilizer' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'fertilizer_to_spread' AND i.reference_name = 'base-all_in_one_sowing-0'"
    # Merge insecticide infos into insecticide_to_input and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'insecticide' AND intervention_parameters.reference_name = 'insecticide_to_input' AND oi.reference_name = 'base-all_in_one_sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'insecticide' AND i.reference_name = 'base-all_in_one_sowing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'insecticide' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'insecticide_to_input' AND i.reference_name = 'base-all_in_one_sowing-0'"
    # Merge molluscicide infos into molluscicide_to_input and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'molluscicide' AND intervention_parameters.reference_name = 'molluscicide_to_input' AND oi.reference_name = 'base-all_in_one_sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'molluscicide' AND i.reference_name = 'base-all_in_one_sowing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'molluscicide' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'molluscicide_to_input' AND i.reference_name = 'base-all_in_one_sowing-0'"
    # Merge vial infos into vial_to_give and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'vial' AND intervention_parameters.reference_name = 'vial_to_give' AND oi.reference_name = 'base-animal_artificial_insemination-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'vial' AND i.reference_name = 'base-animal_artificial_insemination-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'vial' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'vial_to_give' AND i.reference_name = 'base-animal_artificial_insemination-0'"
    # Remove casts excrement_zone from animal_housing_cleaning interventions
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'excrement_zone' AND i.reference_name = 'base-animal_housing_cleaning-0')"
    # Merge straw infos into straw_to_mulch and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'straw' AND intervention_parameters.reference_name = 'straw_to_mulch' AND oi.reference_name = 'base-animal_housing_mulching-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'straw' AND i.reference_name = 'base-animal_housing_mulching-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'straw' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'straw_to_mulch' AND i.reference_name = 'base-animal_housing_mulching-0'"
    # Merge oenological_intrant infos into oenological_intrant_to_put and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oenological_intrant' AND intervention_parameters.reference_name = 'oenological_intrant_to_put' AND oi.reference_name = 'base-chaptalization-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oenological_intrant' AND i.reference_name = 'base-chaptalization-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'oenological_intrant' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'oenological_intrant_to_put' AND i.reference_name = 'base-chaptalization-0'"
    # Merge oenological_intrant infos into oenological_intrant_to_put and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oenological_intrant' AND intervention_parameters.reference_name = 'oenological_intrant_to_put' AND oi.reference_name = 'base-enzyme_addition-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oenological_intrant' AND i.reference_name = 'base-enzyme_addition-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'oenological_intrant' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'oenological_intrant_to_put' AND i.reference_name = 'base-enzyme_addition-0'"
    # Merge oenological_intrant infos into oenological_intrant_to_put and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oenological_intrant' AND intervention_parameters.reference_name = 'oenological_intrant_to_put' AND oi.reference_name = 'base-fermentation-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oenological_intrant' AND i.reference_name = 'base-fermentation-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'oenological_intrant' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'oenological_intrant_to_put' AND i.reference_name = 'base-fermentation-0'"
    # Merge fuel infos into fuel_to_input and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'fuel' AND intervention_parameters.reference_name = 'fuel_to_input' AND oi.reference_name = 'base-fuel_up-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'fuel' AND i.reference_name = 'base-fuel_up-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'fuel' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'fuel_to_input' AND i.reference_name = 'base-fuel_up-0'"
    # Merge grape infos into grape_to_press and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'grape' AND intervention_parameters.reference_name = 'grape_to_press' AND oi.reference_name = 'base-grape_pressing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'grape' AND i.reference_name = 'base-grape_pressing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'grape' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'grape_to_press' AND i.reference_name = 'base-grape_pressing-0'"
    # Merge silage infos into silage_to_give and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'silage' AND intervention_parameters.reference_name = 'silage_to_give' AND oi.reference_name = 'base-manual_feeding-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'silage' AND i.reference_name = 'base-manual_feeding-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'silage' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'silage_to_give' AND i.reference_name = 'base-manual_feeding-0'"
    # Merge oil infos into oil_to_input and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oil' AND intervention_parameters.reference_name = 'oil_to_input' AND oi.reference_name = 'base-oil_replacement-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oil' AND i.reference_name = 'base-oil_replacement-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'oil' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'oil_to_input' AND i.reference_name = 'base-oil_replacement-0'"
    # Merge wine infos into wine_to_move and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'wine' AND intervention_parameters.reference_name = 'wine_to_move' AND oi.reference_name = 'base-partial_wine_transfer-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wine' AND i.reference_name = 'base-partial_wine_transfer-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'wine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'wine_to_move' AND i.reference_name = 'base-partial_wine_transfer-0'"
    # Merge silage infos into silage_to_give and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'silage' AND intervention_parameters.reference_name = 'silage_to_give' AND oi.reference_name = 'base-silage_unload-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'silage' AND i.reference_name = 'base-silage_unload-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'silage' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'silage_to_give' AND i.reference_name = 'base-silage_unload-0'"
    # Add group zone for sowing
    execute "INSERT INTO intervention_parameters (intervention_id, type, reference_name, position, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, 'InterventionGroupParameter', 'zone', 999, created_at, creator_id, updated_at, updater_id, lock_version FROM interventions WHERE reference_name = 'base-sowing-0'"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-sowing-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-sowing-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id"
    # Merge seeds infos into seeds_to_sow and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'seeds' AND intervention_parameters.reference_name = 'seeds_to_sow' AND oi.reference_name = 'base-sowing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'seeds' AND i.reference_name = 'base-sowing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'seeds' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'seeds_to_sow' AND i.reference_name = 'base-sowing-0'"
    # Merge stakes infos into stakes_to_plant and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'stakes' AND intervention_parameters.reference_name = 'stakes_to_plant' AND oi.reference_name = 'base-standard_enclosing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'stakes' AND i.reference_name = 'base-standard_enclosing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'stakes' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'stakes_to_plant' AND i.reference_name = 'base-standard_enclosing-0'"
    # Merge wire_fence infos into wire_fence_to_put and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'wire_fence' AND intervention_parameters.reference_name = 'wire_fence_to_put' AND oi.reference_name = 'base-standard_enclosing-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wire_fence' AND i.reference_name = 'base-standard_enclosing-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'wire_fence' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'wire_fence_to_put' AND i.reference_name = 'base-standard_enclosing-0'"
    # Merge oenological_intrant infos into oenological_intrant_to_put and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'oenological_intrant' AND intervention_parameters.reference_name = 'oenological_intrant_to_put' AND oi.reference_name = 'base-sulfur_addition-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'oenological_intrant' AND i.reference_name = 'base-sulfur_addition-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'oenological_intrant' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'oenological_intrant_to_put' AND i.reference_name = 'base-sulfur_addition-0'"
    # Merge wine infos into wine_to_blend and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'wine' AND intervention_parameters.reference_name = 'wine_to_blend' AND oi.reference_name = 'base-wine_blending-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wine' AND i.reference_name = 'base-wine_blending-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'wine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'wine_to_blend' AND i.reference_name = 'base-wine_blending-0'"
    # Merge adding_wine infos into adding_wine_to_blend and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'adding_wine' AND intervention_parameters.reference_name = 'adding_wine_to_blend' AND oi.reference_name = 'base-wine_blending-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'adding_wine' AND i.reference_name = 'base-wine_blending-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'adding_wine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'adding_wine_to_blend' AND i.reference_name = 'base-wine_blending-0'"
    # Merge wine infos into wine_to_pack and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'wine' AND intervention_parameters.reference_name = 'wine_to_pack' AND oi.reference_name = 'base-wine_bottling-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wine' AND i.reference_name = 'base-wine_bottling-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'wine' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'wine_to_pack' AND i.reference_name = 'base-wine_bottling-0'"
    # Merge bottles infos into bottles_to_use and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'bottles' AND intervention_parameters.reference_name = 'bottles_to_use' AND oi.reference_name = 'base-wine_bottling-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'bottles' AND i.reference_name = 'base-wine_bottling-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'bottles' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'bottles_to_use' AND i.reference_name = 'base-wine_bottling-0'"
    # Merge corks infos into corks_to_use and rename it
    execute "UPDATE intervention_parameters SET outcoming_product_id = intervention_parameters.product_id, product_id = origin.product_id FROM interventions AS i, intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id) WHERE origin.reference_name = 'corks' AND intervention_parameters.reference_name = 'corks_to_use' AND oi.reference_name = 'base-wine_bottling-0' AND oi.reference_name = i.reference_name AND i.id = intervention_parameters.intervention_id"
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'corks' AND i.reference_name = 'base-wine_bottling-0')"
    execute "UPDATE intervention_parameters SET reference_name = 'corks' FROM interventions AS i WHERE i.id = intervention_id AND intervention_parameters.reference_name = 'corks_to_use' AND i.reference_name = 'base-wine_bottling-0'"
    # Remove casts wine_storage from wine_bottling interventions
    execute "DELETE FROM intervention_parameters WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id) WHERE c.reference_name = 'wine_storage' AND i.reference_name = 'base-wine_bottling-0')"
    # target
    execute "UPDATE intervention_parameters SET type = 'InterventionTarget' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_parameters.reference_name IN ('mother', 'bird_band', 'land_parcel', 'equipment', 'mammal_to_milk', 'sortable', 'animal_housing', 'wine_to_treat', 'juice_to_ferment', 'tank_for_wine') OR (intervention_parameters.reference_name = 'animal' AND i.reference_name IN ('base-animal_antibiotic_treatment-0', 'base-animal_artificial_insemination-0')) OR (intervention_parameters.reference_name = 'cultivation' AND i.reference_name IN ('base-mechanical_harvesting-0', 'base-spraying-0', 'base-plant_watering-0', 'base-cutting-0', 'base-detasseling-0', 'base-direct_silage-0', 'base-pasturing-0', 'base-plant_mowing-0', 'base-plantation_unfixing-0')) OR (intervention_parameters.reference_name = 'herd' AND i.reference_name IN ('base-animal_group_changing-0', 'base-manual_feeding-0', 'base-silage_unload-0')) OR (intervention_parameters.reference_name = 'wine' AND i.reference_name IN ('base-complete_wine_transfer-0', 'base-partial_wine_transfer-0', 'base-wine_bottling-0')))"
    # input
    execute "UPDATE intervention_parameters SET type = 'InterventionInput' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_parameters.reference_name IN ('animal_medicine', 'plants', 'item', 'fertilizer', 'plastic', 'seeds', 'insecticide', 'molluscicide', 'plant_medicine', 'water', 'vial', 'oenological_intrant', 'fuel', 'grape', 'straw_to_bunch', 'oil', 'stakes', 'wire_fence', 'adding_wine', 'bottles', 'corks') OR (intervention_parameters.reference_name = 'animal' AND i.reference_name = 'base-animal_group_changing-0') OR (intervention_parameters.reference_name = 'straw' AND i.reference_name = 'base-animal_housing_mulching-0') OR (intervention_parameters.reference_name = 'silage' AND i.reference_name IN ('base-manual_feeding-0', 'base-silage_unload-0')) OR (intervention_parameters.reference_name = 'wine' AND i.reference_name IN ('base-wine_blending-0', 'base-wine_bottling-0')))"
    # doer
    execute "UPDATE intervention_parameters SET type = 'InterventionDoer' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_parameters.reference_name IN ('caregiver', 'doer', 'cropper_driver', 'driver', 'implanter_man', 'mechanic', 'inseminator', 'wine_man', 'forager_driver', 'mower_driver', 'baler_driver'))"
    # output
    execute "UPDATE intervention_parameters SET type = 'InterventionOutput' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_parameters.reference_name IN ('child', 'eggs', 'grains', 'straws', 'milk', 'excrement', 'fermented_juice', 'juice', 'residue', 'grass', 'straw_bales', 'wine_blended', 'wine_bottles') OR (intervention_parameters.reference_name = 'cultivation' AND i.reference_name IN ('base-mechanical_planting-0', 'base-sowing_with_spraying-0', 'base-all_in_one_sowing-0', 'base-sowing-0')) OR (intervention_parameters.reference_name = 'silage' AND i.reference_name IN ('base-direct_silage-0', 'base-indirect_silage-0')) OR (intervention_parameters.reference_name = 'straw' AND i.reference_name = 'base-plant_mowing-0'))"
    # tool
    execute "UPDATE intervention_parameters SET type = 'InterventionTool' FROM interventions AS i WHERE i.id = intervention_id AND (intervention_parameters.reference_name IN ('cropper', 'tractor', 'grinder', 'implanter_tool', 'spreader', 'implanter', 'container', 'variant', 'sower', 'sprayer', 'cleaner', 'tank', 'destination_tank', 'cutter', 'forager', 'tank_for_residue', 'press', 'cultivator', 'mower', 'compressor', 'plow', 'harrow', 'silage_unloader', 'baler', 'hand_drawn', 'corker') OR (intervention_parameters.reference_name = 'herd' AND i.reference_name = 'base-pasturing-0'))"
  end
end
