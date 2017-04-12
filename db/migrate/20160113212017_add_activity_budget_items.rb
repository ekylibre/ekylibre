class AddActivityBudgetItems < ActiveRecord::Migration
  def change
    rename_table :activity_budgets, :activity_budget_items
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='ActivityBudgetItem' WHERE #{quote_column_name(:type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:resource_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:intervention_parameters)} SET #{quote_column_name(:type)}='ActivityBudgetItem' WHERE #{quote_column_name(:type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:target_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:resource_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:notifications)} SET #{quote_column_name(:target_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:target_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:subject_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:record_value_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_movements)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:originator_type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='ActivityBudgetItem' WHERE #{quote_column_name(:type)}='ActivityBudget'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:item_type)}='ActivityBudget'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:affairs)} SET #{quote_column_name(:type)}='ActivityBudget' WHERE #{quote_column_name(:type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='ActivityBudget' WHERE #{quote_column_name(:resource_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:intervention_parameters)} SET #{quote_column_name(:type)}='ActivityBudget' WHERE #{quote_column_name(:type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='ActivityBudget' WHERE #{quote_column_name(:target_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='ActivityBudget' WHERE #{quote_column_name(:resource_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:notifications)} SET #{quote_column_name(:target_type)}='ActivityBudget' WHERE #{quote_column_name(:target_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='ActivityBudget' WHERE #{quote_column_name(:subject_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='ActivityBudget' WHERE #{quote_column_name(:record_value_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_movements)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='ActivityBudget' WHERE #{quote_column_name(:originator_type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:products)} SET #{quote_column_name(:type)}='ActivityBudget' WHERE #{quote_column_name(:type)}='ActivityBudgetItem'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='ActivityBudget' WHERE #{quote_column_name(:item_type)}='ActivityBudgetItem'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='ActivityBudgetItem' WHERE #{quote_column_name(:customized_type)}='ActivityBudget'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='ActivityBudget' WHERE #{quote_column_name(:customized_type)}='ActivityBudgetItem'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='activity_budget_item' WHERE #{quote_column_name(:root_model)}='activity_budget'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='activity_budget' WHERE #{quote_column_name(:root_model)}='activity_budget_item'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='activity_budget_items' WHERE #{quote_column_name(:usage)}='activity_budgets'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='activity_budgets' WHERE #{quote_column_name(:usage)}='activity_budget_items'"
      end
    end

    create_table :activity_budgets do |t|
      t.references :activity, null: false, index: true
      t.references :campaign, null: false, index: true
      t.string :currency, null: false
      t.stamps
    end
    add_index :activity_budgets, %i[activity_id campaign_id], unique: true

    add_reference :activity_budget_items, :activity_budget, index: true

    reversible do |dir|
      dir.up do
        currency = select_value "SELECT string_value FROM preferences WHERE name = 'currency'"
        currency = 'EUR' if currency.blank?
        execute "INSERT INTO activity_budgets (activity_id, campaign_id, currency, created_at, updated_at) SELECT DISTINCT i.activity_id, i.campaign_id, '#{currency}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM activity_budget_items AS i"
        execute 'UPDATE activity_budget_items SET activity_budget_id = b.id FROM activity_budgets AS b WHERE activity_budget_items.activity_id = b.activity_id AND activity_budget_items.campaign_id = b.campaign_id'
      end
      dir.down do
        execute 'UPDATE activity_budget_items SET activity_id = b.activity_id AND campaign_id = b.campaign_id FROM activity_budgets AS b WHERE activity_budget_id = b.id'
      end
    end

    change_column_null :activity_budget_items, :activity_budget_id, false

    revert do
      add_reference :activity_budget_items, :activity, index: true
      add_reference :activity_budget_items, :campaign, index: true
    end
  end
end
