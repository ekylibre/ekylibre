class NormalizeScoria < ActiveRecord::Migration
  def up
    rename_column :accounts, :is_debit, :debtor
    add_column :accounts, :usages, :text

    remove_column :asset_depreciations, :depreciation

    rename_column :cashes, :iban_label, :spaced_iban
    rename_column :cashes, :number, :bank_account_number
    rename_column :cashes, :key, :bank_account_key
    rename_column :cashes, :agency_code, :bank_agency_code
    rename_column :cashes, :address, :bank_agency_address
    # rename_column :cashes, :bank_name, :bank_account_agency_code
    rename_column :cashes, :bic, :bank_identifier_code
    change_column_default :cashes, :mode, "iban"

    drop_table :cultivations

    change_column_null :custom_field_choices, :value, true

    add_column :departments, :lft, :integer
    add_column :departments, :rgt, :integer
    add_column :departments, :depth, :integer, :null => false, :default => 0


    add_column :deposit_lines, :currency, :string, :limit => 3, :null => false

    rename_column :entities, :reflation_submissive, :reminder_submissive
    rename_column :entities, :code, :number
    rename_column :entities, :vat_submissive, :vat_subjected
    remove_column :entities, :ean13
    remove_column :entities, :excise
    remove_column :entities, :name
    remove_column :entities, :salt
    remove_column :entities, :hashed_password
    add_column    :entities, :picture_file_name, :string
    add_column    :entities, :picture_file_size, :integer
    add_column    :entities, :picture_content_type, :string
    add_column    :entities, :picture_updated_at, :datetime
    remove_column :entities, :photo
    add_column    :entities, :type, :string
    add_column    :entities, :nature, :string
    execute("UPDATE #{quoted_table_name(:entities)} SET type = CASE WHEN NOT physical THEN 'LegalEntity' WHEN name LIKE '%dam%' OR name LIKE '%si%r' THEN 'Person' ELSE 'Entity' END, nature = CASE WHEN NOT physical AND en.name LIKE '%asso%' THEN 'association' WHEN NOT physical THEN 'company' WHEN name LIKE '%dam%' THEN 'madam' WHEN name LIKE '%si%r' THEN 'sir' ELSE 'undefined' END FROM #{quoted_table_name(:entity_natures)} AS en WHERE en.id = nature_id")
    # change_column_null :entities, :type, false
    change_column_null :entities, :nature, false
    remove_column :entities, :nature_id

    change_column :entity_links, :started_on, :datetime
    rename_column :entity_links, :started_on, :started_at
    change_column :entity_links, :stopped_on, :datetime
    rename_column :entity_links, :stopped_on, :stopped_at
    add_column :entity_links, :nature, :string
    execute("UPDATE entity_links SET nature = 'undefined'")
    change_column_null :entity_links, :nature, false
    remove_column :entity_links, :nature_id

    drop_table :entity_link_natures

    drop_table :entity_natures
    # add_column :entity_natures, :gender, :string
    # execute("UPDATE #{quoted_table_name(:entity_natures)} SET gender = CASE WHEN NOT physical THEN 'organization' WHEN name LIKE '%dam%' THEN 'woman' WHEN name LIKE '%si%r' THEN 'man' ELSE 'undefined' END")
    # change_column_null :entity_natures, :gender, false
    # remove_column :entity_natures, :physical

    remove_column :establishments, :nic
    rename_column :establishments, :siret, :code
    change_column_null :establishments, :code, true

    rename_table :event_natures, :meeting_natures

    create_table :meeting_participations do |t|
      t.references :meeting, :null => false
      t.references :participant,  :null => false
      t.string :state
      t.stamps
    end
    add_stamps_indexes :meeting_participations
    add_index :meeting_participations, :meeting_id
    add_index :meeting_participations, :participant_id


    rename_column :events, :reason, :name
    rename_column :events, :location, :place
    add_column :events, :description, :text
    add_column :events, :stopped_at, :datetime
    add_column :events, :type, :string
    execute("UPDATE #{quoted_table_name(:events)} SET type = 'Meeting', stopped_at = CASE WHEN duration IS NOT NULL THEN started_at + (duration || ' minutes')::INTERVAL ELSE stopped_at END")
    # change_column_null :events, :type, false
    rename_column :events, :nature_id, :meeting_nature_id
    change_column_null :events, :meeting_nature_id, true
    remove_column :events, :started_sec
    remove_column :events, :responsible_id
    remove_column :events, :entity_id

    remove_column :incoming_deliveries, :currency
    remove_column :incoming_deliveries, :amount
    remove_column :incoming_deliveries, :pretax_amount
    remove_column :incoming_deliveries, :comment
    rename_column :incoming_deliveries, :moved_on, :received_at
    change_column :incoming_deliveries, :received_at, :datetime
    remove_column :incoming_deliveries, :planned_on
    # rename_column :incoming_deliveries, :planned_on, :planned_at
    # change_column :incoming_deliveries, :planned_at, :datetime
    add_column :incoming_deliveries, :sender_id, :integer
    add_index :incoming_deliveries, :sender_id
    execute "UPDATE #{quoted_table_name(:incoming_deliveries)} SET sender_id = p.supplier_id FROM #{quoted_table_name(:purchases)} AS p WHERE p.id = purchase_id"
    execute "UPDATE #{quoted_table_name(:incoming_deliveries)} SET sender_id = 0 WHERE sender_id IS NULL"
    change_column_null :incoming_deliveries, :sender_id, false

    remove_column :incoming_delivery_lines, :amount
    remove_column :incoming_delivery_lines, :pretax_amount
    remove_column :incoming_delivery_lines, :price_id
    remove_column :incoming_delivery_lines, :weight
    change_column_null :incoming_delivery_lines, :purchase_line_id, true
    rename_column :incoming_delivery_lines, :warehouse_id, :container_id
    # # TODO How to manage appro
    # # TODO Build product before create
    # rename_column :incoming_delivery_lines, :product_id, :product_nature_id
    # # TODO Build create and create product after
    # add_column :incoming_delivery_lines, :product_quantity, :decimal, :precision => 19, :scale => 4
    # rename_column :incoming_delivery_lines, :product_id, :product_nature_id

    remove_column :incoming_delivery_lines, :unit_id
    remove_column :incoming_delivery_lines, :tracking_id



    rename_column :incoming_payment_modes, :published, :active

    rename_column :incoming_payments, :bank, :bank_name
    rename_column :incoming_payments, :account_number, :bank_account_number
    rename_column :incoming_payments, :check_number, :bank_check_number

    rename_column :journal_entries, :original_debit,         :real_debit
    rename_column :journal_entries, :original_credit,        :real_credit
    rename_column :journal_entries, :original_currency,      :real_currency
    rename_column :journal_entries, :original_currency_rate, :real_currency_rate
    add_column :journal_entries, :currency, :string, :limit => 3
    add_column :journal_entries, :absolute_debit, :decimal,  :precision => 19, :scale => 4, :null => false, :default => 0.0
    add_column :journal_entries, :absolute_credit, :decimal, :precision => 19, :scale => 4, :null => false, :default => 0.0
    add_column :journal_entries, :absolute_currency, :string, :limit => 3
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET currency = financial_year.currency FROM #{quoted_table_name(:financial_years)} AS financial_year WHERE financial_year.id = financial_year_id"
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET absolute_debit = debit, absolute_credit = credit, absolute_currency = currency"
    change_column_null :journal_entries, :absolute_currency, null: false
    change_column_null :journal_entries, :real_currency, null: false
    change_column_null :journal_entries, :currency, null: false
    change_column_default :journal_entries, :state, nil


    rename_column :journal_entry_lines, :original_debit,  :real_debit
    rename_column :journal_entry_lines, :original_credit, :real_credit
    add_column :journal_entry_lines, :real_currency, :string, :limit => 3
    add_column :journal_entry_lines, :real_currency_rate, :decimal,  :precision => 19, :scale => 10, :null => false, :default => 0.0
    add_column :journal_entry_lines, :financial_year_id, :integer
    add_column :journal_entry_lines, :printed_on, :date
    add_column :journal_entry_lines, :entry_number, :string
    add_column :journal_entry_lines, :currency, :string, :limit => 3
    add_column :journal_entry_lines, :absolute_debit, :decimal,  :precision => 19, :scale => 4, :null => false, :default => 0.0
    add_column :journal_entry_lines, :absolute_credit, :decimal, :precision => 19, :scale => 4, :null => false, :default => 0.0
    add_column :journal_entry_lines, :absolute_currency, :string, :limit => 3
    add_column :journal_entry_lines, :cumulated_absolute_debit, :decimal,  :precision => 19, :scale => 4, :null => false, :default => 0.0
    add_column :journal_entry_lines, :cumulated_absolute_credit, :decimal, :precision => 19, :scale => 4, :null => false, :default => 0.0

    duplicates = [:state, :journal_id, :financial_year_id, :printed_on, :real_currency, :real_currency_rate]
    execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET entry_number = entry.number, " + duplicates.collect{|c| "#{c} = entry.#{c}" }.join(", ") + " FROM #{quoted_table_name(:journal_entries)} AS entry WHERE entry.id = entry_id"
    for duplicate in duplicates
      change_column_null :journal_entry_lines, duplicate, false
    end
    execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET currency = financial_year.currency FROM #{quoted_table_name(:financial_years)} AS financial_year WHERE financial_year.id = financial_year_id"
    execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET absolute_debit = debit, absolute_credit = credit, absolute_currency = currency"
    # TODO update cumuls
    change_column_null :journal_entry_lines, :entry_number, false
    change_column_null :journal_entry_lines, :currency, false
    change_column_null :journal_entry_lines, :absolute_currency, false
    change_column_default :journal_entry_lines, :state, nil

    add_column :listing_nodes, :lft, :integer
    add_column :listing_nodes, :rgt, :integer
    add_column :listing_nodes, :depth, :integer, :null => false, :default => 0

    remove_column :outgoing_deliveries, :currency
    remove_column :outgoing_deliveries, :amount
    remove_column :outgoing_deliveries, :pretax_amount
    remove_column :outgoing_deliveries, :comment
    rename_column :outgoing_deliveries, :moved_on, :sent_at
    change_column :outgoing_deliveries, :sent_at, :datetime
    remove_column :outgoing_deliveries, :planned_on
    # rename_column :outgoing_deliveries, :planned_on, :planned_at
    # change_column :outgoing_deliveries, :planned_at, :datetime
    add_column :outgoing_deliveries, :recipient_id, :integer
    add_index :outgoing_deliveries, :recipient_id
    execute "UPDATE #{quoted_table_name(:outgoing_deliveries)} SET recipient_id = p.entity_id FROM #{quoted_table_name(:entity_addresses)} AS p WHERE p.id = address_id"
    execute "UPDATE #{quoted_table_name(:outgoing_deliveries)} SET recipient_id = 0 WHERE recipient_id IS NULL"
    change_column_null :outgoing_deliveries, :recipient_id, false
    change_column_null :outgoing_deliveries, :sale_id, true
    # FIXME Reference number Keep or not ?

    remove_column :outgoing_delivery_lines, :amount
    remove_column :outgoing_delivery_lines, :pretax_amount
    remove_column :outgoing_delivery_lines, :price_id
    change_column_null :outgoing_delivery_lines, :sale_line_id, true
    remove_column :outgoing_delivery_lines, :warehouse_id
    remove_column :outgoing_delivery_lines, :unit_id
    remove_column :outgoing_delivery_lines, :tracking_id
    # # TODO How to manage appro
    # # TODO Build product before create
    # rename_column :outgoing_delivery_lines, :product_id, :product_nature_id
    # # TODO Build create and create product after
    # add_column :outgoing_delivery_lines, :product_quantity, :decimal, :precision => 19, :scale => 4
    # rename_column :outgoing_delivery_lines, :product_id, :product_nature_id




    add_column :outgoing_payment_modes, :active, :boolean, :null => false, :default => false
    execute("UPDATE #{quoted_table_name(:outgoing_payment_modes)} SET active = #{quoted_true}")

    rename_column :outgoing_payments, :check_number, :bank_check_number
    add_column :outgoing_payments, :cash_id, :integer
    execute("UPDATE #{quoted_table_name(:outgoing_payments)} SET cash_id = m.cash_id FROM #{quoted_table_name(:outgoing_payment_modes)} AS m WHERE m.id = mode_id")
    change_column_null :outgoing_payments, :cash_id, false

    rename_column :prices, :entity_id, :supplier_id
    remove_column :prices, :use_range
    remove_column :prices, :quantity_min
    remove_column :prices, :quantity_max

    change_column :products, :nature, :string, :limit => 16
    execute "UPDATE #{quoted_table_name(:products)} SET nature = 'subscription' WHERE nature = 'subscrip'"
    remove_column :products, :service_coeff

    add_column :product_categories, :lft, :integer
    add_column :product_categories, :rgt, :integer
    add_column :product_categories, :depth, :integer, :null => false, :default => 0

    drop_table :production_chain_conveyors
    drop_table :production_chain_work_centers
    drop_table :production_chain_work_center_uses
    drop_table :production_chains

    drop_table :product_components

    change_column_null :purchase_lines, :account_id, false
    add_column :purchase_lines, :price_amount, :decimal, :precision => 19, :scale => 4
    add_column :purchase_lines, :tax_id, :integer
    execute "UPDATE #{quoted_table_name(:purchase_lines)} SET price_amount = p.pretax_amount, tax_id = p.tax_id FROM #{quoted_table_name(:prices)} AS p where p.id = price_id"
    change_column_null :purchase_lines, :price_amount, false
    change_column_null :purchase_lines, :tax_id, false
    add_index :purchase_lines, :tax_id

    remove_column :professions, :rome
    change_column :professions, :commercial, :boolean, :null => false, :default => false

    add_column :purchase_natures, :by_default, :boolean, :null => false, :default => false
    execute "UPDATE #{quoted_table_name(:purchase_natures)} SET by_default = true WHERE id IN (SELECT id FROM #{quoted_table_name(:purchase_natures)} ORDER BY id LIMIT 1)"
    change_column_default :purchase_natures, :active, true

    add_column :sale_natures, :by_default, :boolean, :null => false, :default => false
    execute "UPDATE #{quoted_table_name(:sale_natures)} SET by_default = true WHERE id IN (SELECT id FROM #{quoted_table_name(:sale_natures)} ORDER BY id LIMIT 1)"

    change_column_default :sales, :state, nil

    remove_column :sale_lines, :entity_id

    rename_column :subscriptions, :entity_id, :subscriber_id

    change_column :subscription_natures, :nature, :string, :size => 16
    add_column :subscription_natures, :entity_link_nature, :string, :limit => 127
    add_column :subscription_natures, :entity_link_direction, :string, :limit => 31
    remove_column :subscription_natures, :entity_link_nature_id

    rename_column :transfers, :supplier_id, :client_id
    change_column_null :transfers, :client_id, false

    rename_column :users, :departed_on, :departed_at
    change_column :users, :departed_at, :datetime
  end

  def down
    rename_column :entities, :reminder_submissive, :reflation_submissive

    add_column :prices, :quantity_max, :decimal, :precision => 19, :scale => 4
    add_column :prices, :quantity_min, :decimal, :precision => 19, :scale => 4
    add_column :prices, :use_range, :boolean, :null => false, :default => false

    add_column :products, :service_coeff, :decimal, :precision => 19, :scale => 4
    execute "UPDATE #{quoted_table_name(:products)} SET nature = 'subscrip' WHERE nature = 'subscription'"
    change_column :products, :nature, :string, :limit => 8

    # TODO Reverse migration
  end
end
