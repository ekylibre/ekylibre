class RenameBudgetsToProductionBudgets < ActiveRecord::Migration
  PRODUCTION_STATES = {
    draft: :opened,
    validated: :closed
  }.freeze

  def change
    rename_table :budgets, :production_budgets
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='ProductionBudget' WHERE #{quote_column_name(:resource_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='ProductionBudget' WHERE #{quote_column_name(:ressource_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='ProductionBudget' WHERE #{quote_column_name(:target_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='ProductionBudget' WHERE #{quote_column_name(:resource_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='ProductionBudget' WHERE #{quote_column_name(:subject_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='ProductionBudget' WHERE #{quote_column_name(:record_value_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='ProductionBudget' WHERE #{quote_column_name(:originator_type)}='Budget'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='ProductionBudget' WHERE #{quote_column_name(:item_type)}='Budget'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='Budget' WHERE #{quote_column_name(:resource_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='Budget' WHERE #{quote_column_name(:ressource_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='Budget' WHERE #{quote_column_name(:target_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='Budget' WHERE #{quote_column_name(:resource_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='Budget' WHERE #{quote_column_name(:subject_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='Budget' WHERE #{quote_column_name(:record_value_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='Budget' WHERE #{quote_column_name(:originator_type)}='ProductionBudget'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='Budget' WHERE #{quote_column_name(:item_type)}='ProductionBudget'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='ProductionBudget' WHERE #{quote_column_name(:customized_type)}='Budget'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='Budget' WHERE #{quote_column_name(:customized_type)}='ProductionBudget'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='production_budget' WHERE #{quote_column_name(:root_model)}='budget'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='budget' WHERE #{quote_column_name(:root_model)}='production_budget'"
      end
    end

    change_column_null :production_budgets, :production_id, false
    change_column_null :production_budgets, :direction, false
    change_column_null :production_budgets, :computation_method, false

    rename_column :production_budgets, :global_amount, :amount
    rename_column :production_budgets, :global_quantity, :quantity
    rename_column :production_budgets, :working_indicator, :variant_indicator
    rename_column :production_budgets, :working_unit, :variant_unit
    add_column :production_budgets, :unit_population, :decimal, precision: 19, scale: 4
    add_column :production_budgets, :unit_currency, :string
    rename_column :productions, :variant_id, :cultivation_variant_id

    reversible do |dir|
      dir.up do
        execute "UPDATE \"production_budgets\" SET currency = 'EUR' WHERE currency IS NULL"
        execute 'UPDATE "production_budgets" SET unit_currency = currency'
        change_column_null :production_budgets, :unit_currency, false
        change_column_null :production_budgets, :currency, false

        remove_column :production_budgets, :name

        drop_table :budget_items

        drop_table :production_support_markers
      end

      dir.down do
        create_table 'production_support_markers', force: :cascade do |t|
          t.integer 'support_id', null: false
          t.string 'aim', null: false
          t.string 'subject'
          t.string 'derivative'
          t.string 'indicator_name',                                                                                                 null: false
          t.string 'indicator_datatype',                                                                                             null: false
          t.decimal 'absolute_measure_value_value', precision: 19, scale: 4
          t.string 'absolute_measure_value_unit'
          t.boolean 'boolean_value', default: false, null: false
          t.string 'choice_value'
          t.decimal 'decimal_value', precision: 19, scale: 4
          t.geometry 'geometry_value', limit: { srid: 4326, type: 'geometry' }
          t.integer 'integer_value'
          t.decimal 'measure_value_value', precision: 19, scale: 4
          t.string 'measure_value_unit'
          t.st_point 'point_value', srid: 4326
          t.text 'string_value'
          t.datetime 'created_at',                                                                                                     null: false
          t.datetime 'updated_at',                                                                                                     null: false
          t.integer 'creator_id'
          t.integer 'updater_id'
          t.integer 'lock_version', default: 0, null: false
        end

        add_index 'production_support_markers', ['created_at'], name: 'index_production_support_markers_on_created_at', using: :btree
        add_index 'production_support_markers', ['creator_id'], name: 'index_production_support_markers_on_creator_id', using: :btree
        add_index 'production_support_markers', ['indicator_name'], name: 'index_production_support_markers_on_indicator_name', using: :btree
        add_index 'production_support_markers', ['support_id'], name: 'index_production_support_markers_on_support_id', using: :btree
        add_index 'production_support_markers', ['updated_at'], name: 'index_production_support_markers_on_updated_at', using: :btree
        add_index 'production_support_markers', ['updater_id'], name: 'index_production_support_markers_on_updater_id', using: :btree

        create_table 'budget_items', force: :cascade do |t|
          t.integer 'budget_id', null: false
          t.integer 'production_support_id'
          t.decimal 'quantity',                          precision: 19, scale: 4, default: 1.0, null: false
          t.decimal 'global_amount',                     precision: 19, scale: 4, default: 0.0, null: false
          t.string 'currency'
          t.datetime 'created_at',                                                               null: false
          t.datetime 'updated_at',                                                               null: false
          t.integer 'creator_id'
          t.integer 'updater_id'
          t.integer 'lock_version', default: 0, null: false
        end

        add_index 'budget_items', ['budget_id'], name: 'index_budget_items_on_budget_id', using: :btree
        add_index 'budget_items', ['created_at'], name: 'index_budget_items_on_created_at', using: :btree
        add_index 'budget_items', ['creator_id'], name: 'index_budget_items_on_creator_id', using: :btree
        add_index 'budget_items', ['production_support_id'], name: 'index_budget_items_on_production_support_id', using: :btree
        add_index 'budget_items', ['updated_at'], name: 'index_budget_items_on_updated_at', using: :btree
        add_index 'budget_items', ['updater_id'], name: 'index_budget_items_on_updater_id', using: :btree

        add_column :production_budgets, :name, :string
        execute 'UPDATE production_budgets SET name = v.name FROM product_nature_variants AS v WHERE v.id = variant_id'
      end
    end

    remove_column :production_budgets, :homogeneous_values, :boolean, null: false, default: false
    remove_column :productions, :homogeneous_expenses, :boolean, null: false, default: false
    remove_column :productions, :homogeneous_revenues, :boolean, null: false, default: false
    remove_column :productions, :static_support, :boolean, null: false, default: false

    remove_column :production_supports, :exclusive, :boolean, null: false, default: false
    add_column :productions, :irrigated, :boolean, null: false, default: false
    add_column :productions, :nitrate_fixing, :boolean, null: false, default: false

    rename_column :productions, :working_indicator, :support_variant_indicator
    rename_column :productions, :working_unit, :support_variant_unit

    add_column :activities, :with_supports,       :boolean
    add_column :activities, :with_cultivation,    :boolean
    reversible do |dir|
      dir.up do
        execute 'UPDATE activities SET with_supports = false, with_cultivation = false'
        execute 'UPDATE activities SET with_supports = true WHERE id IN (SELECT activity_id FROM productions AS p JOIN production_supports AS s ON (s.production_id=p.id))'
        execute 'UPDATE activities SET with_cultivation = true WHERE id IN (SELECT activity_id FROM productions AS p JOIN interventions AS i ON (i.production_id=p.id))'
      end
    end
    change_column_null :activities, :with_supports,    false
    change_column_null :activities, :with_cultivation, false

    add_column :activities, :support_variety,     :string
    add_column :activities, :cultivation_variety, :string

    # Moves columns of support to production
    reversible do |dir|
      dir.up do
        %w[started_at stopped_at].each do |column|
          execute "UPDATE productions SET #{column} = s.#{column} FROM production_supports AS s WHERE s.production_id = productions.id AND productions.#{column} IS NULL AND s.#{column} IS NOT NULL"
        end
        execute 'UPDATE productions SET irrigated = id IN (SELECT production_id FROM production_supports WHERE irrigated)'
        execute "UPDATE productions SET nitrate_fixing = id IN (SELECT production_id FROM production_supports WHERE nature = 'nitrat_trap')"
        remove_column :production_supports, :nature
        remove_column :production_supports, :irrigated
        remove_column :production_supports, :started_at
        remove_column :production_supports, :stopped_at
      end
      dir.down do
        add_column :production_supports, :stopped_at, :datetime
        add_column :production_supports, :started_at, :datetime
        add_column :production_supports, :irrigated, :boolean, null: false, default: false
        add_column :production_supports, :nature, :string
        execute "UPDATE production_supports SET nature = CASE WHEN p.nitrate_fixing THEN 'nitrat_trap' ELSE 'main' END FROM productions AS p WHERE p.id = production_id"
        execute 'UPDATE production_supports SET irrigated = p.irrigated FROM productions AS p WHERE p.irrigated AND p.id = production_id'
        %w[started_at stopped_at].each do |column|
          execute "UPDATE production_supports SET #{column} = p.#{column} FROM productions AS p WHERE p.id = production_supports.production_id AND production_supports.#{column} IS NULL AND p.#{column} IS NOT NULL"
        end
        change_column_null :production_supports, :nature, false
      end
    end

    # Updates states of productions
    reversible do |dir|
      dir.up do
        PRODUCTION_STATES.each do |old, new|
          execute "UPDATE productions SET state = '#{new}' WHERE state = '#{old}'"
        end
      end
      dir.down do
        PRODUCTION_STATES.each do |new, old|
          execute "UPDATE productions SET state = '#{new}' WHERE state = '#{old}'"
        end
      end
    end
  end
end
