class ReplaceLinesWithItems < ActiveRecord::Migration
    @@references = {
    :account => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :account_balance => {
      :account_id => :account,
      :creator_id => :entity,
      :financial_year_id => :financial_year,
      :updater_id => :entity
    },
    :animal => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :area => {
      :creator_id => :entity,
      :district_id => :district,
      :updater_id => :entity
    },
    :asset => {
      :allocation_account_id => :account,
      :charges_account_id => :account,
      :creator_id => :entity,
      :journal_id => :journal,
      :purchase_id => :purchase,
      :purchase_line_id => :purchase_line,
      :sale_id => :sale,
      :sale_line_id => :sale_line,
      :updater_id => :entity
    },
    :asset_depreciation => {
      :asset_id => :asset,
      :creator_id => :entity,
      :financial_year_id => :financial_year,
      :journal_entry_id => :journal_entry,
      :updater_id => :entity
    },
    :bank_statement => {
      :cash_id => :cash,
      :creator_id => :entity,
      :updater_id => :entity
    },
    :bioproduct => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :cash => {
      :account_id => :account,
      :creator_id => :entity,
      :journal_id => :journal,
      :updater_id => :entity
    },
    :cash_transfer => {
      :creator_id => :entity,
      :emitter_cash_id => :cash,
      :emitter_journal_entry_id => :journal_entry,
      :receiver_cash_id => :cash,
      :receiver_journal_entry_id => :journal_entry,
      :updater_id => :entity
    },
    :company => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :cultivation => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :custom_field => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :custom_field_choice => {
      :creator_id => :entity,
      :custom_field_id => :custom_field,
      :updater_id => :entity
    },
    :custom_field_datum => {
      :choice_value_id => :custom_field_choice,
      :creator_id => :entity,
      :custom_field_id => :custom_field,
      :customized_id => "customized_type",
      :updater_id => :entity
    },
    :affair => {
      :creator_id => :entity,
      :journal_entry_id => :journal_entry,
      :origin_id => "origin_type",
      :updater_id => :entity
    },
    :delay => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :department => {
      :creator_id => :entity,
      :parent_id => :department,
      :updater_id => :entity
    },
    :deposit => {
      :cash_id => :cash,
      :creator_id => :entity,
      :journal_entry_id => :journal_entry,
      :mode_id => :incoming_payment_mode,
      :responsible_id => :entity,
      :updater_id => :entity
    },
    :deposit_line => {
      :creator_id => :entity,
      :deposit_id => :deposit,
      :updater_id => :entity
    },
    :district => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :document => {
      :creator_id => :entity,
      :owner_id => "owner_type",
      :template_id => :document_template,
      :updater_id => :entity
    },
    :document_template => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :entity => {
      :attorney_account_id => :account,
      :category_id => :entity_category,
      :client_account_id => :account,
      :creator_id => :entity,
      :department_id => :department,
      :establishment_id => :establishment,
      :nature_id => :entity_nature,
      :payment_delay_id => :delay,
      :payment_mode_id => :incoming_payment_mode,
      :profession_id => :profession,
      :proposer_id => :entity,
      :responsible_id => :entity,
      :role_id => :role,
      :supplier_account_id => :account,
      :updater_id => :entity
    },
    :entity_address => {
      :creator_id => :entity,
      :entity_id => :entity,
      :mail_area_id => :area,
      :updater_id => :entity
    },
    :entity_category => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :entity_link => {
      :creator_id => :entity,
      :entity_1_id => :entity,
      :entity_2_id => :entity,
      :nature_id => :entity_link_nature,
      :updater_id => :entity
    },
    :entity_link_nature => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :entity_nature => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :establishment => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :event => {
      :creator_id => :entity,
      :entity_id => :entity,
      :nature_id => :event_nature,
      :responsible_id => :entity,
      :updater_id => :entity
    },
    :event_nature => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :financial_year => {
      :creator_id => :entity,
      :last_journal_entry_id => :journal_entry,
      :updater_id => :entity
    },
    :fungus => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :incoming_delivery => {
      :address_id => :entity_address,
      :creator_id => :entity,
      :mode_id => :incoming_delivery_mode,
      :purchase_id => :purchase,
      :updater_id => :entity
    },
    :incoming_delivery_line => {
      :creator_id => :entity,
      :delivery_id => :incoming_delivery,
      :price_id => :price,
      :product_id => :product,
      :purchase_line_id => :purchase_line,
      :stock_id => :product_stock,
      :stock_move_id => :product_move,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
    },
    :incoming_delivery_mode => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :incoming_payment => {
      :commission_account_id => :account,
      :creator_id => :entity,
      :affair_id => :affair,
      :deposit_id => :deposit,
      :journal_entry_id => :journal_entry,
      :mode_id => :incoming_payment_mode,
      :payer_id => :entity,
      :responsible_id => :entity,
      :updater_id => :entity
    },
    :incoming_payment_mode => {
      :attorney_journal_id => :journal,
      :cash_id => :cash,
      :commission_account_id => :account,
      :creator_id => :entity,
      :depositables_account_id => :account,
      :depositables_journal_id => :journal,
      :updater_id => :entity
    },
    :inventory => {
      :creator_id => :entity,
      :journal_entry_id => :journal_entry,
      :responsible_id => :entity,
      :updater_id => :entity
    },
    :inventory_line => {
      :creator_id => :entity,
      :inventory_id => :inventory,
      :product_id => :product,
      :stock_id => :stock,
      :stock_move_id => :product_move,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
    },
    :journal => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :journal_entry => {
      :creator_id => :entity,
      :financial_year_id => :financial_year,
      :journal_id => :journal,
      :resource_id => "resource_type",
      :updater_id => :entity
    },
    :journal_entry_line => {
      :account_id => :account,
      :bank_statement_id => :bank_statement,
      :creator_id => :entity,
      :entry_id => :journal_entry,
      :journal_id => :journal,
      :updater_id => :entity
    },
    :land_parcel => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :land_parcel_kinship => {
      :child_land_parcel_id => :land_parcel,
      :creator_id => :entity,
      :parent_land_parcel_id => :land_parcel,
      :updater_id => :entity
    },
    :listing => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :listing_node => {
      :creator_id => :entity,
      :item_listing_id => :listing,
      :item_listing_node_id => :listing_node,
      :listing_id => :listing,
      :parent_id => :listing_node,
      :updater_id => :entity
    },
    :listing_node_item => {
      :creator_id => :entity,
      :node_id => :listing_node,
      :updater_id => :entity
    },
    :log => {
      :creator_id => :entity,
      :origin_id => "origin_type",
      :owner_id => "owner_type",
      :updater_id => :entity
    },
    :mandate => {
      :creator_id => :entity,
      :entity_id => :entity,
      :updater_id => :entity
    },
    :matter => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :observation => {
      :creator_id => :entity,
      :entity_id => :entity,
      :updater_id => :entity
    },
    :operation => {
      :creator_id => :entity,
      :nature_id => :operation_nature,
      :production_chain_work_center_id => :production_chain_work_center,
      :responsible_id => :entity,
      :updater_id => :entity
    },
    :operation_nature => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :operation_use => {
      :creator_id => :entity,
      :operation_id => :operation,
      :tool_id => :tool,
      :updater_id => :entity
    },
    :outgoing_delivery => {
      :address_id => :entity_address,
      :creator_id => :entity,
      :mode_id => :outgoing_delivery_mode,
      :sale_id => :sale,
      :transport_id => :transport,
      :transporter_id => :entity,
      :updater_id => :entity
    },
    :outgoing_delivery_line => {
      :creator_id => :entity,
      :delivery_id => :outgoing_delivery,
      :price_id => :price,
      :product_id => :product,
      :sale_line_id => :sale_line,
      :stock_id => :stock,
      :stock_move_id => :product_move,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
    },
    :outgoing_delivery_mode => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :outgoing_payment => {
      :creator_id => :entity,
      :affair_id => :affair,
      :journal_entry_id => :journal_entry,
      :mode_id => :outgoing_payment_mode,
      :payee_id => :entity,
      :responsible_id => :entity,
      :updater_id => :entity
    },
    :outgoing_payment_mode => {
      :attorney_journal_id => :journal,
      :cash_id => :cash,
      :creator_id => :entity,
      :updater_id => :entity
    },
    :place => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :preference => {
      :creator_id => :entity,
      :record_value_id => "record_value_type",
      :updater_id => :entity,
      :user_id => :entity
    },
    :price => {
      :category_id => :entity_category,
      :creator_id => :entity,
      :entity_id => :entity,
      :product_nature_id => :product_nature,
      :tax_id => :tax,
      :updater_id => :entity
    },
    :product => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :tracking_id => :tracking,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :product_group => {
      :creator_id => :entity,
      :parent_id => :product_group,
      :updater_id => :entity
    },
    :product_indicator => {
      :choice_value_id => :product_indicator_nature_choice,
      :creator_id => :entity,
      :measure_unit_id => :unit,
      :nature_id => :product_indicator_nature,
      :product_id => :product,
      :updater_id => :entity
    },
    :product_indicator_nature => {
      :creator_id => :entity,
      :process_id => :product_process,
      :unit_id => :unit,
      :updater_id => :entity
    },
    :product_indicator_nature_choice => {
      :creator_id => :entity,
      :nature_id => :product_indicator_nature,
      :updater_id => :entity
    },
    :product_membership => {
      :creator_id => :entity,
      :group_id => :product_group,
      :product_id => :product,
      :updater_id => :entity
    },
    :product_nature => {
      :asset_account_id => :account,
      :category_id => :product_nature_category,
      :charge_account_id => :account,
      :creator_id => :entity,
      :product_account_id => :account,
      :subscription_nature_id => :subscription_nature,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :product_nature_category => {
      :creator_id => :entity,
      :parent_id => :product_nature_category,
      :updater_id => :entity
    },
    :product_nature_component => {
      :component_id => :product_nature,
      :creator_id => :entity,
      :product_nature_id => :product_nature,
      :updater_id => :entity
    },
    :product_process => {
      :creator_id => :entity,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :product_process_phase => {
      :creator_id => :entity,
      :process_id => :product_process,
      :updater_id => :entity
    },
    :product_move => {
      :creator_id => :entity,
      :origin_id => "origin_type",
      :product_id => :product,
      :unit_id => :unit,
      :updater_id => :entity,
    },
    :product_transfer => {
      :origin => :place,
      :creator_id => :entity,
      :destination_id => :place,
      :product_id => :product,
      :updater_id => :entity
    },
    :product_localization => {
      :container_id => :place,
      :creator_id => :entity,
      :product_id => :product,
      :updater_id => :entity
    },
    :product_variety => {
      :creator_id => :entity,
      :parent_id => :product_variety,
      :updater_id => :entity
    },
    :production_chain => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :production_chain_conveyor => {
      :creator_id => :entity,
      :product_nature_id => :product_nature,
      :production_chain_id => :production_chain,
      :source_id => :production_chain_work_center,
      :target_id => :production_chain_work_center,
      :unit_id => :unit,
      :updater_id => :entity
    },
    :production_chain_work_center => {
      :building_id => :warehouse,
      :creator_id => :entity,
      :operation_nature_id => :operation_nature,
      :production_chain_id => :production_chain,
      :updater_id => :entity
    },
    :production_chain_work_center_use => {
      :creator_id => :entity,
      :tool_id => :tool,
      :updater_id => :entity,
      :work_center_id => :production_chain_work_center
    },
    :profession => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :purchase => {
      :creator_id => :entity,
      :affair_id => :affair,
      :delivery_address_id => :entity_address,
      :journal_entry_id => :journal_entry,
      :nature_id => :purchase_nature,
      :responsible_id => :entity,
      :supplier_id => :entity,
      :updater_id => :entity
    },
    :purchase_line => {
      :account_id => :account,
      :creator_id => :entity,
      :price_id => :price,
      :product_id => :product,
      :purchase_id => :purchase,
      :stock_id => :stock,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
    },
    :purchase_nature => {
      :creator_id => :entity,
      :journal_id => :journal,
      :updater_id => :entity
    },
    :role => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :sale => {
      :address_id => :entity_address,
      :client_id => :entity,
      :creator_id => :entity,
      :affair_id => :affair,
      :delivery_address_id => :entity_address,
      :expiration_id => :delay,
      :invoice_address_id => :entity_address,
      :journal_entry_id => :journal_entry,
      :nature_id => :sale_nature,
      :origin_id => :sale,
      :payment_delay_id => :delay,
      :responsible_id => :entity,
      :transporter_id => :entity,
      :updater_id => :entity
    },
    :sale_line => {
      :account_id => :account,
      :creator_id => :entity,
      :entity_id => :entity,
      :origin_id => :sale_line,
      :price_id => :price,
      :product_id => :product,
      :reduction_origin_id => :sale_line,
      :sale_id => :sale,
      :stock_id => :stock,
      :tax_id => :tax,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
    },
    :sale_nature => {
      :creator_id => :entity,
      :expiration_id => :delay,
      :journal_id => :journal,
      :payment_delay_id => :delay,
      :payment_mode_id => :incoming_payment_mode,
      :updater_id => :entity
    },
    :sequence => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :service => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :subscription => {
      :address_id => :entity_address,
      :creator_id => :entity,
      :entity_id => :entity,
      :nature_id => :subscription_nature,
      :product_nature_id => :product_nature,
      :sale_id => :sale,
      :sale_line_id => :sale_line,
      :updater_id => :entity
    },
    :subscription_nature => {
      :creator_id => :entity,
      :entity_link_nature_id => :entity_link_nature,
      :updater_id => :entity
    },
    :tax => {
      :collected_account_id => :account,
      :creator_id => :entity,
      :paid_account_id => :account,
      :updater_id => :entity
    },
    :tax_declaration => {
      :creator_id => :entity,
      :financial_year_id => :financial_year,
      :journal_entry_id => :journal_entry,
      :updater_id => :entity
    },
    :tool => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :transfer => {
      :creator_id => :entity,
      :affair_id => :affair,
      :journal_entry_id => :journal_entry,
      :supplier_id => :entity,
      :updater_id => :entity
    },
    :transport => {
      :creator_id => :entity,
      :purchase_id => :purchase,
      :responsible_id => :entity,
      :transporter_id => :entity,
      :updater_id => :entity
    },
    :unit => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :vegetal => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    },
    :warehouse => {
      :address_id => :entity_address,
      :area_unit_id => :unit_id,
      :asset_id => :asset,
      :content_nature_id => :product_nature,
      :content_unit_id => :unit_id,
      :creator_id => :entity,
      :father_id => :product,
      :mother_id => :product,
      :nature_id => :product_nature,
      :owner_id => :entity_id,
      :parent_warehouse_id => :warehouse,
      :producer_id => :entity,
      :unit_id => :unit,
      :updater_id => :entity,
      :variety_id => :product_variety
    }
  }

  # Returns tables
  def references_of(table)
    model = table.to_s.singularize.to_sym
    return @@references.inject({}) do |hash, pair|
      referencer = pair[0].to_s.pluralize.to_sym
      hash[referencer] ||= {}
      for k, v in pair[1]
        if v == model or v.is_a?(String)
          hash[referencer][k] = v
        end
      end
      hash
    end
  end

  def rename_table_and_ref(old_table, new_table)
    rename_table old_table, new_table
    old_model = old_table.to_s.singularize.to_sym
    new_model = new_table.to_s.singularize.to_sym
    @@references[new_model] = @@references[old_model]
    @@references.delete(old_model)
    for model, links in @@references
      for foreign_key, foreign_model in links
        if foreign_model == old_model
          @@references[model][foreign_key] = new_model
        end
      end
    end
  end


  def rename_table_and_indexes(old_table, new_table)
    rename_table_and_ref(old_table, new_table)
    # Updates indexes names
    for index in indexes(new_table)
      rename_index new_table, index.name.to_sym, ("index_#{new_table}_on_" + index.columns.join("_and_")).to_sym
    end
  end

  def rename_table_and_co(old_table, new_table)
    rename_table_and_indexes(old_table, new_table)
    # Updates foreign columns
    for table, columns in references_of(new_table)
      for column, target in columns
        if target.is_a?(String)
          execute("UPDATE #{quoted_table_name(table)} SET #{target} = '#{new_table.to_s.classify}' WHERE #{target} = '#{old_table.to_s.classify}'")
        elsif column.to_s.match(/(^|\_)#{old_table.to_s.singularize + '_id'}$/)
          rename_column table, column, column.to_s.gsub(/(^|\_)#{old_table.to_s.singularize + '_id'}$/, '\1' + new_table.to_s.singularize + '_id').to_sym
        else
          say("No logic way to rename #{table}##{column} for #{new_table}")
        end
      end
    end
  end

  def change
    rename_table_and_co :deposit_lines, :deposit_items
    rename_table_and_co :incoming_delivery_lines, :incoming_delivery_items
    rename_table_and_co :inventory_lines, :inventory_items
    rename_table_and_co :journal_entry_lines, :journal_entry_items
    rename_table_and_co :outgoing_delivery_lines, :outgoing_delivery_items
    rename_table_and_co :purchase_lines, :purchase_items
    rename_table_and_co :sale_lines, :sale_items
  end
end
