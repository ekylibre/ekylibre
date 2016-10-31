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

  # Radius of big corn plant
  RADIUS = 0.0000097

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
        column = :initial_shape
        execute "INSERT INTO cultivable_zones (name, work_number, shape, uuid, product_id, created_at, creator_id, updated_at, updater_id, lock_version) SELECT name, COALESCE(work_number, id::VARCHAR), ST_Multi(ST_Union(ARRAY[ST_Buffer(ST_CollectionExtract(#{column}, 1), #{RADIUS}), ST_Buffer(ST_CollectionExtract(#{column}, 2), #{RADIUS}), ST_CollectionExtract(#{column}, 3)])), uuid_generate_v4(), id, created_at, creator_id, updated_at, updater_id, lock_version FROM products WHERE type = 'LandParcel'"

        column = :geometry_value
        # ST_Multi(geometry_value)
        execute 'UPDATE cultivable_zones SET shape = ' + "ST_Multi(ST_Union(ARRAY[ST_Buffer(ST_CollectionExtract(#{column}, 1), #{RADIUS}), ST_Buffer(ST_CollectionExtract(#{column}, 2), #{RADIUS}), ST_CollectionExtract(#{column}, 3)]))" + ' FROM product_readings AS pr WHERE pr.product_id = cultivable_zones.product_id AND geometry_value IS NOT NULL AND NOT ST_IsEmpty(geometry_value)'
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
        execute 'DELETE FROM activity_budgets WHERE production_id NOT IN (SELECT id FROM productions)'
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
        # puts select_value('SELECT count(*) FROM intervention_parameter_readings WHERE parameter_id IS NULL').inspect.green
        # Try to find cast with cast as originator
        execute "UPDATE intervention_parameter_readings SET parameter_id = originator_id WHERE parameter_id IS NULL AND intervention_id IS NULL AND originator_type = 'InterventionCast'"
        # puts select_value('SELECT count(*) FROM intervention_parameter_readings WHERE parameter_id IS NULL').inspect.green

        # Try to find cast within casts of same intervention
        execute 'UPDATE intervention_parameter_readings SET parameter_id = c.id FROM intervention_parameters AS c WHERE parameter_id IS NULL AND c.intervention_id = intervention_parameter_readings.intervention_id AND c.actor_id = intervention_parameter_readings.product_id'
        # puts select_value('SELECT count(*) FROM intervention_parameter_readings WHERE parameter_id IS NULL').inspect.green

        # Try to find cast with intervention as originator
        execute "UPDATE intervention_parameter_readings SET parameter_id = c.id FROM intervention_parameters AS c WHERE parameter_id IS NULL AND c.intervention_id = intervention_parameter_readings.originator_id AND intervention_parameter_readings.originator_type = 'Intervention' AND c.actor_id = intervention_parameter_readings.product_id"
        # puts select_value('SELECT count(*) FROM intervention_parameter_readings WHERE parameter_id IS NULL').inspect.green

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

    MULTI_POLYGON_COLUMNS.each do |table, columns|
      columns.each do |column|
        reversible do |dir|
          dir.up do
            # Transform Points and Linestrings to Polygons with ST_Buffer function
            execute "UPDATE #{table} SET #{column} = ST_Multi(ST_Union(ARRAY[ST_Buffer(ST_CollectionExtract(#{column}, 1), #{RADIUS}), ST_Buffer(ST_CollectionExtract(#{column}, 2), #{RADIUS}), ST_CollectionExtract(#{column}, 3)]))"
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
    # Constants
    execute "UPDATE intervention_parameters SET type = 'Trash'"
    execute "UPDATE intervention_parameters SET type = 'InterventionTarget' FROM interventions AS i WHERE i.id = intervention_id AND ((i.reference_name = 'base-all_in_one_sowing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-animal_artificial_insemination-0' AND intervention_parameters.reference_name IN ('animal')) OR (i.reference_name = 'base-animal_group_changing-0' AND intervention_parameters.reference_name IN ('herd')) OR (i.reference_name = 'base-animal_housing_cleaning-0' AND intervention_parameters.reference_name IN ('animal_housing')) OR (i.reference_name = 'base-animal_housing_mulching-0' AND intervention_parameters.reference_name IN ('animal_housing')) OR (i.reference_name = 'base-animal_treatment-0' AND intervention_parameters.reference_name IN ('animal')) OR (i.reference_name = 'base-calving_one-0' AND intervention_parameters.reference_name IN ('mother')) OR (i.reference_name = 'base-calving_twin-0' AND intervention_parameters.reference_name IN ('mother')) OR (i.reference_name = 'base-chaptalization-0' AND intervention_parameters.reference_name IN ('wine_to_treat')) OR (i.reference_name = 'base-chemical_weed_killing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-complete_wine_transfer-0' AND intervention_parameters.reference_name IN ('wine')) OR (i.reference_name = 'base-cutting-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-detasseling-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-direct_silage-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-double_spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-egg_production-0' AND intervention_parameters.reference_name IN ('bird_band')) OR (i.reference_name = 'base-enzyme_addition-0' AND intervention_parameters.reference_name IN ('wine_to_treat')) OR (i.reference_name = 'base-fermentation-0' AND intervention_parameters.reference_name IN ('juice_to_ferment')) OR (i.reference_name = 'base-filling-0' AND intervention_parameters.reference_name IN ('tank')) OR (i.reference_name = 'base-fuel_up-0' AND intervention_parameters.reference_name IN ('equipment')) OR (i.reference_name = 'base-grain_transport-0' AND intervention_parameters.reference_name IN ('grain_to_deliver')) OR (i.reference_name = 'base-grains_harvest-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-grape_pressing-0' AND intervention_parameters.reference_name IN ('tank_for_wine')) OR (i.reference_name = 'base-grape_transport-0' AND intervention_parameters.reference_name IN ('grape_to_deliver')) OR (i.reference_name = 'base-grinding-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-ground_destratification-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-group_exclusion-0' AND intervention_parameters.reference_name IN ('member')) OR (i.reference_name = 'base-group_inclusion-0' AND intervention_parameters.reference_name IN ('member')) OR (i.reference_name = 'base-harvest_helping-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-hazelnuts_harvest-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-hazelnuts_transport-0' AND intervention_parameters.reference_name IN ('nuts_to_deliver')) OR (i.reference_name = 'base-hoeing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-implant_helping-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-implanting-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-item_replacement-0' AND intervention_parameters.reference_name IN ('equipment')) OR (i.reference_name = 'base-land_parcel_grinding-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-maintenance_task-0' AND intervention_parameters.reference_name IN ('maintained')) OR (i.reference_name = 'base-mammal_herd_milking-0' AND intervention_parameters.reference_name IN ('mammal_herd_to_milk')) OR (i.reference_name = 'base-mammal_milking-0' AND intervention_parameters.reference_name IN ('mammal_to_milk')) OR (i.reference_name = 'base-manual_feeding-0' AND intervention_parameters.reference_name IN ('herd')) OR (i.reference_name = 'base-mineral_fertilizing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-oil_replacement-0' AND intervention_parameters.reference_name IN ('equipment')) OR (i.reference_name = 'base-organic_fertilizing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-partial_wine_transfer-0' AND intervention_parameters.reference_name IN ('wine_to_move')) OR (i.reference_name = 'base-pasturing-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-plant_grinding-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-plant_mowing-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-plantation_unfixing-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-plants_harvest-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-plastic_mulching-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-plowing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-plums_harvest-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-product_evolution-0' AND intervention_parameters.reference_name IN ('product')) OR (i.reference_name = 'base-product_moving-0' AND intervention_parameters.reference_name IN ('product')) OR (i.reference_name = 'base-raking-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-silage_transport-0' AND intervention_parameters.reference_name IN ('silage_to_deliver')) OR (i.reference_name = 'base-silage_unload-0' AND intervention_parameters.reference_name IN ('herd')) OR (i.reference_name = 'base-sorting-0' AND intervention_parameters.reference_name IN ('sortable_to_sort')) OR (i.reference_name = 'base-sowing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-spraying_on_land_parcel-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-standard_enclosing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-straw_transport-0' AND intervention_parameters.reference_name IN ('straw_to_deliver')) OR (i.reference_name = 'base-sulfur_addition-0' AND intervention_parameters.reference_name IN ('wine_to_treat')) OR (i.reference_name = 'base-superficial_plowing-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-technical_task-0' AND intervention_parameters.reference_name IN ('target')) OR (i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-uncompacting-0' AND intervention_parameters.reference_name IN ('land_parcel')) OR (i.reference_name = 'base-vine_harvest-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-walnuts_harvest-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-walnuts_transport-0' AND intervention_parameters.reference_name IN ('nuts_to_deliver')) OR (i.reference_name = 'base-watering-0' AND intervention_parameters.reference_name IN ('land_parcel', 'cultivation')) OR (i.reference_name = 'base-wine_bottling-0' AND intervention_parameters.reference_name IN ('wine')))"
    execute "UPDATE intervention_parameters SET type = 'InterventionInput' FROM interventions AS i WHERE i.id = intervention_id AND ((i.reference_name = 'base-all_in_one_sowing-0' AND intervention_parameters.reference_name IN ('seeds_to_sow', 'fertilizer_to_spread', 'insecticide_to_input', 'molluscicide_to_input')) OR (i.reference_name = 'base-animal_artificial_insemination-0' AND intervention_parameters.reference_name IN ('vial_to_give')) OR (i.reference_name = 'base-animal_group_changing-0' AND intervention_parameters.reference_name IN ('animal')) OR (i.reference_name = 'base-animal_housing_mulching-0' AND intervention_parameters.reference_name IN ('straw_to_mulch')) OR (i.reference_name = 'base-animal_treatment-0' AND intervention_parameters.reference_name IN ('animal_medicine_to_give')) OR (i.reference_name = 'base-chaptalization-0' AND intervention_parameters.reference_name IN ('oenological_intrant_to_put')) OR (i.reference_name = 'base-chemical_weed_killing-0' AND intervention_parameters.reference_name IN ('weedkiller_to_spray')) OR (i.reference_name = 'base-double_chemical_mixing-0' AND intervention_parameters.reference_name IN ('first_chemical_input', 'first_chemical_input_to_use', 'second_chemical_input', 'second_chemical_input_to_use')) OR (i.reference_name = 'base-double_food_mixing-0' AND intervention_parameters.reference_name IN ('first_food_input', 'first_food_input_to_use', 'second_food_input', 'second_food_input_to_use')) OR (i.reference_name = 'base-double_seed_mixing-0' AND intervention_parameters.reference_name IN ('first_seed_input', 'first_seed_input_to_use', 'second_seed_input', 'second_seed_input_to_use')) OR (i.reference_name = 'base-double_spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('first_plant_medicine_to_spray', 'second_plant_medicine_to_spray')) OR (i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name IN ('first_plant_medicine_to_spray', 'second_plant_medicine_to_spray')) OR (i.reference_name = 'base-enzyme_addition-0' AND intervention_parameters.reference_name IN ('oenological_intrant_to_put')) OR (i.reference_name = 'base-fermentation-0' AND intervention_parameters.reference_name IN ('oenological_intrant_to_put')) OR (i.reference_name = 'base-filling-0' AND intervention_parameters.reference_name IN ('items_to_fill')) OR (i.reference_name = 'base-fuel_up-0' AND intervention_parameters.reference_name IN ('fuel', 'fuel_to_input')) OR (i.reference_name = 'base-grape_pressing-0' AND intervention_parameters.reference_name IN ('grape_to_press')) OR (i.reference_name = 'base-implanting-0' AND intervention_parameters.reference_name IN ('plants_to_fix')) OR (i.reference_name = 'base-indirect_silage-0' AND intervention_parameters.reference_name IN ('straw_to_bunch')) OR (i.reference_name = 'base-item_replacement-0' AND intervention_parameters.reference_name IN ('item', 'item_to_change')) OR (i.reference_name = 'base-manual_feeding-0' AND intervention_parameters.reference_name IN ('silage_to_give')) OR (i.reference_name = 'base-mineral_fertilizing-0' AND intervention_parameters.reference_name IN ('fertilizer_to_spread')) OR (i.reference_name = 'base-oil_replacement-0' AND intervention_parameters.reference_name IN ('oil', 'oil_to_input')) OR (i.reference_name = 'base-organic_fertilizing-0' AND intervention_parameters.reference_name IN ('manure_to_spread')) OR (i.reference_name = 'base-plant_grinding-0' AND intervention_parameters.reference_name IN ('grinded')) OR (i.reference_name = 'base-plastic_mulching-0' AND intervention_parameters.reference_name IN ('plastic_to_mulch')) OR (i.reference_name = 'base-silage_unload-0' AND intervention_parameters.reference_name IN ('silage_to_give')) OR (i.reference_name = 'base-sowing-0' AND intervention_parameters.reference_name IN ('seeds_to_sow')) OR (i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0' AND intervention_parameters.reference_name IN ('seeds_to_sow', 'insecticide_to_input', 'molluscicide_to_input')) OR (i.reference_name = 'base-spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('plant_medicine_to_spray')) OR (i.reference_name = 'base-spraying_on_land_parcel-0' AND intervention_parameters.reference_name IN ('plant_medicine_to_spray')) OR (i.reference_name = 'base-standard_enclosing-0' AND intervention_parameters.reference_name IN ('stakes_to_plant', 'wire_fence_to_put')) OR (i.reference_name = 'base-straw_bunching-0' AND intervention_parameters.reference_name IN ('straw_to_bunch')) OR (i.reference_name = 'base-sulfur_addition-0' AND intervention_parameters.reference_name IN ('oenological_intrant_to_put')) OR (i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name IN ('first_food_input', 'first_food_input_to_use', 'second_food_input', 'second_food_input_to_use', 'third_food_input', 'third_food_input_to_use')) OR (i.reference_name = 'base-triple_seed_mixing-0' AND intervention_parameters.reference_name IN ('first_seed_input', 'first_seed_input_to_use', 'second_seed_input', 'second_seed_input_to_use', 'third_seed_input', 'third_seed_input_to_use')) OR (i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('first_plant_medicine_to_spray', 'second_plant_medicine_to_spray', 'third_plant_medicine_to_spray')) OR (i.reference_name = 'base-watering-0' AND intervention_parameters.reference_name IN ('water_to_spread')) OR (i.reference_name = 'base-wine_blending-0' AND intervention_parameters.reference_name IN ('wine_to_blend', 'adding_wine_to_blend')) OR (i.reference_name = 'base-wine_bottling-0' AND intervention_parameters.reference_name IN ('wine_to_pack', 'bottles_to_use', 'corks_to_use')))"
    execute "UPDATE intervention_parameters SET type = 'InterventionOutput' FROM interventions AS i WHERE i.id = intervention_id AND ((i.reference_name = 'base-all_in_one_sowing-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-animal_housing_cleaning-0' AND intervention_parameters.reference_name IN ('excrement')) OR (i.reference_name = 'base-calving_one-0' AND intervention_parameters.reference_name IN ('child')) OR (i.reference_name = 'base-calving_twin-0' AND intervention_parameters.reference_name IN ('first_child', 'second_child')) OR (i.reference_name = 'base-direct_silage-0' AND intervention_parameters.reference_name IN ('silage')) OR (i.reference_name = 'base-double_chemical_mixing-0' AND intervention_parameters.reference_name IN ('chemical_mix')) OR (i.reference_name = 'base-double_food_mixing-0' AND intervention_parameters.reference_name IN ('food_mix')) OR (i.reference_name = 'base-double_seed_mixing-0' AND intervention_parameters.reference_name IN ('seed_mix')) OR (i.reference_name = 'base-egg_production-0' AND intervention_parameters.reference_name IN ('eggs')) OR (i.reference_name = 'base-fermentation-0' AND intervention_parameters.reference_name IN ('fermented_juice')) OR (i.reference_name = 'base-grains_harvest-0' AND intervention_parameters.reference_name IN ('grains', 'straws')) OR (i.reference_name = 'base-grape_pressing-0' AND intervention_parameters.reference_name IN ('juice', 'residue')) OR (i.reference_name = 'base-hazelnuts_harvest-0' AND intervention_parameters.reference_name IN ('hazelnuts')) OR (i.reference_name = 'base-implanting-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-indirect_silage-0' AND intervention_parameters.reference_name IN ('silage')) OR (i.reference_name = 'base-mammal_herd_milking-0' AND intervention_parameters.reference_name IN ('milk')) OR (i.reference_name = 'base-mammal_milking-0' AND intervention_parameters.reference_name IN ('milk')) OR (i.reference_name = 'base-pasturing-0' AND intervention_parameters.reference_name IN ('grass')) OR (i.reference_name = 'base-plant_mowing-0' AND intervention_parameters.reference_name IN ('straw')) OR (i.reference_name = 'base-plants_harvest-0' AND intervention_parameters.reference_name IN ('plants')) OR (i.reference_name = 'base-plums_harvest-0' AND intervention_parameters.reference_name IN ('fruits')) OR (i.reference_name = 'base-sowing-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0' AND intervention_parameters.reference_name IN ('cultivation')) OR (i.reference_name = 'base-straw_bunching-0' AND intervention_parameters.reference_name IN ('straw_bales')) OR (i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name IN ('food_mix')) OR (i.reference_name = 'base-triple_seed_mixing-0' AND intervention_parameters.reference_name IN ('seed_mix')) OR (i.reference_name = 'base-vine_harvest-0' AND intervention_parameters.reference_name IN ('fruits')) OR (i.reference_name = 'base-walnuts_harvest-0' AND intervention_parameters.reference_name IN ('walnuts')) OR (i.reference_name = 'base-wine_blending-0' AND intervention_parameters.reference_name IN ('wine_blended')) OR (i.reference_name = 'base-wine_bottling-0' AND intervention_parameters.reference_name IN ('wine_bottles')))"
    execute "UPDATE intervention_parameters SET type = 'InterventionTool' FROM interventions AS i WHERE i.id = intervention_id AND ((i.reference_name = 'base-all_in_one_sowing-0' AND intervention_parameters.reference_name IN ('sower', 'tractor')) OR (i.reference_name = 'base-animal_housing_cleaning-0' AND intervention_parameters.reference_name IN ('cleaner', 'tractor')) OR (i.reference_name = 'base-animal_housing_mulching-0' AND intervention_parameters.reference_name IN ('cleaner', 'tractor')) OR (i.reference_name = 'base-attach-0' AND intervention_parameters.reference_name IN ('tractor', 'tool')) OR (i.reference_name = 'base-chaptalization-0' AND intervention_parameters.reference_name IN ('tank')) OR (i.reference_name = 'base-chemical_weed_killing-0' AND intervention_parameters.reference_name IN ('tractor', 'sprayer')) OR (i.reference_name = 'base-complete_wine_transfer-0' AND intervention_parameters.reference_name IN ('tank', 'destination_tank')) OR (i.reference_name = 'base-cutting-0' AND intervention_parameters.reference_name IN ('tractor', 'cutter')) OR (i.reference_name = 'base-detach-0' AND intervention_parameters.reference_name IN ('tractor', 'tool')) OR (i.reference_name = 'base-direct_silage-0' AND intervention_parameters.reference_name IN ('forager')) OR (i.reference_name = 'base-double_spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('tractor', 'sprayer')) OR (i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name IN ('tractor', 'sprayer')) OR (i.reference_name = 'base-enzyme_addition-0' AND intervention_parameters.reference_name IN ('tank')) OR (i.reference_name = 'base-fermentation-0' AND intervention_parameters.reference_name IN ('tank')) OR (i.reference_name = 'base-grain_transport-0' AND intervention_parameters.reference_name IN ('trailer', 'tractor', 'silo')) OR (i.reference_name = 'base-grains_harvest-0' AND intervention_parameters.reference_name IN ('cropper')) OR (i.reference_name = 'base-grape_pressing-0' AND intervention_parameters.reference_name IN ('tank_for_residue', 'press')) OR (i.reference_name = 'base-grape_transport-0' AND intervention_parameters.reference_name IN ('trailer', 'tractor', 'silo')) OR (i.reference_name = 'base-grinding-0' AND intervention_parameters.reference_name IN ('tractor', 'grinder')) OR (i.reference_name = 'base-ground_destratification-0' AND intervention_parameters.reference_name IN ('tractor')) OR (i.reference_name = 'base-group_exclusion-0' AND intervention_parameters.reference_name IN ('group')) OR (i.reference_name = 'base-group_inclusion-0' AND intervention_parameters.reference_name IN ('group')) OR (i.reference_name = 'base-hazelnuts_harvest-0' AND intervention_parameters.reference_name IN ('nuts_harvester')) OR (i.reference_name = 'base-hazelnuts_transport-0' AND intervention_parameters.reference_name IN ('trailer', 'tractor', 'silo')) OR (i.reference_name = 'base-hoeing-0' AND intervention_parameters.reference_name IN ('tractor', 'cultivator')) OR (i.reference_name = 'base-implanting-0' AND intervention_parameters.reference_name IN ('implanter_tool', 'tractor')) OR (i.reference_name = 'base-indirect_silage-0' AND intervention_parameters.reference_name IN ('forager')) OR (i.reference_name = 'base-land_parcel_grinding-0' AND intervention_parameters.reference_name IN ('tractor', 'grinder')) OR (i.reference_name = 'base-mineral_fertilizing-0' AND intervention_parameters.reference_name IN ('spreader', 'tractor')) OR (i.reference_name = 'base-organic_fertilizing-0' AND intervention_parameters.reference_name IN ('spreader', 'tractor')) OR (i.reference_name = 'base-partial_wine_transfer-0' AND intervention_parameters.reference_name IN ('tank', 'destination_tank')) OR (i.reference_name = 'base-pasturing-0' AND intervention_parameters.reference_name IN ('herd')) OR (i.reference_name = 'base-plant_grinding-0' AND intervention_parameters.reference_name IN ('tractor', 'grinder')) OR (i.reference_name = 'base-plant_mowing-0' AND intervention_parameters.reference_name IN ('tractor', 'mower')) OR (i.reference_name = 'base-plantation_unfixing-0' AND intervention_parameters.reference_name IN ('tractor', 'compressor')) OR (i.reference_name = 'base-plants_harvest-0' AND intervention_parameters.reference_name IN ('cropper')) OR (i.reference_name = 'base-plastic_mulching-0' AND intervention_parameters.reference_name IN ('implanter', 'tractor')) OR (i.reference_name = 'base-plowing-0' AND intervention_parameters.reference_name IN ('tractor', 'plow')) OR (i.reference_name = 'base-plums_harvest-0' AND intervention_parameters.reference_name IN ('tractor', 'fruit_harvester')) OR (i.reference_name = 'base-product_evolution-0' AND intervention_parameters.reference_name IN ('variant')) OR (i.reference_name = 'base-product_moving-0' AND intervention_parameters.reference_name IN ('container')) OR (i.reference_name = 'base-raking-0' AND intervention_parameters.reference_name IN ('tractor', 'harrow')) OR (i.reference_name = 'base-silage_transport-0' AND intervention_parameters.reference_name IN ('trailer', 'tractor', 'silo')) OR (i.reference_name = 'base-silage_unload-0' AND intervention_parameters.reference_name IN ('tractor', 'silage_unloader')) OR (i.reference_name = 'base-sorting-0' AND intervention_parameters.reference_name IN ('container', 'variant')) OR (i.reference_name = 'base-sowing-0' AND intervention_parameters.reference_name IN ('sower', 'tractor')) OR (i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0' AND intervention_parameters.reference_name IN ('sower', 'tractor')) OR (i.reference_name = 'base-spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('tractor', 'sprayer')) OR (i.reference_name = 'base-spraying_on_land_parcel-0' AND intervention_parameters.reference_name IN ('tractor', 'sprayer')) OR (i.reference_name = 'base-straw_bunching-0' AND intervention_parameters.reference_name IN ('tractor', 'baler')) OR (i.reference_name = 'base-straw_transport-0' AND intervention_parameters.reference_name IN ('trailer', 'tractor', 'silo')) OR (i.reference_name = 'base-sulfur_addition-0' AND intervention_parameters.reference_name IN ('tank')) OR (i.reference_name = 'base-superficial_plowing-0' AND intervention_parameters.reference_name IN ('tractor', 'plow')) OR (i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('tractor', 'sprayer')) OR (i.reference_name = 'base-uncompacting-0' AND intervention_parameters.reference_name IN ('tractor', 'harrow')) OR (i.reference_name = 'base-vine_harvest-0' AND intervention_parameters.reference_name IN ('grape_reaper')) OR (i.reference_name = 'base-walnuts_harvest-0' AND intervention_parameters.reference_name IN ('nuts_harvester')) OR (i.reference_name = 'base-walnuts_transport-0' AND intervention_parameters.reference_name IN ('trailer', 'tractor', 'silo')) OR (i.reference_name = 'base-watering-0' AND intervention_parameters.reference_name IN ('spreader')) OR (i.reference_name = 'base-wine_blending-0' AND intervention_parameters.reference_name IN ('tank')) OR (i.reference_name = 'base-wine_bottling-0' AND intervention_parameters.reference_name IN ('tank', 'hand_drawn', 'corker')))"
    execute "UPDATE intervention_parameters SET type = 'InterventionDoer' FROM interventions AS i WHERE i.id = intervention_id AND ((i.reference_name = 'base-administrative_task-0' AND intervention_parameters.reference_name IN ('worker')) OR (i.reference_name = 'base-all_in_one_sowing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-animal_artificial_insemination-0' AND intervention_parameters.reference_name IN ('inseminator')) OR (i.reference_name = 'base-animal_housing_cleaning-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-animal_housing_mulching-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-animal_treatment-0' AND intervention_parameters.reference_name IN ('caregiver')) OR (i.reference_name = 'base-attach-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-calving_one-0' AND intervention_parameters.reference_name IN ('caregiver')) OR (i.reference_name = 'base-calving_twin-0' AND intervention_parameters.reference_name IN ('caregiver')) OR (i.reference_name = 'base-chaptalization-0' AND intervention_parameters.reference_name IN ('wine_man')) OR (i.reference_name = 'base-chemical_weed_killing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-complete_wine_transfer-0' AND intervention_parameters.reference_name IN ('wine_man')) OR (i.reference_name = 'base-cutting-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-detach-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-detasseling-0' AND intervention_parameters.reference_name IN ('doer')) OR (i.reference_name = 'base-direct_silage-0' AND intervention_parameters.reference_name IN ('forager_driver')) OR (i.reference_name = 'base-double_chemical_mixing-0' AND intervention_parameters.reference_name IN ('worker')) OR (i.reference_name = 'base-double_food_mixing-0' AND intervention_parameters.reference_name IN ('worker')) OR (i.reference_name = 'base-double_seed_mixing-0' AND intervention_parameters.reference_name IN ('worker')) OR (i.reference_name = 'base-double_spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-egg_production-0' AND intervention_parameters.reference_name IN ('doer')) OR (i.reference_name = 'base-enzyme_addition-0' AND intervention_parameters.reference_name IN ('wine_man')) OR (i.reference_name = 'base-fermentation-0' AND intervention_parameters.reference_name IN ('wine_man')) OR (i.reference_name = 'base-filling-0' AND intervention_parameters.reference_name IN ('doer')) OR (i.reference_name = 'base-fuel_up-0' AND intervention_parameters.reference_name IN ('mechanic')) OR (i.reference_name = 'base-grain_transport-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-grains_harvest-0' AND intervention_parameters.reference_name IN ('cropper_driver')) OR (i.reference_name = 'base-grape_pressing-0' AND intervention_parameters.reference_name IN ('wine_man')) OR (i.reference_name = 'base-grape_transport-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-grinding-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-ground_destratification-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-harvest_helping-0' AND intervention_parameters.reference_name IN ('harvester_man')) OR (i.reference_name = 'base-hazelnuts_harvest-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-hazelnuts_transport-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-hoeing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-implant_helping-0' AND intervention_parameters.reference_name IN ('implanter_man')) OR (i.reference_name = 'base-implanting-0' AND intervention_parameters.reference_name IN ('driver', 'implanter_man')) OR (i.reference_name = 'base-indirect_silage-0' AND intervention_parameters.reference_name IN ('forager_driver')) OR (i.reference_name = 'base-item_replacement-0' AND intervention_parameters.reference_name IN ('mechanic')) OR (i.reference_name = 'base-land_parcel_grinding-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-maintenance_task-0' AND intervention_parameters.reference_name IN ('worker')) OR (i.reference_name = 'base-mammal_herd_milking-0' AND intervention_parameters.reference_name IN ('caregiver')) OR (i.reference_name = 'base-mammal_milking-0' AND intervention_parameters.reference_name IN ('caregiver')) OR (i.reference_name = 'base-manual_feeding-0' AND intervention_parameters.reference_name IN ('caregiver')) OR (i.reference_name = 'base-mineral_fertilizing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-oil_replacement-0' AND intervention_parameters.reference_name IN ('mechanic')) OR (i.reference_name = 'base-organic_fertilizing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-partial_wine_transfer-0' AND intervention_parameters.reference_name IN ('wine_man')) OR (i.reference_name = 'base-plant_grinding-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-plant_mowing-0' AND intervention_parameters.reference_name IN ('mower_driver')) OR (i.reference_name = 'base-plantation_unfixing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-plants_harvest-0' AND intervention_parameters.reference_name IN ('cropper_driver')) OR (i.reference_name = 'base-plastic_mulching-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-plowing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-plums_harvest-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-product_moving-0' AND intervention_parameters.reference_name IN ('doer')) OR (i.reference_name = 'base-raking-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-silage_transport-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-silage_unload-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-sorting-0' AND intervention_parameters.reference_name IN ('doer')) OR (i.reference_name = 'base-sowing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-spraying_on_land_parcel-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-standard_enclosing-0' AND intervention_parameters.reference_name IN ('doer')) OR (i.reference_name = 'base-straw_bunching-0' AND intervention_parameters.reference_name IN ('baler_driver')) OR (i.reference_name = 'base-straw_transport-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-sulfur_addition-0' AND intervention_parameters.reference_name IN ('wine_man')) OR (i.reference_name = 'base-superficial_plowing-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-technical_task-0' AND intervention_parameters.reference_name IN ('worker')) OR (i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name IN ('worker')) OR (i.reference_name = 'base-triple_seed_mixing-0' AND intervention_parameters.reference_name IN ('worker')) OR (i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-uncompacting-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-vine_harvest-0' AND intervention_parameters.reference_name IN ('grape_reaper_driver')) OR (i.reference_name = 'base-walnuts_harvest-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-walnuts_transport-0' AND intervention_parameters.reference_name IN ('driver')) OR (i.reference_name = 'base-wine_blending-0' AND intervention_parameters.reference_name IN ('wine_man')) OR (i.reference_name = 'base-wine_bottling-0' AND intervention_parameters.reference_name IN ('wine_man')))"
    execute <<SQL
      UPDATE intervention_parameters
      SET outcoming_product_id = intervention_parameters.product_id,
        product_id = origin.product_id, quantity_handler = 'population', quantity_value = intervention_parameters.quantity_population
      FROM interventions AS i,
        intervention_parameters AS origin JOIN interventions AS oi ON (oi.id = origin.intervention_id)
      WHERE oi.id = i.id AND i.id = intervention_parameters.intervention_id AND (
           (oi.reference_name = 'base-all_in_one_sowing-0'                               AND origin.reference_name = 'seeds'                    AND intervention_parameters.reference_name = 'seeds_to_sow')
        OR (oi.reference_name = 'base-all_in_one_sowing-0'                               AND origin.reference_name = 'fertilizer'               AND intervention_parameters.reference_name = 'fertilizer_to_spread')
        OR (oi.reference_name = 'base-all_in_one_sowing-0'                               AND origin.reference_name = 'insecticide'              AND intervention_parameters.reference_name = 'insecticide_to_input')
        OR (oi.reference_name = 'base-all_in_one_sowing-0'                               AND origin.reference_name = 'molluscicide'             AND intervention_parameters.reference_name = 'molluscicide_to_input')
        OR (oi.reference_name = 'base-animal_artificial_insemination-0'                  AND origin.reference_name = 'vial'                     AND intervention_parameters.reference_name = 'vial_to_give')
        OR (oi.reference_name = 'base-animal_housing_mulching-0'                         AND origin.reference_name = 'straw'                    AND intervention_parameters.reference_name = 'straw_to_mulch')
        OR (oi.reference_name = 'base-animal_treatment-0'                                AND origin.reference_name = 'animal_medicine'          AND intervention_parameters.reference_name = 'animal_medicine_to_give')
        OR (oi.reference_name = 'base-chaptalization-0'                                  AND origin.reference_name = 'oenological_intrant'      AND intervention_parameters.reference_name = 'oenological_intrant_to_put')
        OR (oi.reference_name = 'base-chemical_weed_killing-0'                           AND origin.reference_name = 'weedkiller'               AND intervention_parameters.reference_name = 'weedkiller_to_spray')
        OR (oi.reference_name = 'base-double_chemical_mixing-0'                          AND origin.reference_name = 'first_chemical_input'     AND intervention_parameters.reference_name = 'first_chemical_input_to_use')
        OR (oi.reference_name = 'base-double_chemical_mixing-0'                          AND origin.reference_name = 'second_chemical_input'    AND intervention_parameters.reference_name = 'second_chemical_input_to_use')
        OR (oi.reference_name = 'base-double_food_mixing-0'                              AND origin.reference_name = 'first_food_input'         AND intervention_parameters.reference_name = 'first_food_input_to_use')
        OR (oi.reference_name = 'base-double_food_mixing-0'                              AND origin.reference_name = 'second_food_input'        AND intervention_parameters.reference_name = 'second_food_input_to_use')
        OR (oi.reference_name = 'base-double_seed_mixing-0'                              AND origin.reference_name = 'first_seed_input'         AND intervention_parameters.reference_name = 'first_seed_input_to_use')
        OR (oi.reference_name = 'base-double_seed_mixing-0'                              AND origin.reference_name = 'second_seed_input'        AND intervention_parameters.reference_name = 'second_seed_input_to_use')
        OR (oi.reference_name = 'base-double_spraying_on_cultivation-0'                  AND origin.reference_name = 'first_plant_medicine'     AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray')
        OR (oi.reference_name = 'base-double_spraying_on_cultivation-0'                  AND origin.reference_name = 'second_plant_medicine'    AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray')
        OR (oi.reference_name = 'base-double_spraying_on_land_parcel-0'                  AND origin.reference_name = 'first_plant_medicine'     AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray')
        OR (oi.reference_name = 'base-double_spraying_on_land_parcel-0'                  AND origin.reference_name = 'second_plant_medicine'    AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray')
        OR (oi.reference_name = 'base-enzyme_addition-0'                                 AND origin.reference_name = 'oenological_intrant'      AND intervention_parameters.reference_name = 'oenological_intrant_to_put')
        OR (oi.reference_name = 'base-fermentation-0'                                    AND origin.reference_name = 'oenological_intrant'      AND intervention_parameters.reference_name = 'oenological_intrant_to_put')
        OR (oi.reference_name = 'base-filling-0'                                         AND origin.reference_name = 'items'                    AND intervention_parameters.reference_name = 'items_to_fill')
        OR (oi.reference_name = 'base-fuel_up-0'                                         AND origin.reference_name = 'fuel'                     AND intervention_parameters.reference_name = 'fuel_to_input')
        OR (oi.reference_name = 'base-grain_transport-0'                                 AND origin.reference_name = 'grain'                    AND intervention_parameters.reference_name = 'grain_to_deliver')
        OR (oi.reference_name = 'base-grape_pressing-0'                                  AND origin.reference_name = 'grape'                    AND intervention_parameters.reference_name = 'grape_to_press')
        OR (oi.reference_name = 'base-grape_transport-0'                                 AND origin.reference_name = 'grape'                    AND intervention_parameters.reference_name = 'grape_to_deliver')
        OR (oi.reference_name = 'base-hazelnuts_transport-0'                             AND origin.reference_name = 'nuts'                     AND intervention_parameters.reference_name = 'nuts_to_deliver')
        OR (oi.reference_name = 'base-implanting-0'                                      AND origin.reference_name = 'plants'                   AND intervention_parameters.reference_name = 'plants_to_fix')
        OR (oi.reference_name = 'base-item_replacement-0'                                AND origin.reference_name = 'item'                     AND intervention_parameters.reference_name = 'item_to_change')
        OR (oi.reference_name = 'base-manual_feeding-0'                                  AND origin.reference_name = 'silage'                   AND intervention_parameters.reference_name = 'silage_to_give')
        OR (oi.reference_name = 'base-mineral_fertilizing-0'                             AND origin.reference_name = 'fertilizer'               AND intervention_parameters.reference_name = 'fertilizer_to_spread')
        OR (oi.reference_name = 'base-oil_replacement-0'                                 AND origin.reference_name = 'oil'                      AND intervention_parameters.reference_name = 'oil_to_input')
        OR (oi.reference_name = 'base-organic_fertilizing-0'                             AND origin.reference_name = 'manure'                   AND intervention_parameters.reference_name = 'manure_to_spread')
        OR (oi.reference_name = 'base-partial_wine_transfer-0'                           AND origin.reference_name = 'wine'                     AND intervention_parameters.reference_name = 'wine_to_move')
        OR (oi.reference_name = 'base-plastic_mulching-0'                                AND origin.reference_name = 'plastic'                  AND intervention_parameters.reference_name = 'plastic_to_mulch')
        OR (oi.reference_name = 'base-silage_transport-0'                                AND origin.reference_name = 'silage'                   AND intervention_parameters.reference_name = 'silage_to_deliver')
        OR (oi.reference_name = 'base-silage_unload-0'                                   AND origin.reference_name = 'silage'                   AND intervention_parameters.reference_name = 'silage_to_give')
        OR (oi.reference_name = 'base-sorting-0'                                         AND origin.reference_name = 'sortable'                 AND intervention_parameters.reference_name = 'sortable_to_sort')
        OR (oi.reference_name = 'base-sowing-0'                                          AND origin.reference_name = 'seeds'                    AND intervention_parameters.reference_name = 'seeds_to_sow')
        OR (oi.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'        AND origin.reference_name = 'seeds'                    AND intervention_parameters.reference_name = 'seeds_to_sow')
        OR (oi.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'        AND origin.reference_name = 'insecticide'              AND intervention_parameters.reference_name = 'insecticide_to_input')
        OR (oi.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'        AND origin.reference_name = 'molluscicide'             AND intervention_parameters.reference_name = 'molluscicide_to_input')
        OR (oi.reference_name = 'base-spraying_on_cultivation-0'                         AND origin.reference_name = 'plant_medicine'           AND intervention_parameters.reference_name = 'plant_medicine_to_spray')
        OR (oi.reference_name = 'base-spraying_on_land_parcel-0'                         AND origin.reference_name = 'plant_medicine'           AND intervention_parameters.reference_name = 'plant_medicine_to_spray')
        OR (oi.reference_name = 'base-standard_enclosing-0'                              AND origin.reference_name = 'stakes'                   AND intervention_parameters.reference_name = 'stakes_to_plant')
        OR (oi.reference_name = 'base-standard_enclosing-0'                              AND origin.reference_name = 'wire_fence'               AND intervention_parameters.reference_name = 'wire_fence_to_put')
        OR (oi.reference_name = 'base-straw_transport-0'                                 AND origin.reference_name = 'straw'                    AND intervention_parameters.reference_name = 'straw_to_deliver')
        OR (oi.reference_name = 'base-sulfur_addition-0'                                 AND origin.reference_name = 'oenological_intrant'      AND intervention_parameters.reference_name = 'oenological_intrant_to_put')
        OR (oi.reference_name = 'base-triple_food_mixing-0'                              AND origin.reference_name = 'first_food_input'         AND intervention_parameters.reference_name = 'first_food_input_to_use')
        OR (oi.reference_name = 'base-triple_food_mixing-0'                              AND origin.reference_name = 'second_food_input'        AND intervention_parameters.reference_name = 'second_food_input_to_use')
        OR (oi.reference_name = 'base-triple_food_mixing-0'                              AND origin.reference_name = 'third_food_input'         AND intervention_parameters.reference_name = 'third_food_input_to_use')
        OR (oi.reference_name = 'base-triple_seed_mixing-0'                              AND origin.reference_name = 'first_seed_input'         AND intervention_parameters.reference_name = 'first_seed_input_to_use')
        OR (oi.reference_name = 'base-triple_seed_mixing-0'                              AND origin.reference_name = 'second_seed_input'        AND intervention_parameters.reference_name = 'second_seed_input_to_use')
        OR (oi.reference_name = 'base-triple_seed_mixing-0'                              AND origin.reference_name = 'third_seed_input'         AND intervention_parameters.reference_name = 'third_seed_input_to_use')
        OR (oi.reference_name = 'base-triple_spraying_on_cultivation-0'                  AND origin.reference_name = 'first_plant_medicine'     AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray')
        OR (oi.reference_name = 'base-triple_spraying_on_cultivation-0'                  AND origin.reference_name = 'second_plant_medicine'    AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray')
        OR (oi.reference_name = 'base-triple_spraying_on_cultivation-0'                  AND origin.reference_name = 'third_plant_medicine'     AND intervention_parameters.reference_name = 'third_plant_medicine_to_spray')
        OR (oi.reference_name = 'base-walnuts_transport-0'                               AND origin.reference_name = 'nuts'                     AND intervention_parameters.reference_name = 'nuts_to_deliver')
        OR (oi.reference_name = 'base-watering-0'                                        AND origin.reference_name = 'water'                    AND intervention_parameters.reference_name = 'water_to_spread')
        OR (oi.reference_name = 'base-wine_blending-0'                                   AND origin.reference_name = 'wine'                     AND intervention_parameters.reference_name = 'wine_to_blend')
        OR (oi.reference_name = 'base-wine_blending-0'                                   AND origin.reference_name = 'adding_wine'              AND intervention_parameters.reference_name = 'adding_wine_to_blend')
        OR (oi.reference_name = 'base-wine_bottling-0'                                   AND origin.reference_name = 'wine'                     AND intervention_parameters.reference_name = 'wine_to_pack')
        OR (oi.reference_name = 'base-wine_bottling-0'                                   AND origin.reference_name = 'bottles'                  AND intervention_parameters.reference_name = 'bottles_to_use')
        OR (oi.reference_name = 'base-wine_bottling-0'                                   AND origin.reference_name = 'corks'                    AND intervention_parameters.reference_name = 'corks_to_use')
      )
SQL
    execute <<SQL
      DELETE FROM intervention_parameters
      WHERE id IN (
        SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id)
        WHERE
             (i.reference_name = 'base-all_in_one_sowing-0'                              AND c.reference_name = 'seeds')
          OR (i.reference_name = 'base-all_in_one_sowing-0'                              AND c.reference_name = 'fertilizer')
          OR (i.reference_name = 'base-all_in_one_sowing-0'                              AND c.reference_name = 'insecticide')
          OR (i.reference_name = 'base-all_in_one_sowing-0'                              AND c.reference_name = 'molluscicide')
          OR (i.reference_name = 'base-animal_artificial_insemination-0'                 AND c.reference_name = 'vial')
          OR (i.reference_name = 'base-animal_housing_mulching-0'                        AND c.reference_name = 'straw')
          OR (i.reference_name = 'base-animal_treatment-0'                               AND c.reference_name = 'animal_medicine')
          OR (i.reference_name = 'base-chaptalization-0'                                 AND c.reference_name = 'oenological_intrant')
          OR (i.reference_name = 'base-chemical_weed_killing-0'                          AND c.reference_name = 'weedkiller')
          OR (i.reference_name = 'base-double_chemical_mixing-0'                         AND c.reference_name = 'first_chemical_input')
          OR (i.reference_name = 'base-double_chemical_mixing-0'                         AND c.reference_name = 'second_chemical_input')
          OR (i.reference_name = 'base-double_food_mixing-0'                             AND c.reference_name = 'first_food_input')
          OR (i.reference_name = 'base-double_food_mixing-0'                             AND c.reference_name = 'second_food_input')
          OR (i.reference_name = 'base-double_seed_mixing-0'                             AND c.reference_name = 'first_seed_input')
          OR (i.reference_name = 'base-double_seed_mixing-0'                             AND c.reference_name = 'second_seed_input')
          OR (i.reference_name = 'base-double_spraying_on_cultivation-0'                 AND c.reference_name = 'first_plant_medicine')
          OR (i.reference_name = 'base-double_spraying_on_cultivation-0'                 AND c.reference_name = 'second_plant_medicine')
          OR (i.reference_name = 'base-double_spraying_on_land_parcel-0'                 AND c.reference_name = 'first_plant_medicine')
          OR (i.reference_name = 'base-double_spraying_on_land_parcel-0'                 AND c.reference_name = 'second_plant_medicine')
          OR (i.reference_name = 'base-enzyme_addition-0'                                AND c.reference_name = 'oenological_intrant')
          OR (i.reference_name = 'base-fermentation-0'                                   AND c.reference_name = 'oenological_intrant')
          OR (i.reference_name = 'base-filling-0'                                        AND c.reference_name = 'items')
          OR (i.reference_name = 'base-fuel_up-0'                                        AND c.reference_name = 'fuel')
          OR (i.reference_name = 'base-grain_transport-0'                                AND c.reference_name = 'grain')
          OR (i.reference_name = 'base-grape_pressing-0'                                 AND c.reference_name = 'grape')
          OR (i.reference_name = 'base-grape_transport-0'                                AND c.reference_name = 'grape')
          OR (i.reference_name = 'base-hazelnuts_transport-0'                            AND c.reference_name = 'nuts')
          OR (i.reference_name = 'base-implanting-0'                                     AND c.reference_name = 'plants')
          OR (i.reference_name = 'base-item_replacement-0'                               AND c.reference_name = 'item')
          OR (i.reference_name = 'base-manual_feeding-0'                                 AND c.reference_name = 'silage')
          OR (i.reference_name = 'base-mineral_fertilizing-0'                            AND c.reference_name = 'fertilizer')
          OR (i.reference_name = 'base-oil_replacement-0'                                AND c.reference_name = 'oil')
          OR (i.reference_name = 'base-organic_fertilizing-0'                            AND c.reference_name = 'manure')
          OR (i.reference_name = 'base-partial_wine_transfer-0'                          AND c.reference_name = 'wine')
          OR (i.reference_name = 'base-plastic_mulching-0'                               AND c.reference_name = 'plastic')
          OR (i.reference_name = 'base-silage_transport-0'                               AND c.reference_name = 'silage')
          OR (i.reference_name = 'base-silage_unload-0'                                  AND c.reference_name = 'silage')
          OR (i.reference_name = 'base-sorting-0'                                        AND c.reference_name = 'sortable')
          OR (i.reference_name = 'base-sowing-0'                                         AND c.reference_name = 'seeds')
          OR (i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'       AND c.reference_name = 'seeds')
          OR (i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'       AND c.reference_name = 'insecticide')
          OR (i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'       AND c.reference_name = 'molluscicide')
          OR (i.reference_name = 'base-spraying_on_cultivation-0'                        AND c.reference_name = 'plant_medicine')
          OR (i.reference_name = 'base-spraying_on_land_parcel-0'                        AND c.reference_name = 'plant_medicine')
          OR (i.reference_name = 'base-standard_enclosing-0'                             AND c.reference_name = 'stakes')
          OR (i.reference_name = 'base-standard_enclosing-0'                             AND c.reference_name = 'wire_fence')
          OR (i.reference_name = 'base-straw_transport-0'                                AND c.reference_name = 'straw')
          OR (i.reference_name = 'base-sulfur_addition-0'                                AND c.reference_name = 'oenological_intrant')
          OR (i.reference_name = 'base-triple_food_mixing-0'                             AND c.reference_name = 'first_food_input')
          OR (i.reference_name = 'base-triple_food_mixing-0'                             AND c.reference_name = 'second_food_input')
          OR (i.reference_name = 'base-triple_food_mixing-0'                             AND c.reference_name = 'third_food_input')
          OR (i.reference_name = 'base-triple_seed_mixing-0'                             AND c.reference_name = 'first_seed_input')
          OR (i.reference_name = 'base-triple_seed_mixing-0'                             AND c.reference_name = 'second_seed_input')
          OR (i.reference_name = 'base-triple_seed_mixing-0'                             AND c.reference_name = 'third_seed_input')
          OR (i.reference_name = 'base-triple_spraying_on_cultivation-0'                 AND c.reference_name = 'first_plant_medicine')
          OR (i.reference_name = 'base-triple_spraying_on_cultivation-0'                 AND c.reference_name = 'second_plant_medicine')
          OR (i.reference_name = 'base-triple_spraying_on_cultivation-0'                 AND c.reference_name = 'third_plant_medicine')
          OR (i.reference_name = 'base-walnuts_transport-0'                              AND c.reference_name = 'nuts')
          OR (i.reference_name = 'base-watering-0'                                       AND c.reference_name = 'water')
          OR (i.reference_name = 'base-wine_blending-0'                                  AND c.reference_name = 'wine')
          OR (i.reference_name = 'base-wine_blending-0'                                  AND c.reference_name = 'adding_wine')
          OR (i.reference_name = 'base-wine_bottling-0'                                  AND c.reference_name = 'wine')
          OR (i.reference_name = 'base-wine_bottling-0'                                  AND c.reference_name = 'bottles')
          OR (i.reference_name = 'base-wine_bottling-0'                                  AND c.reference_name = 'corks')
      )
SQL
    execute <<SQL
      UPDATE intervention_parameters
      SET reference_name = CASE
        WHEN i.reference_name = 'base-all_in_one_sowing-0'                               AND intervention_parameters.reference_name = 'seeds_to_sow'                     THEN 'seeds'
        WHEN i.reference_name = 'base-all_in_one_sowing-0'                               AND intervention_parameters.reference_name = 'fertilizer_to_spread'             THEN 'fertilizer'
        WHEN i.reference_name = 'base-all_in_one_sowing-0'                               AND intervention_parameters.reference_name = 'insecticide_to_input'             THEN 'insecticide'
        WHEN i.reference_name = 'base-all_in_one_sowing-0'                               AND intervention_parameters.reference_name = 'molluscicide_to_input'            THEN 'molluscicide'
        WHEN i.reference_name = 'base-animal_artificial_insemination-0'                  AND intervention_parameters.reference_name = 'vial_to_give'                     THEN 'vial'
        WHEN i.reference_name = 'base-animal_housing_mulching-0'                         AND intervention_parameters.reference_name = 'straw_to_mulch'                   THEN 'straw'
        WHEN i.reference_name = 'base-animal_treatment-0'                                AND intervention_parameters.reference_name = 'animal_medicine_to_give'          THEN 'animal_medicine'
        WHEN i.reference_name = 'base-chaptalization-0'                                  AND intervention_parameters.reference_name = 'oenological_intrant_to_put'       THEN 'oenological_intrant'
        WHEN i.reference_name = 'base-chemical_weed_killing-0'                           AND intervention_parameters.reference_name = 'weedkiller_to_spray'              THEN 'weedkiller'
        WHEN i.reference_name = 'base-double_chemical_mixing-0'                          AND intervention_parameters.reference_name = 'first_chemical_input_to_use'      THEN 'first_chemical_input'
        WHEN i.reference_name = 'base-double_chemical_mixing-0'                          AND intervention_parameters.reference_name = 'second_chemical_input_to_use'     THEN 'second_chemical_input'
        WHEN i.reference_name = 'base-double_food_mixing-0'                              AND intervention_parameters.reference_name = 'first_food_input_to_use'          THEN 'first_food_input'
        WHEN i.reference_name = 'base-double_food_mixing-0'                              AND intervention_parameters.reference_name = 'second_food_input_to_use'         THEN 'second_food_input'
        WHEN i.reference_name = 'base-double_seed_mixing-0'                              AND intervention_parameters.reference_name = 'first_seed_input_to_use'          THEN 'first_seed_input'
        WHEN i.reference_name = 'base-double_seed_mixing-0'                              AND intervention_parameters.reference_name = 'second_seed_input_to_use'         THEN 'second_seed_input'
        WHEN i.reference_name = 'base-double_spraying_on_cultivation-0'                  AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray'    THEN 'first_plant_medicine'
        WHEN i.reference_name = 'base-double_spraying_on_cultivation-0'                  AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray'   THEN 'second_plant_medicine'
        WHEN i.reference_name = 'base-double_spraying_on_land_parcel-0'                  AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray'    THEN 'first_plant_medicine'
        WHEN i.reference_name = 'base-double_spraying_on_land_parcel-0'                  AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray'   THEN 'second_plant_medicine'
        WHEN i.reference_name = 'base-enzyme_addition-0'                                 AND intervention_parameters.reference_name = 'oenological_intrant_to_put'       THEN 'oenological_intrant'
        WHEN i.reference_name = 'base-fermentation-0'                                    AND intervention_parameters.reference_name = 'oenological_intrant_to_put'       THEN 'oenological_intrant'
        WHEN i.reference_name = 'base-filling-0'                                         AND intervention_parameters.reference_name = 'items_to_fill'                    THEN 'items'
        WHEN i.reference_name = 'base-fuel_up-0'                                         AND intervention_parameters.reference_name = 'fuel_to_input'                    THEN 'fuel'
        WHEN i.reference_name = 'base-grain_transport-0'                                 AND intervention_parameters.reference_name = 'grain_to_deliver'                 THEN 'grain'
        WHEN i.reference_name = 'base-grape_pressing-0'                                  AND intervention_parameters.reference_name = 'grape_to_press'                   THEN 'grape'
        WHEN i.reference_name = 'base-grape_transport-0'                                 AND intervention_parameters.reference_name = 'grape_to_deliver'                 THEN 'grape'
        WHEN i.reference_name = 'base-hazelnuts_transport-0'                             AND intervention_parameters.reference_name = 'nuts_to_deliver'                  THEN 'nuts'
        WHEN i.reference_name = 'base-implanting-0'                                      AND intervention_parameters.reference_name = 'plants_to_fix'                    THEN 'plants'
        WHEN i.reference_name = 'base-item_replacement-0'                                AND intervention_parameters.reference_name = 'item_to_change'                   THEN 'item'
        WHEN i.reference_name = 'base-manual_feeding-0'                                  AND intervention_parameters.reference_name = 'silage_to_give'                   THEN 'silage'
        WHEN i.reference_name = 'base-mineral_fertilizing-0'                             AND intervention_parameters.reference_name = 'fertilizer_to_spread'             THEN 'fertilizer'
        WHEN i.reference_name = 'base-oil_replacement-0'                                 AND intervention_parameters.reference_name = 'oil_to_input'                     THEN 'oil'
        WHEN i.reference_name = 'base-organic_fertilizing-0'                             AND intervention_parameters.reference_name = 'manure_to_spread'                 THEN 'manure'
        WHEN i.reference_name = 'base-partial_wine_transfer-0'                           AND intervention_parameters.reference_name = 'wine_to_move'                     THEN 'wine'
        WHEN i.reference_name = 'base-plastic_mulching-0'                                AND intervention_parameters.reference_name = 'plastic_to_mulch'                 THEN 'plastic'
        WHEN i.reference_name = 'base-silage_transport-0'                                AND intervention_parameters.reference_name = 'silage_to_deliver'                THEN 'silage'
        WHEN i.reference_name = 'base-silage_unload-0'                                   AND intervention_parameters.reference_name = 'silage_to_give'                   THEN 'silage'
        WHEN i.reference_name = 'base-sorting-0'                                         AND intervention_parameters.reference_name = 'sortable_to_sort'                 THEN 'sortable'
        WHEN i.reference_name = 'base-sowing-0'                                          AND intervention_parameters.reference_name = 'seeds_to_sow'                     THEN 'seeds'
        WHEN i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'        AND intervention_parameters.reference_name = 'seeds_to_sow'                     THEN 'seeds'
        WHEN i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'        AND intervention_parameters.reference_name = 'insecticide_to_input'             THEN 'insecticide'
        WHEN i.reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'        AND intervention_parameters.reference_name = 'molluscicide_to_input'            THEN 'molluscicide'
        WHEN i.reference_name = 'base-spraying_on_cultivation-0'                         AND intervention_parameters.reference_name = 'plant_medicine_to_spray'          THEN 'plant_medicine'
        WHEN i.reference_name = 'base-spraying_on_land_parcel-0'                         AND intervention_parameters.reference_name = 'plant_medicine_to_spray'          THEN 'plant_medicine'
        WHEN i.reference_name = 'base-standard_enclosing-0'                              AND intervention_parameters.reference_name = 'stakes_to_plant'                  THEN 'stakes'
        WHEN i.reference_name = 'base-standard_enclosing-0'                              AND intervention_parameters.reference_name = 'wire_fence_to_put'                THEN 'wire_fence'
        WHEN i.reference_name = 'base-straw_transport-0'                                 AND intervention_parameters.reference_name = 'straw_to_deliver'                 THEN 'straw'
        WHEN i.reference_name = 'base-sulfur_addition-0'                                 AND intervention_parameters.reference_name = 'oenological_intrant_to_put'       THEN 'oenological_intrant'
        WHEN i.reference_name = 'base-triple_food_mixing-0'                              AND intervention_parameters.reference_name = 'first_food_input_to_use'          THEN 'first_food_input'
        WHEN i.reference_name = 'base-triple_food_mixing-0'                              AND intervention_parameters.reference_name = 'second_food_input_to_use'         THEN 'second_food_input'
        WHEN i.reference_name = 'base-triple_food_mixing-0'                              AND intervention_parameters.reference_name = 'third_food_input_to_use'          THEN 'third_food_input'
        WHEN i.reference_name = 'base-triple_seed_mixing-0'                              AND intervention_parameters.reference_name = 'first_seed_input_to_use'          THEN 'first_seed_input'
        WHEN i.reference_name = 'base-triple_seed_mixing-0'                              AND intervention_parameters.reference_name = 'second_seed_input_to_use'         THEN 'second_seed_input'
        WHEN i.reference_name = 'base-triple_seed_mixing-0'                              AND intervention_parameters.reference_name = 'third_seed_input_to_use'          THEN 'third_seed_input'
        WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0'                  AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray'    THEN 'first_plant_medicine'
        WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0'                  AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray'   THEN 'second_plant_medicine'
        WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0'                  AND intervention_parameters.reference_name = 'third_plant_medicine_to_spray'    THEN 'third_plant_medicine'
        WHEN i.reference_name = 'base-walnuts_transport-0'                               AND intervention_parameters.reference_name = 'nuts_to_deliver'                  THEN 'nuts'
        WHEN i.reference_name = 'base-watering-0'                                        AND intervention_parameters.reference_name = 'water_to_spread'                  THEN 'water'
        WHEN i.reference_name = 'base-wine_blending-0'                                   AND intervention_parameters.reference_name = 'wine_to_blend'                    THEN 'wine'
        WHEN i.reference_name = 'base-wine_blending-0'                                   AND intervention_parameters.reference_name = 'adding_wine_to_blend'             THEN 'adding_wine'
        WHEN i.reference_name = 'base-wine_bottling-0'                                   AND intervention_parameters.reference_name = 'wine_to_pack'                     THEN 'wine'
        WHEN i.reference_name = 'base-wine_bottling-0'                                   AND intervention_parameters.reference_name = 'bottles_to_use'                   THEN 'bottles'
        WHEN i.reference_name = 'base-wine_bottling-0'                                   AND intervention_parameters.reference_name = 'corks_to_use'                     THEN 'corks'
       ELSE intervention_parameters.reference_name END
      FROM interventions AS i
      WHERE i.id = intervention_id
SQL
    # Merge interventions
    execute <<SQL
      DELETE FROM intervention_parameters
      WHERE id IN (SELECT c.id FROM intervention_parameters AS c JOIN interventions AS i ON (i.id = c.intervention_id)
        WHERE (i.reference_name = 'base-plums_harvest-0' AND c.reference_name = 'tractor')
       OR (i.reference_name = 'base-triple_food_mixing-0' AND c.reference_name = 'food_storage')
       OR (i.reference_name = 'base-double_food_mixing-0' AND c.reference_name = 'food_storage')
      )
SQL
    execute <<SQL
      UPDATE intervention_parameters
      SET reference_name = CASE
        WHEN i.reference_name = 'base-all_in_one_sowing-0' AND intervention_parameters.reference_name = 'molluscicide' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-all_in_one_sowing-0' AND intervention_parameters.reference_name = 'insecticide' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-calving_twin-0' AND intervention_parameters.reference_name = 'first_child' THEN 'child'
       WHEN i.reference_name = 'base-calving_twin-0' AND intervention_parameters.reference_name = 'second_child' THEN 'child'
       WHEN i.reference_name = 'base-chemical_weed_killing-0' AND intervention_parameters.reference_name = 'weedkiller' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-chemical_weed_killing-0' AND intervention_parameters.reference_name = 'weedkiller_to_spray' THEN 'plant_medicine_to_spray'
       WHEN i.reference_name = 'base-chemical_weed_killing-0' AND intervention_parameters.reference_name = 'land_parcel' THEN 'cultivation'
       WHEN i.reference_name = 'base-double_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'first_plant_medicine' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-double_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray' THEN 'plant_medicine_to_spray'
       WHEN i.reference_name = 'base-double_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'second_plant_medicine' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-double_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray' THEN 'plant_medicine_to_spray'
       WHEN i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name = 'first_plant_medicine' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray' THEN 'plant_medicine_to_spray'
       WHEN i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name = 'second_plant_medicine' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray' THEN 'plant_medicine_to_spray'
       WHEN i.reference_name = 'base-double_spraying_on_land_parcel-0' AND intervention_parameters.reference_name = 'land_parcel' THEN 'cultivation'
       WHEN i.reference_name = 'base-hazelnuts_harvest-0' AND intervention_parameters.reference_name = 'driver' THEN 'cropper_driver'
       WHEN i.reference_name = 'base-hazelnuts_harvest-0' AND intervention_parameters.reference_name = 'nuts_harvester' THEN 'cropper'
       WHEN i.reference_name = 'base-hazelnuts_harvest-0' AND intervention_parameters.reference_name = 'hazelnuts' THEN 'grains'
       WHEN i.reference_name = 'base-mammal_herd_milking-0' AND intervention_parameters.reference_name = 'mammal_herd_to_milk' THEN 'mammal_to_milk'
       WHEN i.reference_name = 'base-organic_fertilizing-0' AND intervention_parameters.reference_name = 'manure' THEN 'fertilizer'
       WHEN i.reference_name = 'base-organic_fertilizing-0' AND intervention_parameters.reference_name = 'manure_to_spread' THEN 'fertilizer_to_spread'
       WHEN i.reference_name = 'base-plants_harvest-0' AND intervention_parameters.reference_name = 'plants' THEN 'grains'
       WHEN i.reference_name = 'base-plums_harvest-0' AND intervention_parameters.reference_name = 'driver' THEN 'cropper_driver'
       WHEN i.reference_name = 'base-plums_harvest-0' AND intervention_parameters.reference_name = 'fruit_harvester' THEN 'cropper'
       WHEN i.reference_name = 'base-plums_harvest-0' AND intervention_parameters.reference_name = 'fruits' THEN 'grains'
       WHEN i.reference_name = 'base-spraying_on_land_parcel-0' AND intervention_parameters.reference_name = 'land_parcel' THEN 'cultivation'
       WHEN i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name = 'first_food_input' THEN 'food'
       WHEN i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name = 'first_food_input_to_use' THEN 'food'
       WHEN i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name = 'second_food_input' THEN 'food'
       WHEN i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name = 'second_food_input_to_use' THEN 'food'
       WHEN i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name = 'third_food_input' THEN 'food'
       WHEN i.reference_name = 'base-triple_food_mixing-0' AND intervention_parameters.reference_name = 'third_food_input_to_use' THEN 'food'
       WHEN i.reference_name = 'base-double_food_mixing-0' AND intervention_parameters.reference_name = 'first_food_input' THEN 'food'
       WHEN i.reference_name = 'base-double_food_mixing-0' AND intervention_parameters.reference_name = 'first_food_input_to_use' THEN 'food'
       WHEN i.reference_name = 'base-double_food_mixing-0' AND intervention_parameters.reference_name = 'second_food_input' THEN 'food'
       WHEN i.reference_name = 'base-double_food_mixing-0' AND intervention_parameters.reference_name = 'second_food_input_to_use' THEN 'food'
       WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'first_plant_medicine' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'first_plant_medicine_to_spray' THEN 'plant_medicine_to_spray'
       WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'second_plant_medicine' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'second_plant_medicine_to_spray' THEN 'plant_medicine_to_spray'
       WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'third_plant_medicine' THEN 'plant_medicine'
       WHEN i.reference_name = 'base-triple_spraying_on_cultivation-0' AND intervention_parameters.reference_name = 'third_plant_medicine_to_spray' THEN 'plant_medicine_to_spray'
       WHEN i.reference_name = 'base-vine_harvest-0' AND intervention_parameters.reference_name = 'grape_reaper_driver' THEN 'cropper_driver'
       WHEN i.reference_name = 'base-vine_harvest-0' AND intervention_parameters.reference_name = 'grape_reaper' THEN 'cropper'
       WHEN i.reference_name = 'base-vine_harvest-0' AND intervention_parameters.reference_name = 'fruits' THEN 'grains'
       WHEN i.reference_name = 'base-walnuts_harvest-0' AND intervention_parameters.reference_name = 'driver' THEN 'cropper_driver'
       WHEN i.reference_name = 'base-walnuts_harvest-0' AND intervention_parameters.reference_name = 'nuts_harvester' THEN 'cropper'
       WHEN i.reference_name = 'base-walnuts_harvest-0' AND intervention_parameters.reference_name = 'walnuts' THEN 'grains'
       ELSE intervention_parameters.reference_name END
      FROM interventions AS i WHERE i.id = intervention_id
SQL
    # Add groups
    execute "INSERT INTO intervention_parameters (intervention_id, type, reference_name, position, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, 'InterventionGroupParameter', 'zone', 999, created_at, creator_id, updated_at, updater_id, lock_version FROM interventions WHERE reference_name = 'base-sowing-0'"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-sowing-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id AND reference_name IN ('land_parcel', 'cultivation')"
    execute "INSERT INTO intervention_parameters (intervention_id, type, reference_name, position, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, 'InterventionGroupParameter', 'zone', 999, created_at, creator_id, updated_at, updater_id, lock_version FROM interventions WHERE reference_name = 'base-sowing_with_spraying-0'"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-sowing_with_spraying-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id AND reference_name IN ('land_parcel', 'cultivation')"
    execute "INSERT INTO intervention_parameters (intervention_id, type, reference_name, position, created_at, creator_id, updated_at, updater_id, lock_version) SELECT id, 'InterventionGroupParameter', 'zone', 999, created_at, creator_id, updated_at, updater_id, lock_version FROM interventions WHERE reference_name = 'base-all_in_one_sowing-0'"
    execute "UPDATE intervention_parameters SET group_id = groups.id FROM (SELECT cg.id, cg.intervention_id FROM intervention_parameters AS cg JOIN interventions AS i ON (cg.intervention_id = i.id) WHERE type = 'InterventionGroupParameter' AND cg.reference_name = 'zone' AND i.reference_name = 'base-all_in_one_sowing-0') AS groups WHERE groups.intervention_id = intervention_parameters.intervention_id AND reference_name IN ('land_parcel', 'cultivation')"
    execute "DELETE FROM intervention_parameters WHERE type = 'Trash'"
    # Remove not wanted interventions
    execute "DELETE FROM intervention_parameters WHERE intervention_id IN (SELECT id FROM interventions WHERE reference_name IN ('base-administrative_task-0', 'base-attach-0', 'base-detach-0', 'base-double_chemical_mixing-0', 'base-double_seed_mixing-0', 'base-filling-0', 'base-group_exclusion-0', 'base-group_inclusion-0', 'base-maintenance_task-0', 'base-product_evolution-0', 'base-product_moving-0', 'base-technical_task-0', 'base-triple_seed_mixing-0'))"
    execute "DELETE FROM interventions WHERE reference_name IN ('base-administrative_task-0', 'base-attach-0', 'base-detach-0', 'base-double_chemical_mixing-0', 'base-double_seed_mixing-0', 'base-filling-0', 'base-group_exclusion-0', 'base-group_inclusion-0', 'base-maintenance_task-0', 'base-product_evolution-0', 'base-product_moving-0', 'base-technical_task-0', 'base-triple_seed_mixing-0')"
    # Rename interventions
    execute <<SQL
      UPDATE interventions
      SET reference_name = CASE
         WHEN reference_name = 'base-animal_treatment-0'                          THEN 'base-animal_antibiotic_treatment-0'
         WHEN reference_name = 'base-calving_one-0'                               THEN 'base-parturition-0'
         WHEN reference_name = 'base-egg_production-0'                            THEN 'base-egg_collecting-0'
         WHEN reference_name = 'base-grains_harvest-0'                            THEN 'base-mechanical_harvesting-0'
         WHEN reference_name = 'base-grinding-0'                                  THEN 'base-crop_residues_grinding-0'
         WHEN reference_name = 'base-implanting-0'                                THEN 'base-mechanical_planting-0'
         WHEN reference_name = 'base-item_replacement-0'                          THEN 'base-equipment_item_replacement-0'
         WHEN reference_name = 'base-mammal_milking-0'                            THEN 'base-milking-0'
         WHEN reference_name = 'base-mineral_fertilizing-0'                       THEN 'base-mechanical_fertilizing-0'
         WHEN reference_name = 'base-plastic_mulching-0'                          THEN 'base-plant_mulching-0'
         WHEN reference_name = 'base-sorting-0'                                   THEN 'base-field_plant_sorting-0'
         WHEN reference_name = 'base-sowing_with_insecticide_and_molluscicide-0'  THEN 'base-sowing_with_spraying-0'
         WHEN reference_name = 'base-spraying_on_cultivation-0'                   THEN 'base-spraying-0'
         WHEN reference_name = 'base-watering-0'                                  THEN 'base-plant_watering-0'
        ELSE reference_name END
      WHERE reference_name IN ('base-animal_treatment-0', 'base-calving_one-0', 'base-egg_production-0', 'base-grains_harvest-0', 'base-grinding-0', 'base-implanting-0', 'base-item_replacement-0', 'base-mammal_milking-0', 'base-mineral_fertilizing-0', 'base-plastic_mulching-0', 'base-sorting-0', 'base-sowing_with_insecticide_and_molluscicide-0', 'base-spraying_on_cultivation-0', 'base-watering-0')
SQL
    # Rename interventions
    execute <<SQL
      UPDATE interventions
      SET reference_name = CASE
         WHEN reference_name = 'base-calving_twin-0'                              THEN 'base-parturition-0'
         WHEN reference_name = 'base-chemical_weed_killing-0'                     THEN 'base-spraying-0'
         WHEN reference_name = 'base-double_spraying_on_cultivation-0'            THEN 'base-spraying-0'
         WHEN reference_name = 'base-double_spraying_on_land_parcel-0'            THEN 'base-spraying-0'
         WHEN reference_name = 'base-spraying_on_land_parcel-0'                   THEN 'base-spraying-0'
         WHEN reference_name = 'base-triple_spraying_on_cultivation-0'            THEN 'base-spraying-0'
         WHEN reference_name = 'base-harvest_helping-0'                           THEN 'base-mechanical_harvesting-0'
         WHEN reference_name = 'base-hazelnuts_harvest-0'                         THEN 'base-mechanical_harvesting-0'
         WHEN reference_name = 'base-plants_harvest-0'                            THEN 'base-mechanical_harvesting-0'
         WHEN reference_name = 'base-plums_harvest-0'                             THEN 'base-mechanical_harvesting-0'
         WHEN reference_name = 'base-vine_harvest-0'                              THEN 'base-mechanical_harvesting-0'
         WHEN reference_name = 'base-walnuts_harvest-0'                           THEN 'base-mechanical_harvesting-0'
         WHEN reference_name = 'base-implant_helping-0'                           THEN 'base-mechanical_planting-0'
         WHEN reference_name = 'base-mammal_herd_milking-0'                       THEN 'base-milking-0'
         WHEN reference_name = 'base-organic_fertilizing-0'                       THEN 'base-mechanical_fertilizing-0'
         WHEN reference_name = 'base-plant_grinding-0'                            THEN 'base-crop_residues_grinding-0'
         WHEN reference_name = 'base-double_food_mixing-0'                        THEN 'base-food_preparation-0'
         WHEN reference_name = 'base-triple_food_mixing-0'                        THEN 'base-food_preparation-0'
        ELSE reference_name END
      WHERE reference_name IN ('base-calving_twin-0', 'base-chemical_weed_killing-0', 'base-double_spraying_on_cultivation-0', 'base-double_spraying_on_land_parcel-0', 'base-spraying_on_land_parcel-0', 'base-triple_spraying_on_cultivation-0', 'base-harvest_helping-0', 'base-hazelnuts_harvest-0', 'base-plants_harvest-0', 'base-plums_harvest-0', 'base-vine_harvest-0', 'base-walnuts_harvest-0', 'base-implant_helping-0', 'base-mammal_herd_milking-0', 'base-organic_fertilizing-0', 'base-plant_grinding-0', 'base-double_food_mixing-0', 'base-triple_food_mixing-0')
SQL
  end
end
