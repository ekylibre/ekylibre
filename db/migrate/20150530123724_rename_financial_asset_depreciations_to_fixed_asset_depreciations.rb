class RenameFinancialAssetDepreciationsToFixedAssetDepreciations < ActiveRecord::Migration
  def change
    rename_table :financial_asset_depreciations, :fixed_asset_depreciations
    # Polymorphic columns
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:resource_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:ressource_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:target_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:resource_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:subject_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:record_value_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FinancialAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:item_type)}='FinancialAssetDepreciation'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:attachments)} SET #{quote_column_name(:resource_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:resource_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:interventions)} SET #{quote_column_name(:ressource_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:ressource_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:issues)} SET #{quote_column_name(:target_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:target_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:journal_entries)} SET #{quote_column_name(:resource_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:resource_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:observations)} SET #{quote_column_name(:subject_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:subject_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:preferences)} SET #{quote_column_name(:record_value_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:record_value_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_enjoyments)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_junctions)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_linkages)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_links)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_localizations)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_memberships)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_ownerships)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_phases)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_reading_tasks)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:product_readings)} SET #{quote_column_name(:originator_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:originator_type)}='FixedAssetDepreciation'"
        execute "UPDATE #{quote_table_name(:versions)} SET #{quote_column_name(:item_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:item_type)}='FixedAssetDepreciation'"
      end
    end
    # Custom fields
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='FixedAssetDepreciation' WHERE #{quote_column_name(:customized_type)}='FinancialAssetDepreciation'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:custom_fields)} SET #{quote_column_name(:customized_type)}='FinancialAssetDepreciation' WHERE #{quote_column_name(:customized_type)}='FixedAssetDepreciation'"
      end
    end
    # Listings
    reversible do |dir|
      dir.up do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='fixed_asset_depreciation' WHERE #{quote_column_name(:root_model)}='financial_asset_depreciation'"
      end
      dir.down do
        execute "UPDATE #{quote_table_name(:listings)} SET #{quote_column_name(:root_model)}='financial_asset_depreciation' WHERE #{quote_column_name(:root_model)}='fixed_asset_depreciation'"
      end
    end

    # Add your specific code here...
  end
end
