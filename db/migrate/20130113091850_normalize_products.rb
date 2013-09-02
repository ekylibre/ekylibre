class NormalizeProducts < ActiveRecord::Migration
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
    # :custom_field_datum => {
    #   :choice_value_id => :custom_field_choice,
    #   :creator_id => :entity,
    #   :custom_field_id => :custom_field,
    #   :customized_id => "customized_type",
    #   :updater_id => :entity
    # },
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
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
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
    :incoming_payment_use => {
      :creator_id => :entity,
      :expense_id => "expense_type",
      :journal_entry_id => :journal_entry,
      :payment_id => :incoming_payment,
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
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
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
      :area_unit_id => :unit,
      :creator_id => :entity,
      :group_id => :land_parcel_group,
      :updater_id => :entity
    },
    :land_parcel_group => {
      :creator_id => :entity,
      :updater_id => :entity
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
    :mandate => {
      :creator_id => :entity,
      :entity_id => :entity,
      :updater_id => :entity
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
      :target_id => "target_type",
      :updater_id => :entity
    },
    :operation_line => {
      :area_unit_id => :unit,
      :creator_id => :entity,
      :operation_id => :operation,
      :product_id => :product,
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
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
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
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
    :outgoing_payment_use => {
      :creator_id => :entity,
      :expense_id => :purchase,
      :journal_entry_id => :journal_entry,
      :payment_id => :outgoing_payment,
      :updater_id => :entity
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
      :product_id => :product,
      :tax_id => :tax,
      :updater_id => :entity
    },
    :product => {
      :category_id => :product_category,
      :creator_id => :entity,
      :immobilizations_account_id => :account,
      :purchases_account_id => :account,
      :sales_account_id => :account,
      :subscription_nature_id => :subscription_nature,
      :unit_id => :unit,
      :updater_id => :entity
    },
    :product_category => {
      :creator_id => :entity,
      :parent_id => :product_category,
      :updater_id => :entity
    },
    # :product_component => {
    #   :component_id => :product,
    #   :creator_id => :entity,
    #   :product_id => :product,
    #   :updater_id => :entity,
    #   :warehouse_id => :warehouse
    # },
    # :production_chain => {
    #   :creator_id => :entity,
    #   :updater_id => :entity
    # },
    # :production_chain_conveyor => {
    #   :creator_id => :entity,
    #   :product_id => :product,
    #   :production_chain_id => :production_chain,
    #   :source_id => :production_chain_work_center,
    #   :target_id => :production_chain_work_center,
    #   :unit_id => :unit,
    #   :updater_id => :entity
    # },
    # :production_chain_work_center => {
    #   :building_id => :warehouse,
    #   :creator_id => :entity,
    #   :operation_nature_id => :operation_nature,
    #   :production_chain_id => :production_chain,
    #   :updater_id => :entity
    # },
    # :production_chain_work_center_use => {
    #   :creator_id => :entity,
    #   :tool_id => :tool,
    #   :updater_id => :entity,
    #   :work_center_id => :production_chain_work_center
    # },
    :profession => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :purchase => {
      :creator_id => :entity,
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
      :tracking_id => :tracking,
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
      :tax_id => :tax,
      :tracking_id => :tracking,
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
    :stock => {
      :creator_id => :entity,
      :product_id => :product,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
    },
    :stock_move => {
      :creator_id => :entity,
      :origin_id => "origin_type",
      :product_id => :product,
      :stock_id => :stock,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
    },
    :stock_transfer => {
      :creator_id => :entity,
      :product_id => :product,
      :second_stock_move_id => :stock_move,
      :second_warehouse_id => :warehouse,
      :stock_move_id => :stock_move,
      :tracking_id => :tracking,
      :unit_id => :unit,
      :updater_id => :entity,
      :warehouse_id => :warehouse
    },
    :subscription => {
      :address_id => :entity_address,
      :creator_id => :entity,
      :entity_id => :entity,
      :nature_id => :subscription_nature,
      :product_id => :product,
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
      :asset_id => :asset,
      :creator_id => :entity,
      :nature_id => :tool_nature,
      :updater_id => :entity
    },
    :tool_nature => {
      :creator_id => :entity,
      :updater_id => :entity
    },
    :tracking => {
      :creator_id => :entity,
      :producer_id => :entity,
      :product_id => :product,
      :updater_id => :entity
    },
    :tracking_state => {
      :creator_id => :entity,
      :production_chain_conveyor_id => :production_chain_conveyor,
      :responsible_id => :entity,
      :tracking_id => :tracking,
      :updater_id => :entity
    },
    :transfer => {
      :creator_id => :entity,
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
    :warehouse => {
      :address_id => :entity_address,
      :creator_id => :entity,
      :establishment_id => :establishment,
      :parent_id => :warehouse,
      :product_id => :product,
      :unit_id => :unit,
      :updater_id => :entity
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
    normalize_indexes(new_table)
  end

  def rename_table_and_co(old_table, new_table)
    rename_table_and_indexes(old_table, new_table)
    # Updates foreign columns
    for table, columns in references_of(new_table)
      model = table.to_s.singularize.to_sym
      for column, target in columns
        if target.is_a?(String)
          execute("UPDATE #{quoted_table_name(table)} SET #{target} = '#{new_table.to_s.classify}' WHERE #{target} = '#{old_table.to_s.classify}'")
        elsif column.to_s.match(/(^|\_)#{old_table.to_s.singularize + '_id'}$/)
          foreign_key = column.to_s.gsub(/(^|\_)#{old_table.to_s.singularize + '_id'}$/, '\1' + new_table.to_s.singularize + '_id').to_sym
          rename_column table, column, foreign_key
          @@references[model] ||= {}
          @@references[model][foreign_key] = @@references[model][column]
          @@references[model].delete(column)
        else
          say("No logic way to rename #{table}##{column} for #{new_table}")
        end
      end
    end
  end


  def update_depending_records(old_table, new_table, new_table_key)
    # puts "References of #{old_table}:\n" + references_of(old_table).inspect
    for table, links in references_of(old_table)
      table = new_table if table == old_table
      model = table.to_s.singularize.to_sym
      for foreign_key, foreign_model in links
        if foreign_model.is_a?(String)
          execute("UPDATE #{quoted_table_name(table)} SET #{foreign_key} = nt.id, #{foreign_model} = '#{new_table.to_s.classify}' FROM #{quoted_table_name(new_table)} AS nt WHERE #{quoted_table_name(table)}.#{foreign_key} = nt.#{new_table_key} AND #{quoted_table_name(table)}.#{foreign_model} = '#{old_table.to_s.classify}' AND nt.#{new_table_key} IS NOT NULL")
        else
          execute("UPDATE #{quoted_table_name(table)} SET #{foreign_key} = nt.id FROM #{quoted_table_name(new_table)} AS nt WHERE #{quoted_table_name(table)}.#{foreign_key} = nt.#{new_table_key} AND nt.#{new_table_key} IS NOT NULL")
          @@references[model] ||= {}
          @@references[model][foreign_key] = new_table.to_s.singularize.to_sym
        end
      end
    end

  end


  def up
    # Normalize units with nomenclatures
    for table in [:sale_lines, :purchase_lines, :inventory_lines] # , :incoming_delivery_lines, :outgoing_delivery_lines
      add_column table, :unit, :string
      add_index table, :unit
      if index_exists?(table, :unit_id)
        remove_index table, :unit_id
      end
      remove_column table, :unit_id
    end
    drop_table :units

    # Prevents errors by renaming table products
    rename_table_and_co :products, :old_products

    # Prevents errors by renaming table stocks
    rename_table_and_co :stocks, :old_stocks

    # Prevents errors by renaming table stock_moves
    rename_table_and_co :stock_moves, :old_stock_moves

    # Prevents errors by renaming table stock_transfers
    rename_table_and_co :stock_transfers, :old_stock_transfers

    # Prevents errors by renaming table operations
    # rename_table_and_co :operations, :old_operations

    # Types of product: define behaviours
    create_table :product_natures do |t|
      t.string :name,   :null => false
      t.string :number, :null => false, :limit => 31
      t.text :description
      # t.text :comment
      t.string :variety,       :null => false, :limit => 127
      t.string :derivative_of, :limit => 127
      t.string :nomen, :limit => 127
      t.text   :abilities
      t.text   :indicators
      t.string :population_counting,   :null => false # population management (unitary,integer,decimal)
      #t.boolean :individual,   :null => false, :default => false # population % 1
      #t.boolean :unitary,      :null => false, :default => false # population = 1
      #t.references :category,  :null => false
      t.boolean :active,       :null => false, :default => false
      # t.boolean :alive,        :null => false, :default => false
      t.boolean :depreciable,  :null => false, :default => false
      t.boolean :saleable,     :null => false, :default => false
      t.boolean :purchasable,  :null => false, :default => false
      # t.boolean :producible,   :null => false, :default => false
      # t.boolean :deliverable,  :null => false, :default => false
      t.boolean :storable,     :null => false, :default => false
      # t.boolean :storage,      :null => false, :default => false
      # t.boolean :towable,      :null => false, :default => false
      # t.boolean :tractive,     :null => false, :default => false
      # t.boolean :traceable,    :null => false, :default => false
      # t.boolean :transferable, :null => false, :default => false
      t.boolean :reductible,   :null => false, :default => false
      # t.boolean :atomic,       :null => false, :default => false
      t.boolean    :subscribing,  :null => false, :default => false
      t.references :subscription_nature
      t.string     :subscription_duration
      t.references :charge_account
      t.references :product_account
      t.references :asset_account
      t.references :stock_account
      t.stamps
    end
    add_stamps_indexes :product_natures
    add_index :product_natures, :number, :unique => true
    add_index :product_natures, :variety
    #add_index :product_natures, :category_id
    add_index :product_natures, :subscription_nature_id
    add_index :product_natures, :charge_account_id
    add_index :product_natures, :product_account_id
    add_index :product_natures, :asset_account_id
    add_index :product_natures, :stock_account_id


    create_table :product_nature_variants do |t|
      t.references :nature, :null => false
      t.string :name
      t.string :number
      t.string :nature_name, :null => false # Auto
      t.string :unit_name, :null => false
      t.string :commercial_name, :null => false
      t.text   :commercial_description
      t.text   :frozen_indicators
      t.text   :variable_indicators
      t.boolean :active,       :null => false, :default => false
      t.attachment :picture
      t.string  :contour # enumerize
      t.integer :horizontal_rotation, :null => false, :default => false

      t.stamps
    end
    add_stamps_indexes :product_nature_variants
    add_index :product_nature_variants, :nature_id

    create_table :product_nature_variant_indicator_data do |t|
      t.references :variant,            :null => false
      t.string     :indicator,          :null => false
      t.string     :indicator_datatype, :null => false
      t.string     :computation_method, :null => false
      t.geometry   :geometry_value
      t.decimal    :decimal_value,   :precision => 19, :scale => 4
      t.decimal    :measure_value_value,   :precision => 19, :scale => 4
      t.string     :measure_value_unit      # Needed for historic
      t.text       :string_value
      t.boolean    :boolean_value, :null => false, :default => false
      t.string     :choice_value
      t.stamps
    end
    add_stamps_indexes :product_nature_variant_indicator_data
    add_index :product_nature_variant_indicator_data, :variant_id
    add_index :product_nature_variant_indicator_data, :indicator

    # Re-create table product
    create_table :products do |t|
      t.string :type # , :null => false
      t.string :name, :null => false
      t.string :number, :null => false
      t.boolean :active, :null => false, :default => false
      t.string :variety, :null => false, :limit => 127
      t.references :variant, :null => false
      t.references :nature, :null => false # Auto
      # t.string :unit, :null => false    # Same as nature.unit
      t.references :tracking
      # t.references :tractor
      t.references :asset
      # t.references :current_place
      t.datetime :born_at
      t.datetime :dead_at
      t.text :description
      t.text :comment
      t.attachment :picture
      # t.decimal :minimal_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
      # t.decimal :maximal_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
      # t.decimal    :real_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
      # t.decimal :virtual_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
      t.boolean :external, :null => false, :default => false # true if owner == Entity.of_company
      t.references :owner, :null => false
      # Animal specific columns
      # t.string :sex
      t.string :identification_number # replaceable by serial_number ? No, for now
      t.string :work_number           # replaceable by number ?        No, for now
      # t.boolean :reproductor, :null => false, :default => false
      t.references :father
      t.references :mother
      # Place specific columns
      t.references :address
      # LandParcel specific columns
      # t.geometry   :shape
      # t.decimal    :area_measure, :precision => 19, :scale => 4
      # t.string     :area_unit
      # Warehouse specific columns
      t.boolean    :reservoir, :null => false, :default => false
      t.references :content_nature
      t.string     :content_indicator # Auto
      t.string     :content_indicator_unit # Auto
      t.decimal    :content_maximal_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
      # Hierarchy column (for Place, Group)
      t.references :parent
      # Stamps
      t.stamps
    end
    add_stamps_indexes :products
    add_index :products, :type
    add_index :products, :number, :unique => true
    add_index :products, :nature_id
    add_index :products, :variant_id
    add_index :products, :tracking_id
    add_index :products, :variety
    # add_index :products, :unit
    # add_index :products, :tractor_id
    add_index :products, :asset_id
    add_index :products, :owner_id
    # Animal specific indexes
    add_index :products, :father_id
    add_index :products, :mother_id
    # Place specific columns
    add_index :products, :address_id
    # LandParcel specific indexes
    # add_index :products, :area_unit
    # Warehouse specific indexes
    add_index :products, :content_nature_id
    add_index :products, :content_indicator_unit
    add_index :products, :parent_id
    @@references[:product] ||= {}
    @@references[:product][:current_place_id] = :warehouse

    # Contains all moves of the stock of the product
    create_table :product_moves do |t|
      t.references :product,   :null => false
      t.decimal :population_delta, :precision => 19, :scale => 4, :null => false
      t.datetime :started_at
      t.datetime :stopped_at
      t.boolean :initial, :null => false, :default => false
      t.stamps
    end
    add_stamps_indexes :product_moves
    add_index :product_moves, :product_id
    add_index :product_moves, :started_at
    add_index :product_moves, :stopped_at

    # # Contains all transfers
    # create_table :product_transfers do |t|
    #   t.references :product,  :null => false # RO
    #   t.references :origin
    #   t.references :destination              # nil => exterior
    #   t.datetime :started_at, :null => false
    #   t.datetime :stopped_at, :null => false
    #   t.stamps
    # end
    # add_stamps_indexes :product_transfers
    # add_index :product_transfers, :product_id
    # add_index :product_transfers, :destination_id
    # add_index :product_transfers, :origin_id


    # Historize differents localizations of the products
    create_table :product_localizations do |t|
      # t.references :transfer # RO
      # t.references :operation
      t.references :product,   :null => false # Duplicated from transfer.product_id
      t.string     :nature,    :null => false
      t.references :container
      t.string :arrival_cause
      t.string :departure_cause
      t.datetime :started_at
      t.datetime :stopped_at
      t.stamps
    end
    add_stamps_indexes :product_localizations
    # add_index :product_localizations, :transfer_id
    # add_index :product_localizations, :operation_id
    add_index :product_localizations, :product_id
    add_index :product_localizations, :container_id
    add_index :product_localizations, :started_at
    add_index :product_localizations, :stopped_at

    # Historize differents ownerships of the products
    create_table :product_ownerships do |t|
      t.references :product,   :null => false
      t.string     :nature,    :null => false
      t.references :owner
      t.datetime :started_at
      t.datetime :stopped_at
      t.stamps
    end
    add_stamps_indexes :product_ownerships
    add_index :product_ownerships, :product_id
    add_index :product_ownerships, :owner_id
    add_index :product_ownerships, :started_at
    add_index :product_ownerships, :stopped_at


    # Historize differents catches/releases between products
    create_table :product_links do |t|
      t.references :carrier, :null => false
      t.references :carried, :null => false
      t.datetime :started_at
      t.datetime :stopped_at
      t.stamps
    end
    add_stamps_indexes :product_links
    add_index :product_links, :carrier_id
    add_index :product_links, :carried_id
    add_index :product_links, :started_at
    add_index :product_links, :stopped_at

    # Trace all memberships for products
    create_table :product_memberships do |t|
      t.references :member,   :null => false # RO
      t.references :group,    :null => false # RO
      t.datetime :started_at, :null => false
      t.datetime :stopped_at
      t.stamps
    end
    add_stamps_indexes :product_memberships
    add_index :product_memberships, :member_id
    add_index :product_memberships, :group_id
    add_index :product_memberships, :started_at
    add_index :product_memberships, :stopped_at

    # # Permits to group product to enhances ergonomy
    # create_table :product_groups do |t|
    #   t.string :name, :null => false
    #   t.text :description
    #   t.text :comment
    #   t.string :color
    #   t.references :parent
    #   t.integer :lft
    #   t.integer :rgt
    #   t.integer :depth, :null => false, :default => 0
    #   t.stamps
    # end
    # add_stamps_indexes :product_groups
    # add_index :product_groups, :parent_id
    # add_index :product_groups, :lft
    # add_index :product_groups, :rgt

    # Trace all activities
    create_table :logs do |t|
      t.string :event, :null => false
      t.references :owner, :polymorphic => true
      t.text :owner_object
      t.datetime :observed_at, :null => false
      t.references :origin, :polymorphic => true
      t.text :origin_object
      t.text :description
      t.stamps
    end
    add_stamps_indexes :logs
    add_index :logs, [:owner_type, :owner_id]
    add_index :logs, :observed_at
    add_index :logs, [:origin_type, :origin_id]
    add_index :logs, :description

    # Create new table operations mono-target and mono-operand
    # create_table :operations do |t|
    #   t.references :target, :null => false
    #   t.string :nature, :null => false
    #   t.references :operand
    #   t.references :operand_unit
    #   t.decimal    :operand_quantity, :precision => 19, :scale => 4
    #   t.datetime :started_at, :null => false
    #   t.datetime :stopped_at, :null => false
    #   t.boolean :confirmed,   :null => false, :default => false
    #   t.stamps
    # end
    # add_stamps_indexes :operations
    # add_index :operations, :target_id
    # add_index :operations, :operand_id
    # add_index :operations, :nature

    # # Define workers on given operations
    # create_table :operation_works do |t|
    #   t.references :operation, :null => false
    #   t.references :worker, :null => false
    #   t.string :nature, :null => false
    #   t.stamps
    # end
    # add_stamps_indexes :operation_works
    # add_index :operation_works, :operation_id
    # add_index :operation_works, :worker_id

    # Rename table in order to be more logical
    #rename_table_and_co :product_categories, :product_nature_categories
    drop_table :product_categories
    # Rename table in order to be more logical
    rename_table_and_indexes :prices, :product_price_templates
    add_column :product_price_templates, :pretax_amount_generation, :string, :limit => 32
    execute "UPDATE #{quoted_table_name(:product_price_templates)} SET pretax_amount_generation = 'assignment'"
    change_column_null :product_price_templates, :pretax_amount_generation, :null => false
    add_column :product_price_templates, :pretax_amount_calculation_formula, :text
    for column in [:pretax_amount, :amount]
      change_column_null :product_price_templates, column, true
      rename_column :product_price_templates, column, "assignment_#{column}".to_sym
    end
    add_column :product_price_templates, :amounts_scale, :integer, :null => false, :default => 2

    add_column :purchase_lines, :price_template_id, :integer
    add_column :sale_lines, :price_template_id, :integer

    # Rename table in order to be more logical
    rename_table_and_indexes :entity_categories, :product_price_listings
    rename_column :entities, :category_id, :sale_price_listing_id
    rename_column :product_price_templates, :category_id, :listing_id

    # This table registered all computed prices
    create_table :product_prices do |t|
      t.references :product
      t.references :variant, :null => false
      t.references :listing
      t.references :supplier, :null => false
      t.decimal :pretax_amount, :null => false, :precision => 19, :scale => 4
      t.decimal :amount, :null => false, :precision => 19, :scale => 4
      t.references :tax, :null => false
      t.string :currency, :null => false, :limit => 3
      t.datetime :started_at
      t.datetime :stopped_at
      t.stamps
    end
    add_stamps_indexes :product_prices
    add_index :product_prices, :product_id
    add_index :product_prices, :listing_id
    add_index :product_prices, :supplier_id
    add_index :product_prices, :tax_id
    add_index :product_prices, :variant_id

    # TODO Insert new prices

    # Rename table in order to be more logical
    # rename_table_and_co :product_components, :product_nature_components
    # remove_column :product_nature_components, :warehouse_id


    # TODO: Make data migration

    # # Find default category
    # default_category_id = select_value("SELECT id FROM #{quoted_table_name(:product_nature_categories)} WHERE parent_id IS NULL OR parent_id = 0 ORDER BY name DESC").to_i

    # # Insert old_products in product_natures
    # add_column :product_natures, :old_id, :integer
    # ca = [:name, :created_at, :creator_id, :updated_at, :updater_id, :lock_version, :active, :comment, :description, :deliverable, :subscription_nature_id, :unit_id, :category_id]
    # da = {:variety_id => "v.id", :old_id => "p.id", :subscription_duration => "CASE WHEN sn.nature = 'period' THEN subscription_period WHEN sn.nature = 'quantity' THEN CAST(subscription_quantity AS VARCHAR) END", :number => "p.code", :commercial_description => "p.catalog_description", :commercial_name => "p.catalog_name", :depreciable => "p.for_immobilizations", :producible => "p.for_productions", :purchasable => "p.for_purchases", :saleable => "p.for_sales", :asset_account_id => "p.immobilizations_account_id", :charge_account_id => "p.purchases_account_id", :product_account_id => "p.sales_account_id", :reductible => "p.reduction_submissive", :traceable => "p.trackable", :storable => "p.stockable"}
    # execute("INSERT INTO #{quoted_table_name(:product_natures)} (" + ca.join(', ') + ", " + da.keys.join(', ') + ") SELECT " + ca.collect{|c| "p.#{c}"}.join(', ') + ", " + da.values.join(', ') + " FROM #{quoted_table_name(:old_products)} AS p JOIN #{quoted_table_name(:product_varieties)} AS v ON (v.code = (CASE WHEN p.nature = 'product' THEN 'matter' ELSE 'service' END)) LEFT JOIN #{quoted_table_name(:subscription_natures)} AS sn ON (sn.id = p.subscription_nature_id)")
    # update_depending_records(:old_products, :product_natures, :old_id)

    # # Insert old_stocks in products
    # add_column :products, :old_id, :integer
    # # add_column :products, :old_stock_id, :integer
    # # add_column :products, :old_tracking_id, :integer
    # da = {:minimal_quantity => "COALESCE(s.quantity_min, 0)", :maximal_quantity => "COALESCE(s.quantity_max, 0)", :old_id => "s.id", :name => "COALESCE(s.name, pn.name, pnv.name)", :unit_id => "s.unit_id", :tracking_id => "s.tracking_id", :number => "LPAD(CAST(s.id AS VARCHAR), 8, '0')", :nature_id => "s.old_product_id", :created_at => "s.created_at", :creator_id => "s.creator_id", :updated_at => "s.updated_at", :updater_id => "s.updater_id", :lock_version => "s.lock_version", :type => "pnv.product_type", :minimal_quantity => "COALESCE(s.quantity_min, 0)", :maximal_quantity => "COALESCE(s.quantity_max, 0)", :real_quantity => "COALESCE(s.quantity, 0)", :virtual_quantity => "COALESCE(s.virtual_quantity, 0)", :current_place_id => "s.warehouse_id"}
    # execute("INSERT INTO #{quoted_table_name(:products)} (" + da.keys.join(', ') + ") SELECT DISTINCT " + da.values.join(', ') + " FROM #{quoted_table_name(:old_stocks)} AS s LEFT JOIN #{quoted_table_name(:product_natures)} AS pn ON (s.old_product_id = pn.id) LEFT JOIN #{quoted_table_name(:product_varieties)} AS pnv ON (pn.variety_id = pnv.id)")

    # update_depending_records(:old_stocks, :products, :old_id)


    # # Insert old_stock_moves in operations with consume/produce
    # add_column :operations, :old_stock_move_id, :integer
    # da = {:old_id => "oms.id", :stock_id => "ns.id", :product_id => "oms.product_id", :warehouse_id => "oms.warehouse_id", :unit_id => "oms.unit_id", :quantity => "oms.quantity", :moved_at => "oms.moved_on", :mode => "CASE WHEN oms.virtual THEN 'virtual' ELSE 'real' END", :origin_id => "oms.origin_id", :origin_type => "oms.origin_type", :created_at => "oms.created_at", :creator_id => "oms.creator_id", :updated_at => "oms.updated_at", :updater_id => "oms.updater_id", :lock_version => "oms.lock_version"}
    # da = {:old_id => "oms.id", :stock_id => "ns.id", :product_id => "oms.product_id", :warehouse_id => "oms.warehouse_id", :unit_id => "oms.unit_id", :quantity => "oms.quantity", :moved_at => "oms.moved_on", :mode => "CASE WHEN oms.virtual THEN 'virtual' ELSE 'real' END", :origin_id => "oms.origin_id", :origin_type => "oms.origin_type", :created_at => "oms.created_at", :creator_id => "oms.creator_id", :updated_at => "oms.updated_at", :updater_id => "oms.updater_id", :lock_version => "oms.lock_version"}
    # execute("INSERT INTO #{quoted_table_name(:product_stock_moves)} (" + da.keys.join(', ') + ") SELECT " + da.values.join(', ') + " FROM #{quoted_table_name(:old_stock_moves)} AS oms LEFT JOIN #{quoted_table_name(:product_stocks)} AS ns ON (oms.stock_id = ns.id)")
    # update_depending_records(:old_stock_movess, :product_stock_moves, :old_id)

    # raise "Stop!"

    # # Old stock_transfers
    # add_column :old_stock_transfers, :stock_id, :integer
    # add_column :old_stock_transfers, :second_stock_id, :integer
    # add_column :product_transfers, :old_id, :integer
    # ost = quoted_table_name(:old_stock_transfers)
    # execute("UPDATE #{ost} SET stock_id = nps.id FROM #{quoted_table_name(:product_stocks)} AS nps WHERE #{ost}.product_id = nps.product_id AND #{ost}.tracking_id = nps.old_tracking_id AND #{ost}.warehouse_id = nps.warehouse_id")
    # execute("UPDATE #{ost} SET second_stock_id = nps.id FROM #{quoted_table_name(:product_stocks)} AS nps WHERE #{ost}.product_id = nps.product_id AND #{ost}.tracking_id = nps.old_tracking_id AND #{ost}.second_warehouse_id = nps.warehouse_id")
    # da = {:old_id => "ost.id", :number => "ost.number", :product_id => "ost.product_id", :unit_id => "ost.unit_id", :quantity => "ost.quantity", :nature => "CASE WHEN nature = 'waste' THEN 'loss' ELSE nature END", :moved_at => "ost.moved_on", :departure_stock_id => "ost.stock_id", :departure_move_id => "ost.stock_move_id", :departure_warehouse_id => "ost.warehouse_id", :arrival_stock_id => "ost.second_stock_id", :arrival_move_id => "ost.second_stock_move_id", :arrival_warehouse_id => "ost.second_warehouse_id", :comment => "ost.comment", :created_at => "ost.created_at", :creator_id => "ost.creator_id", :updated_at => "ost.updated_at", :updater_id => "ost.updater_id", :lock_version => "ost.lock_version"}
    # execute("INSERT INTO #{quoted_table_name(:product_transfers)} (" + da.keys.join(', ') + ") SELECT " + da.values.join(', ') + " FROM #{quoted_table_name(:old_stock_transfers)} AS ost")
    # update_depending_records(:stock_transfers, :product_transfers, :old_id)



    # # Add missing stock_id in traceable tables
    # for table in [:incoming_delivery_lines, :inventory_lines, :operation_lines, :outgoing_delivery_lines, :purchase_lines, :sale_lines]
    #   qtn = quoted_table_name(table)
    #   add_column table, :stock_id, :integer
    #   add_index  table, :stock_id
    #   # Fill new column
    #   execute("UPDATE #{qtn} SET stock_id = nps.id FROM #{quoted_table_name(:product_stocks)} AS nps JOIN #{quoted_table_name(:products)} AS np ON (np.id = nps.product_id) WHERE #{qtn}.product_id = np.id AND #{qtn}.warehouse_id = nps.warehouse_id AND #{qtn}.tracking_id = np.old_tracking_id")

    #   # Removes old columns
    #   model = table.to_s.singularize.to_sym
    #   remove_column table, :tracking_id
    #   @@references[model].delete(:tracking_id)
    # end

    # # Replace products with product_natures in needed tables
    # for table, columns in {:prices => nil, :product_nature_components => [:component_id, nil], :production_chain_conveyors => nil, :subscriptions => nil, :warehouses => nil} # , :trackings => nil
    #   columns = [columns] unless columns.is_a?(Array)
    #   for column in columns
    #     column ||= :product_id
    #     execute("UPDATE #{quoted_table_name(table)} SET #{column} = pn.nature_id FROM #{quoted_table_name(:products)} AS pn")
    #     if column.to_s.match(/(^|\_)product_id/)
    #       rename_column table, column, column.to_s.gsub(/(^|\_)product_id/, '\1product_nature_id').to_sym
    #     end
    #   end
    # end

    # # LandParcelGroup
    # add_column :product_groups, :old_land_parcel_group_id, :integer
    # ca = [:name, :comment, :color, :created_at, :creator_id, :lock_version, :updated_at, :updater_id]
    # execute("INSERT INTO #{quoted_table_name(:product_groups)} (old_land_parcel_group_id, " + ca.join(', ') + ") SELECT id, " + ca.join(', ') + " FROM #{quoted_table_name(:land_parcel_groups)}")
    # update_depending_records(:land_parcel_groups, :product_groups, :old_land_parcel_group_id)


    # land_parcels_count = select_value("SELECT count(*) FROM #{quoted_table_name(:land_parcels)}").to_i
    # if Rails.env.development? or land_parcels_count > 0

    #   # "LandParcelNature"
    #   unit_id = select_value("SELECT id FROM #{quoted_table_name(:units)} WHERE base = 'm2' ORDER BY name DESC").to_i
    #   name, number = "Land parcel", "LANDPARCEL0"
    #   ca = [:created_at, :creator_id, :lock_version, :updated_at, :updater_id]
    #   da = {:name => "'#{name}'", :number => "'#{number}'", :unit_id => unit_id, :commercial_name => "'#{name}'", :variety_id => "v.id", :active => true, :category_id => default_category_id, :saleable => quoted_true, :purchasable => quoted_true}
    #   execute("INSERT INTO #{quoted_table_name(:product_natures)} (" + ca.join(', ') + ", " + da.keys.join(', ') + ") SELECT " + ca.join(', ') + ", " + da.values.join(', ') + " FROM #{quoted_table_name(:product_varieties)} AS v WHERE v.code = 'land_parcel'")
    #   nature_id = select_value("SELECT id FROM #{quoted_table_name(:product_natures)} WHERE number = '#{number}'").to_i

    #   # LandParcel
    #   add_column :products, :old_land_parcel_id, :integer
    #   ca = [:name, :number, :description, :created_at, :creator_id, :lock_version, :updated_at, :updater_id, :shape, :area_measure, :area_unit_id]
    #   da = {:type => "'LandParcel'", :active => quoted_true, :nature_id => nature_id, :unit_id => unit_id, :born_at => "started_on", :dead_at => "stopped_on"}
    #   execute("INSERT INTO #{quoted_table_name(:products)} (old_land_parcel_id, " + ca.join(', ') + ", " + da.keys.join(', ') + ") SELECT id, " + ca.join(', ') + ", " + da.values.join(', ') + " FROM #{quoted_table_name(:land_parcels)}")
    #   update_depending_records(:land_parcels, :products, :old_land_parcel_id)

    #   # "LandParcelMembership"
    #   ca = [:created_at, :creator_id, :updated_at, :updater_id, :lock_version]
    #   execute("INSERT INTO #{quoted_table_name(:product_memberships)} (product_id, group_id, " + ca.join(', ') + ") SELECT np.id, lp.group_id, " + ca.collect{|c| "lp.#{c}"}.join(', ') + " FROM #{quoted_table_name(:land_parcels)} AS lp JOIN #{quoted_table_name(:products)} AS np ON (np.old_land_parcel_id = lp.id) WHERE lp.group_id IS NOT NULL AND np.id IS NOT NULL")
    # end

    # # ToolNature
    # add_column :product_natures, :old_tool_nature_id, :integer
    # unit_id = select_value("SELECT id FROM #{quoted_table_name(:units)} WHERE LENGTH(TRIM(base)) <= 0 ORDER BY name DESC").to_i
    # variety_id = select_value("SELECT id FROM #{quoted_table_name(:product_varieties)} WHERE code = 'tool'").to_i
    # ca = [:name, :comment, :created_at, :creator_id, :updated_at, :updater_id, :lock_version]
    # da = {:number => "'TN'||CAST(tn.id AS VARCHAR)", :unit_id => unit_id, :commercial_name => :name, :variety_id => variety_id, :category_id => default_category_id, :saleable => quoted_true, :purchasable => quoted_true, :stockable => quoted_true, :reductible => quoted_true, :indivisible => quoted_true}
    # execute("INSERT INTO #{quoted_table_name(:product_natures)} (old_tool_nature_id, " + ca.join(', ') + ", " + da.keys.join(', ') + ") SELECT id, " + ca.join(', ') + ", " + da.values.join(', ') + " FROM #{quoted_table_name(:tool_natures)} AS tn")
    # update_depending_records(:tool_natures, :product_natures, :old_tool_nature_id)

    # # Tool
    # add_column :products, :old_tool_id, :integer
    # ca = [:name, :comment, :nature_id, :created_at, :creator_id, :updated_at, :updater_id, :lock_version]
    # da = {:type => "'Tool'", :born_at => :purchased_on, :dead_at => :ceded_on, :unit_id => unit_id}
    # execute("INSERT INTO #{quoted_table_name(:products)} (old_tool_id, " + ca.join(', ') + ", " + da.keys.join(', ') + ") SELECT id, " + ca.join(', ') + ", " + da.values.join(', ') + " FROM #{quoted_table_name(:tools)} AS t")
    # update_depending_records(:tools, :products, :old_tool_id)

    # warehouses_count = select_value("SELECT count(*) FROM #{quoted_table_name(:warehouses)}").to_i
    # if Rails.env.development? or warehouses_count > 0
    #   # "WarehouseNature"
    #   unit_id = select_value("SELECT id FROM #{quoted_table_name(:units)} WHERE base = 'm2' ORDER BY name ASC").to_i
    #   name, number = "Warehouse", "WAREHOUSE0"
    #   ca = [:created_at, :creator_id, :lock_version, :updated_at, :updater_id]
    #   da = {:name => "'#{name}'", :number => "'#{number}'", :unit_id => unit_id, :commercial_name => "'#{name}'", :variety_id => "v.id", :active => true, :category_id => default_category_id, :saleable => quoted_true, :purchasable => quoted_true}
    #   execute("INSERT INTO #{quoted_table_name(:product_natures)} (" + ca.join(', ') + ", " + da.keys.join(', ') + ") SELECT " + ca.join(', ') + ", " + da.values.join(', ') + " FROM #{quoted_table_name(:product_varieties)} AS v WHERE v.code = 'warehouse'")
    #   nature_id = select_value("SELECT id FROM #{quoted_table_name(:product_natures)} WHERE number = '#{number}'").to_i

    #   # Warehouse
    #   add_column :products, :old_warehouse_id, :integer
    #   ca = [:name, :number, :created_at, :creator_id, :lock_version, :updated_at, :updater_id, :reservoir, :address_id]
    #   da = {:type => "'Warehouse'", :active => quoted_true, :nature_id => nature_id, :unit_id => unit_id, :content_nature_id => :product_nature_id, :content_unit_id => :unit_id, :content_maximal_quantity => "COALESCE(quantity_max, 0.0)", :description => "COALESCE(division, name) || COALESCE(', ' || subdivision, '') || COALESCE(', ' || subsubdivision, '')", :unit_id => unit_id, :parent_place_id => :parent_id}
    #   execute("INSERT INTO #{quoted_table_name(:products)} (old_warehouse_id, " + ca.join(', ') + ", " + da.keys.join(', ') + ") SELECT id, " + ca.collect{|c| "w.#{c}" }.join(', ') + ", " + da.values.join(', ') + " FROM #{quoted_table_name(:warehouses)} AS w")

    #   @@references[:warehouse].delete(:parent_id)
    #   update_depending_records(:warehouses, :products, :old_warehouse_id)
    # end

    # if Rails.env.development? or warehouses_count > 0
    #   remove_column :products, :old_warehouse_id
    # end
    # remove_column :products, :old_tool_id
    # remove_column :product_natures, :old_tool_nature_id
    # if Rails.env.development? or land_parcels_count > 0
    #   remove_column :products, :old_land_parcel_id
    # end
    # remove_column :product_groups, :old_land_parcel_group_id
    # remove_column :product_groups, :old_animal_group_id
    # remove_column :products, :old_animal_id
    # remove_column :product_natures, :old_animal_nature_id
    # remove_column :product_varieties, :old_animal_race_id
    # remove_column :product_transfers, :old_id
    # remove_column :product_stock_moves, :old_id
    # remove_column :product_stocks, :old_tracking_id
    # remove_column :product_stocks, :old_id
    # # remove_column :products, :old_tracking_id
    # # remove_column :products, :old_stock_id
    # remove_column :products, :old_id
    # remove_column :product_natures, :old_id

    for model, references in @@references
      table = model.to_s.tableize.to_sym
      for column, foreign_table in references
        if column == :old_product_id
          rename_column table, column, ([:product_price_templates, :product_nature_components, :subscriptions].include?(table) ? :product_nature_id : :product_id) # , :production_chain_conveyors
        elsif column == :old_stock_move_id
          rename_column table, column, :move_id
        end
      end
    end

    drop_table :product_price_templates
    # drop_table :trackings
    drop_table :tracking_states

    drop_table :land_parcel_groups
    drop_table :land_parcels
    drop_table :land_parcel_kinships
    drop_table :tools
    drop_table :warehouses

    # drop_table :operation_uses
    # drop_table :operation_lines
    # drop_table :operation_natures

    # drop_table :old_operations
    drop_table :old_stock_transfers
    drop_table :old_stock_moves
    drop_table :old_stocks
    drop_table :old_products



  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end




    # Contains all the emplacement ever used to stock the product
    # create_table :product_stocks do |t|
    #   t.references :product,   :null => false # RO
    #   t.references :warehouse, :null => false # RO
    #   t.references :unit,      :null => false # Duplicated from product.unit_id if possible
    #   t.decimal    :real_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
    #   t.decimal :virtual_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
    #   t.decimal :minimal_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
    #   t.decimal :maximal_quantity, :precision => 19, :scale => 4, :null => false, :default => 0.0
    #   t.stamps
    # end
    # add_stamps_indexes :product_stocks
    # add_index :product_stocks, :product_id
    # add_index :product_stocks, :warehouse_id
    # add_index :product_stocks, :unit_id

    # # Contains all moves of the stock of the product
    # create_table :product_stock_moves do |t|
    #   t.references :stock,     :null => false # RO
    #   t.references :product,   :null => false # Duplicated from stock.product_id
    #   t.references :warehouse, :null => false # Duplicated from stock.warehouse_id
    #   t.references :unit,      :null => false # Duplicated from stock.unit_id
    #   t.decimal :quantity, :precision => 19, :scale => 4, :null => false
    #   t.datetime :moved_at
    #   t.string :mode, :null => false
    #   t.references :origin, :polymorphic => true
    #   t.stamps
    # end
    # add_stamps_indexes :product_stock_moves
    # add_index :product_stock_moves, :stock_id
    # add_index :product_stock_moves, :product_id
    # add_index :product_stock_moves, :warehouse_id
    # add_index :product_stock_moves, :unit_id
    # add_index :product_stock_moves, :mode
    # add_index :product_stock_moves, :moved_at
    # add_index :product_stock_moves, [:origin_id, :origin_type]

    # # Contains all the historic of quantities for a given product_stock
    # create_table :product_stock_periods do |t|
    #   t.references :move,      :null => false # RO
    #   t.references :stock,     :null => false # Duplicated from move.stock_id
    #   t.references :product,   :null => false # Duplicated from move.stock.product_id
    #   t.references :warehouse, :null => false # Duplicated from move.stock.warehouse_id
    #   t.references :unit,      :null => false # Duplicated from move.stock.unit_id
    #   t.decimal :quantity, :decimal, :precision => 19, :scale => 4, :null => false, :default => 0
    #   t.string :mode, :limit => 32, :null => false
    #   t.datetime :started_at
    #   t.datetime :stopped_at
    #   t.stamps
    # end
    # add_stamps_indexes :product_stock_periods
    # add_index :product_stock_periods, :move_id
    # add_index :product_stock_periods, :stock_id
    # add_index :product_stock_periods, :product_id
    # add_index :product_stock_periods, :warehouse_id
    # add_index :product_stock_periods, :unit_id
    # add_index :product_stock_periods, :started_at
    # add_index :product_stock_periods, :stopped_at

    # # Contains all stocks transfers
    # create_table :product_transfers do |t|
    #   t.string :number, :null => false
    #   t.references :product, :null => false # RO
    #   t.references :unit,    :null => false # Duplicated from product.unit_id if possible
    #   t.decimal  :quantity, :precision => 19, :scale => 4, :null => false
    #   t.string   :nature, :null => false
    #   t.datetime :moved_at, :null => false
    #   t.references :departure_stock
    #   t.references :departure_move
    #   t.references :departure_warehouse # Duplicated from departure_stock.warehouse_id
    #   t.references :arrival_stock
    #   t.references :arrival_move
    #   t.references :arrival_warehouse   # Duplicated from arrival_stock.warehouse_id
    #   t.text :comment
    #   t.stamps
    # end
    # add_stamps_indexes :product_transfers
    # add_index :product_transfers, :number, :unique => true
    # add_index :product_transfers, :product_id
    # # add_index :product_transfers, :unit_id
    # add_index :product_transfers, :moved_at
    # add_index :product_transfers, :nature
    # add_index :product_transfers, :departure_stock_id
    # add_index :product_transfers, :departure_move_id
    # # add_index :product_transfers, :departure_warehouse_id
    # add_index :product_transfers, :arrival_stock_id
    # add_index :product_transfers, :arrival_move_id
    # # add_index :product_transfers, :arrival_warehouse_id


    # update_depending_records(:old_products, :products, :old_id)
    # # Old stocks
    # add_column :product_stocks, :old_id, :integer
    # add_column :product_stocks, :old_tracking_id, :integer
    # da = {:old_id => "s.id", :product_id => "np.id", :warehouse_id => "s.warehouse_id", :unit_id => "s.unit_id", :old_tracking_id => "s.tracking_id", :minimal_quantity => "COALESCE(s.quantity_min, 0)", :maximal_quantity => "COALESCE(s.quantity_max, 0)", :created_at => "s.created_at", :creator_id => "s.creator_id", :updated_at => "s.updated_at", :updater_id => "s.updater_id", :lock_version => "s.lock_version", :real_quantity => "COALESCE(s.quantity, 0)", :virtual_quantity => "COALESCE(s.virtual_quantity, 0)"}
    # execute("INSERT INTO #{quoted_table_name(:product_stocks)} (" + da.keys.join(', ') + ") SELECT " + da.values.join(', ') + " FROM #{quoted_table_name(:old_stocks)} AS s LEFT JOIN #{quoted_table_name(:products)} AS np ON (s.product_id = np.id)")
