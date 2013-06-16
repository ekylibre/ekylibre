class NormalizeScoria < ActiveRecord::Migration
  def up
    rename_column :accounts, :is_debit, :debtor

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
    change_column_null :entities, :type, false
    change_column_null :entities, :nature, false
    remove_column :entities, :nature_id

    change_column :entity_links, :started_on, :datetime
    rename_column :entity_links, :started_on, :started_at
    change_column :entity_links, :stopped_on, :datetime
    rename_column :entity_links, :stopped_on, :stopped_at
    add_column :entity_links, :nature, :string
    execute("UPDATE entity_links SET nature = 'undefined'")

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

    create_table :meeting_participants do |t|
      t.references :meeting, :null => false
      t.references :entity,  :null => false
      t.string :status
      t.stamps
    end
    add_stamps_indexes :meeting_participants
    add_index :meeting_participants, :meeting_id
    add_index :meeting_participants, :entity_id


    rename_column :events, :reason, :name
    rename_column :events, :location, :place
    add_column :events, :description, :text
    add_column :events, :stopped_at, :datetime
    add_column :events, :type, :string
    execute("UPDATE #{quoted_table_name(:events)} SET type = 'Meeting', stopped_at = CASE WHEN duration IS NOT NULL THEN started_at + (duration || ' minutes')::INTERVAL ELSE stopped_at END")
    change_column_null :events, :type, false
    rename_column :events, :nature_id, :meeting_nature_id
    change_column_null :events, :meeting_nature_id, true
    remove_column :events, :started_sec
    remove_column :events, :responsible_id
    remove_column :events, :entity_id

    rename_column :incoming_payment_modes, :published, :active

    rename_column :incoming_payments, :bank, :bank_name
    rename_column :incoming_payments, :account_number, :bank_account_number
    rename_column :incoming_payments, :check_number, :bank_check_number

    add_column :listing_nodes, :lft, :integer
    add_column :listing_nodes, :rgt, :integer
    add_column :listing_nodes, :depth, :integer, :null => false, :default => 0

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

    drop_table :product_components

    change_column_null :purchase_lines, :account_id, false

    remove_column :professions, :rome
    change_column :professions, :commercial, :boolean, :null => false, :default => false

    add_column :purchase_natures, :by_default, :boolean, :null => false, :default => false
    execute "UPDATE #{quoted_table_name(:purchase_natures)} SET by_default = true WHERE id IN (SELECT id FROM #{quoted_table_name(:purchase_natures)} ORDER BY id LIMIT 1)"
    change_column_default :purchase_natures, :active, true

    add_column :sale_natures, :by_default, :boolean, :null => false, :default => false
    execute "UPDATE #{quoted_table_name(:sale_natures)} SET by_default = true WHERE id IN (SELECT id FROM #{quoted_table_name(:sale_natures)} ORDER BY id LIMIT 1)"

    change_column_default :sales, :state, nil

    change_column :subscription_natures, :nature, :string, :size => 16

    rename_column :transfers, :supplier_id, :client_id
    change_column_null :transfers, :client_id, false
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
