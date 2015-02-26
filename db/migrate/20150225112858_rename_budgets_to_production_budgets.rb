class RenameBudgetsToProductionBudgets < ActiveRecord::Migration

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
    rename_column :production_budgets, :working_indicator, :unit_indicator
    rename_column :production_budgets, :working_unit, :unit_unit
    add_column :production_budgets, :unit_population, :decimal, precision: 19, scale: 4
    add_column :production_budgets, :unit_currency, :string
    rename_column :productions, :variant_id, :producing_variant_id

    reversible do |dir|
      dir.up do
        execute "UPDATE \"production_budgets\" SET currency = 'EUR' WHERE currency IS NULL"
        execute "UPDATE \"production_budgets\" SET unit_currency = currency"
        change_column_null :production_budgets, :unit_currency, false
        change_column_null :production_budgets, :currency, false

        remove_column :production_budgets, :homogeneous_values
        remove_column :production_budgets, :name
        remove_column :productions, :static_support

        remove_column :productions, :homogeneous_expenses
        remove_column :productions, :homogeneous_revenues

        drop_table :budget_items

        drop_table :production_support_markers
      end

      dir.down do
        create_table "production_support_markers", force: :cascade do |t|
          t.integer  "support_id",                                                                                                     null: false
          t.string   "aim",                                                                                                            null: false
          t.string   "subject"
          t.string   "derivative"
          t.string   "indicator_name",                                                                                                 null: false
          t.string   "indicator_datatype",                                                                                             null: false
          t.decimal  "absolute_measure_value_value",                                          precision: 19, scale: 4
          t.string   "absolute_measure_value_unit"
          t.boolean  "boolean_value",                                                                                  default: false, null: false
          t.string   "choice_value"
          t.decimal  "decimal_value",                                                         precision: 19, scale: 4
          t.geometry "geometry_value",               limit: {:srid=>4326, :type=>"geometry"}
          t.integer  "integer_value"
          t.decimal  "measure_value_value",                                                   precision: 19, scale: 4
          t.string   "measure_value_unit"
          t.st_point "point_value", srid: 4326
          t.text     "string_value"
          t.datetime "created_at",                                                                                                     null: false
          t.datetime "updated_at",                                                                                                     null: false
          t.integer  "creator_id"
          t.integer  "updater_id"
          t.integer  "lock_version",                                                                                   default: 0,     null: false
        end

        add_index "production_support_markers", ["created_at"], name: "index_production_support_markers_on_created_at", using: :btree
        add_index "production_support_markers", ["creator_id"], name: "index_production_support_markers_on_creator_id", using: :btree
        add_index "production_support_markers", ["indicator_name"], name: "index_production_support_markers_on_indicator_name", using: :btree
        add_index "production_support_markers", ["support_id"], name: "index_production_support_markers_on_support_id", using: :btree
        add_index "production_support_markers", ["updated_at"], name: "index_production_support_markers_on_updated_at", using: :btree
        add_index "production_support_markers", ["updater_id"], name: "index_production_support_markers_on_updater_id", using: :btree



        create_table "budget_items", force: true do |t|
          t.integer  "budget_id",                                                                null: false
          t.integer  "production_support_id"
          t.decimal  "quantity",                          precision: 19, scale: 4, default: 1.0, null: false
          t.decimal  "global_amount",                     precision: 19, scale: 4, default: 0.0, null: false
          t.string   "currency"
          t.datetime "created_at",                                                               null: false
          t.datetime "updated_at",                                                               null: false
          t.integer  "creator_id"
          t.integer  "updater_id"
          t.integer  "lock_version",                                               default: 0,   null: false
        end

        add_index "budget_items", ["budget_id"], :name => "index_budget_items_on_budget_id"
        add_index "budget_items", ["created_at"], :name => "index_budget_items_on_created_at"
        add_index "budget_items", ["creator_id"], :name => "index_budget_items_on_creator_id"
        add_index "budget_items", ["production_support_id"], :name => "index_budget_items_on_production_support_id"
        add_index "budget_items", ["updated_at"], :name => "index_budget_items_on_updated_at"
        add_index "budget_items", ["updater_id"], :name => "index_budget_items_on_updater_id"

        add_column :productions, :homogeneous_revenues, :boolean, null: false, default: false
        add_column :productions, :homogeneous_expenses, :boolean, null: false, default: false

        add_column :productions, :static_support, :boolean, null: false, default: false
        add_column :production_budgets, :name, :string
        execute "UPDATE production_budgets SET name = v.name FROM product_nature_variants AS v WHERE v.id = variant_id"
        add_column :production_budgets, :homogeneous_values, :boolean, null: false, default: false
      end
    end

  end

end
