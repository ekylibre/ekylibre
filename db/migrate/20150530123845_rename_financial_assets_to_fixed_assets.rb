class RenameFinancialAssetsToFixedAssets < ActiveRecord::Migration

  def change
    rename_table :financial_assets, :fixed_assets
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='FixedAsset' WHERE #{quote_column_name(:resource_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='FixedAsset' WHERE #{quote_column_name(:ressource_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='FixedAsset' WHERE #{quote_column_name(:target_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='FixedAsset' WHERE #{quote_column_name(:resource_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='FixedAsset' WHERE #{quote_column_name(:subject_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='FixedAsset' WHERE #{quote_column_name(:record_value_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='FixedAsset' WHERE #{quote_column_name(:originator_type)}='FinancialAsset'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='FixedAsset' WHERE #{quote_column_name(:item_type)}='FinancialAsset'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='FinancialAsset' WHERE #{quote_column_name(:resource_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='FinancialAsset' WHERE #{quote_column_name(:ressource_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='FinancialAsset' WHERE #{quote_column_name(:target_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='FinancialAsset' WHERE #{quote_column_name(:resource_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='FinancialAsset' WHERE #{quote_column_name(:subject_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='FinancialAsset' WHERE #{quote_column_name(:record_value_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='FinancialAsset' WHERE #{quote_column_name(:originator_type)}='FixedAsset'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='FinancialAsset' WHERE #{quote_column_name(:item_type)}='FixedAsset'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='FixedAsset' WHERE #{quote_column_name(:customized_type)}='FinancialAsset'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='FinancialAsset' WHERE #{quote_column_name(:customized_type)}='FixedAsset'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='fixed_asset' WHERE #{quote_column_name(:root_model)}='financial_asset'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='financial_asset' WHERE #{quote_column_name(:root_model)}='fixed_asset'"
      end
    end
    # Sequences
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='fixed_assets' WHERE #{quote_column_name(:usage)}='financial_assets'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:sequences)} SET #{quote_column_name(:usage)}='financial_assets' WHERE #{quote_column_name(:usage)}='fixed_assets'"
      end
    end

    rename_column :fixed_asset_depreciations, :financial_asset_id, :fixed_asset_id

    rename_column :products, :financial_asset_id, :fixed_asset_id

    rename_column :product_nature_categories, :financial_asset_account_id,              :fixed_asset_account_id
    rename_column :product_nature_categories, :financial_asset_allocation_account_id,   :fixed_asset_allocation_account_id
    rename_column :product_nature_categories, :financial_asset_depreciation_method,     :fixed_asset_depreciation_method
    rename_column :product_nature_categories, :financial_asset_depreciation_percentage, :fixed_asset_depreciation_percentage
    rename_column :product_nature_categories, :financial_asset_expenses_account_id,     :fixed_asset_expenses_account_id
  end

end
