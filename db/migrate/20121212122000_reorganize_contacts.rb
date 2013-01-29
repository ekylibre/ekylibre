# -*- coding: utf-8 -*-
class ReorganizeContacts < ActiveRecord::Migration
  REFERENCES = {
    :account => {
      :creator_id => :user,
      :updater_id => :user
    },
    :account_balance => {
      :account_id => :account,
      :creator_id => :user,
      :financial_year_id => :financial_year,
      :updater_id => :user
    },
    :animal => {
      :creator_id => :user,
      :father_id => :animal,
      :group_id => :animal_group,
      :mother_id => :animal,
      :race_id => :animal_race,
      :updater_id => :user
    },
    :animal_event => {
      :animal_group_id => :animal_group,
      :animal_id => :animal,
      :creator_id => :user,
      :nature_id => :animal_event_nature,
      :treatment_id => :animal_treatment,
      :updater_id => :user,
      :watcher_id => :entity
    },
    :animal_event_nature => {
      :creator_id => :user,
      :updater_id => :user
    },
    :animal_group => {
      :creator_id => :user,
      :updater_id => :user
    },
    :animal_race => {
      :creator_id => :user,
      :nature_id => :animal_race_nature,
      :updater_id => :user
    },
    :animal_race_nature => {
      :creator_id => :user,
      :updater_id => :user
    },
    :animal_treatment => {
      :creator_id => :user,
      :disease_id => :disease,
      :drug_id => :drug,
      :prescriptor_id => :entity,
      :unit_id => :unit,
      :updater_id => :user
    },
    :area => {
      :creator_id => :user,
      :district_id => :district,
      :updater_id => :user
    },
    :asset => {
      :allocation_account_id => :account,
      :charges_account_id => :account,
      :creator_id => :user,
      :journal_id => :journal,
      :purchase_id => :purchase,
      :purchase_line_id => :purchase_line,
      :sale_id => :sale,
      :sale_line_id => :sale_line,
      :updater_id => :user
    },
    :asset_depreciation => {
      :asset_id => :asset,
      :creator_id => :user,
      :financial_year_id => :financial_year,
      :journal_entry_id => :journal_entry,
      :updater_id => :user
    },
    :bank_statement => {
      :cash_id => :cash,
      :creator_id => :user,
      :updater_id => :user
    },
    :cash => {
      :account_id => :account,
      :creator_id => :user,
      :entity_id => :entity,
      :journal_id => :journal,
      :updater_id => :user
    },
    :cash_transfer => {
      :creator_id => :user,
      :emitter_cash_id => :cash,
      :emitter_journal_entry_id => :journal_entry,
      :receiver_cash_id => :cash,
      :receiver_journal_entry_id => :journal_entry,
      :updater_id => :user
    },
    :company => {

    },
    :contact => {
      :area_id => :area,
      :creator_id => :user,
      :entity_id => :entity,
      :updater_id => :user
    },
    :cultivation => {
      :creator_id => :user,
      :updater_id => :user
    },
    :custom_field => {
      :creator_id => :user,
      :updater_id => :user
    },
    :custom_field_choice => {
      :creator_id => :user,
      :custom_field_id => :custom_field,
      :updater_id => :user
    },
    :custom_field_datum => {
      :choice_value_id => :custom_field_choice,
      :creator_id => :user,
      :custom_field_id => :custom_field,
      :entity_id => :entity,
      :updater_id => :user
    },
    :delay => {
      :creator_id => :user,
      :updater_id => :user
    },
    :department => {
      :creator_id => :user,
      :parent_id => :department,
      :updater_id => :user
    },
    :deposit => {
      :cash_id => :cash,
      :creator_id => :user,
      :journal_entry_id => :journal_entry,
      :mode_id => :incoming_payment_mode,
      :responsible_id => :user,
      :updater_id => :user
    },
    :deposit_line => {
      :creator_id => :user,
      :deposit_id => :deposit,
      :updater_id => :user
    },
    :diagnostic => {
      :creator_id => :user,
      :disease_id => :disease,
      :event_id => :event,
      :updater_id => :user
    },
    :disease => {
      :creator_id => :user,
      :updater_id => :user
    },
    :district => {
      :creator_id => :user,
      :updater_id => :user
    },
    :document => {
      :creator_id => :user,
      :owner_id => "owner_type",
      :template_id => :document_template,
      :updater_id => :user
    },
    :document_template => {
      :creator_id => :user,
      :updater_id => :user
    },
    :drug => {
      :creator_id => :user,
      :nature_id => :drug_nature,
      :unit_id => :unit,
      :updater_id => :user
    },
    :drug_nature => {
      :creator_id => :user,
      :updater_id => :user
    },
    :entity => {
      :attorney_account_id => :account,
      :category_id => :entity_category,
      :client_account_id => :account,
      :creator_id => :user,
      :nature_id => :entity_nature,
      :payment_delay_id => :delay,
      :payment_mode_id => :incoming_payment_mode,
      :proposer_id => :entity,
      :responsible_id => :user,
      :supplier_account_id => :account,
      :updater_id => :user
    },
    :entity_category => {
      :creator_id => :user,
      :updater_id => :user
    },
    :entity_link => {
      :creator_id => :user,
      :entity_1_id => :entity,
      :entity_2_id => :entity,
      :nature_id => :entity_link_nature,
      :updater_id => :user
    },
    :entity_link_nature => {
      :creator_id => :user,
      :updater_id => :user
    },
    :entity_nature => {
      :creator_id => :user,
      :updater_id => :user
    },
    :establishment => {
      :creator_id => :user,
      :updater_id => :user
    },
    :event => {
      :creator_id => :user,
      :entity_id => :entity,
      :nature_id => :event_nature,
      :responsible_id => :user,
      :updater_id => :user
    },
    :event_nature => {
      :creator_id => :user,
      :updater_id => :user
    },
    :financial_year => {
      :creator_id => :user,
      :last_journal_entry_id => :journal_entry,
      :updater_id => :user
    },
    :incoming_delivery => {
      :contact_id => :contact,
      :creator_id => :user,
      :mode_id => :incoming_delivery_mode,
      :purchase_id => :purchase,
      :updater_id => :user
    },
    :incoming_delivery_line => {
      :creator_id => :user,
      :delivery_id => :incoming_delivery,
      :price_id => :price,
      :product_id => :product,
      :purchase_line_id => :purchase_line,
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :incoming_delivery_mode => {
      :creator_id => :user,
      :updater_id => :user
    },
    :incoming_payment => {
      :commission_account_id => :account,
      :creator_id => :user,
      :deposit_id => :deposit,
      :journal_entry_id => :journal_entry,
      :mode_id => :incoming_payment_mode,
      :payer_id => :entity,
      :responsible_id => :user,
      :updater_id => :user
    },
    :incoming_payment_mode => {
      :attorney_journal_id => :journal,
      :cash_id => :cash,
      :commission_account_id => :account,
      :creator_id => :user,
      :depositables_account_id => :account,
      :depositables_journal_id => :journal,
      :updater_id => :user
    },
    :incoming_payment_use => {
      :creator_id => :user,
      :expense_id => "expense_type",
      :journal_entry_id => :journal_entry,
      :payment_id => :incoming_payment,
      :updater_id => :user
    },
    :inventory => {
      :creator_id => :user,
      :journal_entry_id => :journal_entry,
      :responsible_id => :user,
      :updater_id => :user
    },
    :inventory_line => {
      :creator_id => :user,
      :inventory_id => :inventory,
      :product_id => :product,
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :journal => {
      :creator_id => :user,
      :updater_id => :user
    },
    :journal_entry => {
      :creator_id => :user,
      :financial_year_id => :financial_year,
      :journal_id => :journal,
      :resource_id => "resource_type",
      :updater_id => :user
    },
    :journal_entry_line => {
      :account_id => :account,
      :bank_statement_id => :bank_statement,
      :creator_id => :user,
      :entry_id => :journal_entry,
      :journal_id => :journal,
      :updater_id => :user
    },
    :land_parcel => {
      :area_unit_id => :unit,
      :creator_id => :user,
      :group_id => :land_parcel_group,
      :updater_id => :user
    },
    :land_parcel_group => {
      :creator_id => :user,
      :updater_id => :user
    },
    :land_parcel_kinship => {
      :child_land_parcel_id => :land_parcel,
      :creator_id => :user,
      :parent_land_parcel_id => :land_parcel,
      :updater_id => :user
    },
    :listing => {
      :creator_id => :user,
      :updater_id => :user
    },
    :listing_node => {
      :creator_id => :user,
      :item_listing_id => :listing,
      :item_listing_node_id => :listing_node,
      :listing_id => :listing,
      :parent_id => :listing_node,
      :updater_id => :user
    },
    :listing_node_item => {
      :creator_id => :user,
      :node_id => :listing_node,
      :updater_id => :user
    },
    :mandate => {
      :creator_id => :user,
      :entity_id => :entity,
      :updater_id => :user
    },
    :observation => {
      :creator_id => :user,
      :entity_id => :entity,
      :updater_id => :user
    },
    :operation => {
      :creator_id => :user,
      :nature_id => :operation_nature,
      :production_chain_work_center_id => :production_chain_work_center,
      :responsible_id => :user,
      :target_id => "target_type",
      :updater_id => :user
    },
    :operation_line => {
      :area_unit_id => :unit,
      :creator_id => :user,
      :operation_id => :operation,
      :product_id => :product,
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :operation_nature => {
      :creator_id => :user,
      :updater_id => :user
    },
    :operation_use => {
      :creator_id => :user,
      :operation_id => :operation,
      :tool_id => :tool,
      :updater_id => :user
    },
    :outgoing_delivery => {
      :contact_id => :contact,
      :creator_id => :user,
      :mode_id => :outgoing_delivery_mode,
      :sale_id => :sale,
      :transport_id => :transport,
      :transporter_id => :entity,
      :updater_id => :user
    },
    :outgoing_delivery_line => {
      :creator_id => :user,
      :delivery_id => :outgoing_delivery,
      :price_id => :price,
      :product_id => :product,
      :sale_line_id => :sale_line,
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :outgoing_delivery_mode => {
      :creator_id => :user,
      :updater_id => :user
    },
    :outgoing_payment => {
      :creator_id => :user,
      :journal_entry_id => :journal_entry,
      :mode_id => :outgoing_payment_mode,
      :payee_id => :entity,
      :responsible_id => :user,
      :updater_id => :user
    },
    :outgoing_payment_mode => {
      :attorney_journal_id => :journal,
      :cash_id => :cash,
      :creator_id => :user,
      :updater_id => :user
    },
    :outgoing_payment_use => {
      :creator_id => :user,
      :expense_id => :purchase,
      :journal_entry_id => :journal_entry,
      :payment_id => :outgoing_payment,
      :updater_id => :user
    },
    :preference => {
      :creator_id => :user,
      :record_value_id => "record_value_type",
      :updater_id => :user,
      :user_id => :user
    },
    :price => {
      :category_id => :entity_category,
      :creator_id => :user,
      :entity_id => :entity,
      :product_id => :product,
      :tax_id => :tax,
      :updater_id => :user
    },
    :product => {
      :category_id => :product_category,
      :creator_id => :user,
      :immobilizations_account_id => :account,
      :purchases_account_id => :account,
      :sales_account_id => :account,
      :subscription_nature_id => :subscription_nature,
      :unit_id => :unit,
      :updater_id => :user
    },
    :product_category => {
      :creator_id => :user,
      :parent_id => :product_category,
      :updater_id => :user
    },
    :product_component => {
      :component_id => :product_component,
      :creator_id => :user,
      :product_id => :product,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :production_chain => {
      :creator_id => :user,
      :updater_id => :user
    },
    :production_chain_conveyor => {
      :creator_id => :user,
      :product_id => :product,
      :production_chain_id => :production_chain,
      :source_id => :production_chain_work_center,
      :target_id => :production_chain_work_center,
      :unit_id => :unit,
      :updater_id => :user
    },
    :production_chain_work_center => {
      :building_id => :warehouse,
      :creator_id => :user,
      :operation_nature_id => :operation_nature,
      :production_chain_id => :production_chain,
      :updater_id => :user
    },
    :production_chain_work_center_use => {
      :creator_id => :user,
      :tool_id => :tool,
      :updater_id => :user,
      :work_center_id => :production_chain_work_center
    },
    :profession => {
      :creator_id => :user,
      :updater_id => :user
    },
    :purchase => {
      :creator_id => :user,
      :delivery_contact_id => :contact,
      :journal_entry_id => :journal_entry,
      :nature_id => :purchase_nature,
      :responsible_id => :user,
      :supplier_id => :entity,
      :updater_id => :user
    },
    :purchase_line => {
      :account_id => :account,
      :creator_id => :user,
      :price_id => :price,
      :product_id => :product,
      :purchase_id => :purchase,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :purchase_nature => {
      :creator_id => :user,
      :journal_id => :journal,
      :updater_id => :user
    },
    :role => {
      :creator_id => :user,
      :updater_id => :user
    },
    :sale => {
      :client_id => :entity,
      :contact_id => :contact,
      :creator_id => :user,
      :delivery_contact_id => :contact,
      :expiration_id => :delay,
      :invoice_contact_id => :contact,
      :journal_entry_id => :journal_entry,
      :nature_id => :sale_nature,
      :origin_id => :sale,
      :payment_delay_id => :delay,
      :responsible_id => :user,
      :transporter_id => :entity,
      :updater_id => :user
    },
    :sale_line => {
      :account_id => :account,
      :creator_id => :user,
      :entity_id => :entity,
      :origin_id => :sale_line,
      :price_id => :price,
      :product_id => :product,
      :reduction_origin_id => :sale_line,
      :sale_id => :sale,
      :tax_id => :tax,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :sale_nature => {
      :creator_id => :user,
      :expiration_id => :delay,
      :journal_id => :journal,
      :payment_delay_id => :delay,
      :payment_mode_id => :incoming_payment_mode,
      :updater_id => :user
    },
    :sequence => {
      :creator_id => :user,
      :updater_id => :user
    },
    :stock => {
      :creator_id => :user,
      :product_id => :product,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :stock_move => {
      :creator_id => :user,
      :origin_id => "origin_type",
      :product_id => :product,
      :stock_id => :stock,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :stock_transfer => {
      :creator_id => :user,
      :product_id => :product,
      :second_stock_move_id => :stock_move,
      :second_warehouse_id => :warehouse,
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :user,
      :warehouse_id => :warehouse
    },
    :subscription => {
      :contact_id => :contact,
      :creator_id => :user,
      :entity_id => :entity,
      :nature_id => :subscription_nature,
      :product_id => :product,
      :sale_id => :sale,
      :sale_line_id => :sale_line,
      :updater_id => :user
    },
    :subscription_nature => {
      :creator_id => :user,
      :entity_link_nature_id => :entity_link_nature,
      :updater_id => :user
    },
    :tax => {
      :collected_account_id => :account,
      :creator_id => :user,
      :paid_account_id => :account,
      :updater_id => :user
    },
    :tax_declaration => {
      :creator_id => :user,
      :financial_year_id => :financial_year,
      :journal_entry_id => :journal_entry,
      :updater_id => :user
    },
    :tool => {
      :asset_id => :asset,
      :creator_id => :user,
      :nature_id => :tool_nature,
      :updater_id => :user
    },
    :tool_nature => {
      :creator_id => :user,
      :updater_id => :user
    },
    :tracking => {
      :creator_id => :user,
      :producer_id => :entity,
      :product_id => :product,
      :updater_id => :user
    },
    :tracking_state => {
      :creator_id => :user,
      :production_chain_conveyor_id => :production_chain_conveyor,
      :responsible_id => :user,
      :tracking_id => :tracking,
      :updater_id => :user
    },
    :transfer => {
      :creator_id => :user,
      :journal_entry_id => :journal_entry,
      :supplier_id => :entity,
      :updater_id => :user
    },
    :transport => {
      :creator_id => :user,
      :purchase_id => :purchase,
      :responsible_id => :user,
      :transporter_id => :entity,
      :updater_id => :user
    },
    :unit => {
      :creator_id => :user,
      :updater_id => :user
    },
    :user => {
      :creator_id => :user,
      :department_id => :department,
      :establishment_id => :establishment,
      :profession_id => :profession,
      :role_id => :role,
      :updater_id => :user
    },
    :warehouse => {
      :contact_id => :contact,
      :creator_id => :user,
      :establishment_id => :establishment,
      :parent_id => :warehouse,
      :product_id => :product,
      :unit_id => :unit,
      :updater_id => :user
    }
  }


  RENAMINGS = {:contacts => :entity_addresses}

  USER_TABLES = REFERENCES.inject({}) do |hash, ts|
    t, fkeys = ts[0].to_s.pluralize.to_sym, ts[1].collect{|k,v| (v == :user ? k : nil)}.compact
    hash[RENAMINGS[t]||t] = fkeys if fkeys.size > 0
    hash
  end.freeze

  CONTACT_TABLES = REFERENCES.inject({}) do |hash, ts|
    t, fkeys = ts[0].to_s.pluralize.to_sym, ts[1].collect{|k,v| (v == :contact ? k : nil)}.compact
    hash[RENAMINGS[t]||t] = fkeys if fkeys.size > 0
    hash
  end.freeze

  def up
    rename_table :contacts, :entity_addresses
    change_table :entity_addresses do |t|
      t.string :canal, :limit => 16
      t.string :coordinate, :limit => 511
      t.string  :name
      t.string  :mail_line_1
      t.point   :mail_geolocation, :geometric => true
      t.boolean :mail_auto_update, :null => false, :default => false
      t.rename  :area_id, :mail_area_id
      t.rename  :country, :mail_country
      (2..6).each do |i|
        t.rename "line_#{i}".to_sym, "mail_line_#{i}".to_sym
        t.change "mail_line_#{i}".to_sym, :string, :limit => 255
      end
      t.remove :latitude
      t.remove :longitude
      t.remove :address
    end
    execute("DELETE FROM #{quoted_table_name(:entity_addresses)} WHERE entity_id NOT IN (SELECT id FROM #{quoted_table_name(:entities)})")
    execute("UPDATE #{quoted_table_name(:entity_addresses)} SET canal = 'mail', mail_auto_update = TRUE, mail_line_1 = e.full_name, coordinate = TRIM(e.full_name)" + (2..6).collect{|i| " || COALESCE(',' || mail_line_#{i}, '')"}.join + " FROM entities AS e WHERE e.id = entity_id AND e.full_name IS NOT NULL")
    change_column_null :entity_addresses, :canal, false
    change_column_null :entity_addresses, :coordinate, false
    for canal in [:fax, :phone, :email, :mobile, :website]
      execute("INSERT INTO #{quoted_table_name(:entity_addresses)} (entity_id, canal, coordinate, code, created_at, deleted_at, creator_id, updated_at, updater_id, lock_version) SELECT entity_id, '#{canal}', #{canal}, code, created_at, deleted_at, creator_id, updated_at, updater_id, lock_version FROM #{quoted_table_name(:entity_addresses)} WHERE LENGTH(TRIM(#{canal})) > 0")
      remove_column :entity_addresses, canal
    end
    for table, columns in CONTACT_TABLES
      for column in columns
        rename_column table, column, column.to_s.gsub("contact_id", "address_id").to_sym
      end
    end
    rename_index :entity_addresses, :index_contacts_on_default, :index_entity_addresses_on_by_default
    rename_index :entity_addresses, :index_contacts_on_stopped_at, :index_entity_addresses_on_deleted_at
    for column in [:code, :created_at, :creator_id, :entity_id, :updated_at, :updater_id]
      rename_index(:entity_addresses, "index_contacts_on_#{column}".to_sym, "index_entity_addresses_on_#{column}".to_sym)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
