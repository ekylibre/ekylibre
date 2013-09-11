class CreateBase < ActiveRecord::Migration
  def up

    create_table :account_balances do |t|
      t.references :account,                                               null: false
      t.references :financial_year,                                        null: false
      t.decimal  :global_debit,      precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :global_credit,     precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :global_balance,    precision: 19, scale: 4, default: 0.0, null: false
      t.integer  :global_count,                               default: 0,   null: false
      t.decimal  :local_debit,       precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :local_credit,      precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :local_balance,     precision: 19, scale: 4, default: 0.0, null: false
      t.integer  :local_count,                                default: 0,   null: false
      t.stamps
    end
    add_index :account_balances, [:account_id], name: :index_account_balances_on_account_id
    add_index :account_balances, [:financial_year_id], name: :index_account_balances_on_financialyear_id

    create_table :accounts do |t|
      t.string   :number,       limit: 16,                  null: false
      t.string   :name,         limit: 208,                 null: false
      t.string   :label,                                    null: false
      t.boolean  :debtor,                   default: false, null: false
      t.string   :last_letter,  limit: 8
      t.text     :description
      t.boolean  :reconcilable,             default: false, null: false
      t.text     :usages
      t.stamps
    end

    create_table :activities do |t|
      t.string   :name,                     null: false
      t.string   :description
      t.string   :family
      t.string   :nature,                   null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.references :parent
      t.integer  :lft
      t.integer  :rgt
      t.integer  :depth
      t.stamps
    end
    add_index :activities, [:name], name: :index_activities_on_name
    add_index :activities, [:parent_id], name: :index_activities_on_parent_id

    create_table :affairs do |t|
      t.boolean  :closed,                                              default: false, null: false
      t.datetime :closed_at
      t.string   :currency,         limit: 3,                                          null: false
      t.decimal  :debit,                      precision: 19, scale: 4, default: 0.0,   null: false
      t.decimal  :credit,                     precision: 19, scale: 4, default: 0.0,   null: false
      t.datetime :accounted_at
      t.references :journal_entry
      t.stamps
    end
    add_index :affairs, [:journal_entry_id], name: :index_affairs_on_journal_entry_id

    create_table :analytic_repartitions do |t|
      t.references :production,                                               null: false
      t.references :journal_entry_item,                                       null: false
      t.string   :state,                                                       null: false
      t.date     :affected_on,                                                 null: false
      t.decimal  :affectation_percentage, precision: 19, scale: 4,             null: false
      t.stamps
    end
    add_index :analytic_repartitions, [:journal_entry_item_id], name: :index_analytic_repartitions_on_journal_entry_item_id
    add_index :analytic_repartitions, [:production_id], name: :index_analytic_repartitions_on_production_id

    create_table :areas do |t|
      t.string   :postcode,                              null: false
      t.string   :name,                                  null: false
      t.string   :country,      limit: 2, null: false
      t.references :district
      t.string   :city
      t.string   :city_name
      t.string   :code
      t.stamps
    end
    add_index :areas, [:district_id], name: :index_areas_on_district_id

    create_table :asset_depreciations do |t|
      t.references :asset,                                                    null: false
      t.references :journal_entry
      t.boolean  :accountable,                                 default: false, null: false
      t.date     :created_on,                                                  null: false
      t.datetime :accounted_at
      t.date     :started_on,                                                  null: false
      t.date     :stopped_on,                                                  null: false
      t.decimal  :amount,             precision: 19, scale: 4,                 null: false
      t.integer  :position
      t.boolean  :locked,                                      default: false, null: false
      t.references :financial_year
      t.decimal  :asset_amount,       precision: 19, scale: 4
      t.decimal  :depreciated_amount, precision: 19, scale: 4
      t.stamps
    end
    add_index :asset_depreciations, [:asset_id], name: :index_asset_depreciations_on_asset_id
    add_index :asset_depreciations, [:financial_year_id], name: :index_asset_depreciations_on_financial_year_id
    add_index :asset_depreciations, [:journal_entry_id], name: :index_asset_depreciations_on_journal_entry_id

    create_table :assets do |t|
      t.references :allocation_account,                                                  null: false
      t.references :journal,                                                             null: false
      t.string   :name,                                                                   null: false
      t.string   :number,                                                                 null: false
      t.text     :description
      t.date     :purchased_on
      t.references :purchase
      t.references :purchase_item
      t.boolean  :ceded
      t.date     :ceded_on
      t.references :sale
      t.references :sale_item
      t.decimal  :purchase_amount,                   precision: 19, scale: 4
      t.date     :started_on,                                                             null: false
      t.date     :stopped_on,                                                             null: false
      t.decimal  :depreciable_amount,                precision: 19, scale: 4,             null: false
      t.decimal  :depreciated_amount,                precision: 19, scale: 4,             null: false
      t.string   :depreciation_method,                                                    null: false
      t.string   :currency,                limit: 3
      t.decimal  :current_amount,                    precision: 19, scale: 4
      t.references :charges_account
      t.decimal  :depreciation_percentage,           precision: 19, scale: 4
      t.stamps
    end
    add_index :assets, [:allocation_account_id], name: :index_assets_on_account_id
    add_index :assets, [:charges_account_id], name: :index_assets_on_charges_account_id
    add_index :assets, [:currency], name: :index_assets_on_currency
    add_index :assets, [:journal_id], name: :index_assets_on_journal_id
    add_index :assets, [:purchase_id], name: :index_assets_on_purchase_id
    add_index :assets, [:purchase_item_id], name: :index_assets_on_purchase_item_id
    add_index :assets, [:sale_id], name: :index_assets_on_sale_id
    add_index :assets, [:sale_item_id], name: :index_assets_on_sale_item_id

    create_table :bank_statements do |t|
      t.references :cash,                                             null: false
      t.date     :started_on,                                          null: false
      t.date     :stopped_on,                                          null: false
      t.string   :number,                                              null: false
      t.decimal  :debit,        precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :credit,       precision: 19, scale: 4, default: 0.0, null: false
      t.stamps
    end
    add_index :bank_statements, [:cash_id], name: :index_bank_account_statements_on_bank_account_id

    create_table :campaigns do |t|
      t.string   :name,                         null: false
      t.string   :description
      t.boolean  :closed,       default: false, null: false
      t.datetime :closed_at
      t.stamps
    end
    add_index :campaigns, [:name], name: :index_campaigns_on_name

    create_table :cash_transfers do |t|
      t.references :emitter_cash,                                                   null: false
      t.references :receiver_cash,                                                  null: false
      t.references :emitter_journal_entry
      t.datetime :accounted_at
      t.string   :number,                                                            null: false
      t.text     :description
      t.decimal  :currency_rate,             precision: 19, scale: 10, default: 1.0, null: false
      t.decimal  :emitter_amount,            precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :receiver_amount,           precision: 19, scale: 4,  default: 0.0, null: false
      t.references :receiver_journal_entry
      t.date     :created_on
      t.stamps
    end
    add_index :cash_transfers, [:emitter_cash_id], name: :index_cash_transfers_on_emitter_cash_id
    add_index :cash_transfers, [:emitter_journal_entry_id], name: :index_cash_transfers_on_emitter_journal_entry_id
    add_index :cash_transfers, [:receiver_cash_id], name: :index_cash_transfers_on_receiver_cash_id
    add_index :cash_transfers, [:receiver_journal_entry_id], name: :index_cash_transfers_on_receiver_journal_entry_id

    create_table :cashes do |t|
      t.string   :name,                                                     null: false
      t.string   :iban,                 limit: 34
      t.string   :spaced_iban,          limit: 48
      t.string   :bank_identifier_code, limit: 16
      t.references :journal,                                               null: false
      t.references :account,                                               null: false
      t.string   :bank_code
      t.string   :bank_agency_code
      t.string   :bank_account_number
      t.string   :bank_account_key
      t.string   :mode,                            default: "iban",         null: false
      t.boolean  :by_default,                      default: false,          null: false
      t.text     :bank_agency_address
      t.string   :bank_name,            limit: 50
      t.string   :nature,               limit: 16, default: "bank_account", null: false
      t.string   :currency,             limit: 3
      t.string   :country,              limit: 2
      t.stamps
    end
    add_index :cashes, [:account_id], name: :index_bank_accounts_on_account_id
    add_index :cashes, [:currency], name: :index_cashes_on_currency
    add_index :cashes, [:journal_id], name: :index_bank_accounts_on_journal_id

    create_table :custom_field_choices do |t|
      t.references :custom_field,             null: false
      t.string   :name,                        null: false
      t.string   :value
      t.integer  :position
      t.stamps
    end
    add_index :custom_field_choices, [:custom_field_id], name: :index_complement_choices_on_complement_id

    create_table :custom_fields do |t|
      t.string   :name,                                                               null: false
      t.string   :nature,          limit: 8,                                          null: false
      t.integer  :position
      t.boolean  :active,                                             default: true,  null: false
      t.boolean  :required,                                           default: false, null: false
      t.integer  :maximal_length
      t.decimal  :minimal_value,             precision: 19, scale: 4
      t.decimal  :maximal_value,             precision: 19, scale: 4
      t.string   :customized_type,                                                    null: false
      t.integer  :minimal_length
      t.string   :column_name
      t.stamps
    end
    add_index :custom_fields, [:required], name: :index_complements_on_required

    create_table :departments do |t|
      t.string   :name,                         null: false
      t.text     :description
      t.references :parent
      t.text     :sales_conditions
      t.integer  :lft
      t.integer  :rgt
      t.integer  :depth,            default: 0, null: false
      t.stamps
    end
    add_index :departments, [:parent_id], name: :index_departments_on_parent_id

    create_table :deposit_items do |t|
      t.references :deposit,                                                    null: false
      t.decimal  :quantity,               precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :amount,                 precision: 19, scale: 4, default: 1.0, null: false
      t.string   :currency,     limit: 3,                                        null: false
      t.stamps
    end
    add_index :deposit_items, [:deposit_id], name: :index_deposit_items_on_deposit_id

    create_table :deposits do |t|
      t.decimal  :amount,           precision: 19, scale: 4, default: 0.0,   null: false
      t.integer  :payments_count,                            default: 0,     null: false
      t.date     :created_on,                                                null: false
      t.text     :description
      t.references :cash,                                                   null: false
      t.references :mode,                                                   null: false
      t.boolean  :locked,                                    default: false, null: false
      t.references :responsible
      t.string   :number
      t.datetime :accounted_at
      t.references :journal_entry
      t.boolean  :in_cash,                                   default: false, null: false
      t.stamps
    end
    add_index :deposits, [:cash_id], name: :index_deposits_on_cash_id
    add_index :deposits, [:journal_entry_id], name: :index_deposits_on_journal_entry_id
    add_index :deposits, [:mode_id], name: :index_deposits_on_mode_id
    add_index :deposits, [:responsible_id], name: :index_deposits_on_responsible_id

    create_table :districts do |t|
      t.string   :name,                     null: false
      t.string   :code
      t.stamps
    end

    create_table :document_archives do |t|
      t.references :document,                   null: false
      t.datetime :archived_at,                   null: false
      t.references :template
      t.string   :file_file_name
      t.integer  :file_file_size
      t.string   :file_content_type
      t.datetime :file_updated_at
      t.string   :file_fingerprint
      t.integer  :file_pages_count
      t.text     :file_content_text
      t.stamps
    end
    add_index :document_archives, [:document_id], name: :index_document_archives_on_document_id
    add_index :document_archives, [:template_id], name: :index_document_archives_on_template_id

    create_table :document_templates do |t|
      t.string   :name,                                    null: false
      t.boolean  :active,                  default: false, null: false
      t.boolean  :by_default,              default: false, null: false
      t.string   :nature,       limit: 63,                 null: false
      t.string   :language,     limit: 3,                  null: false
      t.string   :archiving,    limit: 63,                 null: false
      t.boolean  :managed,                 default: false, null: false
      t.string   :formats
      t.stamps
    end

    create_table :documents do |t|
      t.string   :number,         limit: 63,             null: false
      t.string   :name,                                  null: false
      t.string   :nature,         limit: 63,             null: false
      t.string   :key,                                   null: false
      t.integer  :archives_count,            default: 0, null: false
      t.stamps
    end
    add_index :documents, [:name], name: :index_documents_on_name
    add_index :documents, [:nature, :key], name: :index_documents_on_nature_and_key, unique: true
    add_index :documents, [:nature], name: :index_documents_on_nature
    add_index :documents, [:number], name: :index_documents_on_number

    create_table :entities do |t|
      t.string   :last_name,                                                                     null: false
      t.string   :first_name
      t.string   :full_name,                                                                     null: false
      t.string   :number,                    limit: 64
      t.boolean  :active,                                                        default: true,  null: false
      t.date     :born_on
      t.date     :dead_on
      t.string   :soundex,                   limit: 4
      t.boolean  :client,                                                        default: false, null: false
      t.boolean  :supplier,                                                      default: false, null: false
      t.references :client_account
      t.references :supplier_account
      t.boolean  :vat_subjected,                                                 default: true,  null: false
      t.boolean  :reminder_submissive,                                           default: false, null: false
      t.string   :deliveries_conditions,     limit: 60
      t.decimal  :discount_percentage,                  precision: 19, scale: 4
      t.decimal  :reduction_percentage,                 precision: 19, scale: 4
      t.text     :description
      t.string   :vat_number,                limit: 15
      t.string   :country,                   limit: 2
      t.integer  :authorized_payments_count
      t.references :responsible
      t.references :proposer
      t.references :payment_mode
      t.integer  :invoices_count
      t.date     :first_met_on
      t.references :sale_price_listing
      t.string   :siren,                     limit: 9
      t.string   :origin
      t.string   :webpass
      t.string   :activity_code,             limit: 32
      t.boolean  :transporter,                                                   default: false, null: false
      t.string   :language,                  limit: 3,                                           null: false
      t.boolean  :prospect,                                                      default: false, null: false
      t.boolean  :attorney,                                                      default: false, null: false
      t.references :attorney_account
      t.boolean  :locked,                                                        default: false, null: false
      t.string   :currency,                                                                      null: false
      t.boolean  :of_company,                                                    default: false, null: false
      t.string   :picture_file_name
      t.integer  :picture_file_size
      t.string   :picture_content_type
      t.datetime :picture_updated_at
      t.string   :type
      t.string   :nature,                                                                        null: false
      t.string   :payment_delay
      t.stamps
    end
    add_index :entities, [:attorney_account_id], name: :index_entities_on_attorney_account_id
    add_index :entities, [:client_account_id], name: :index_entities_on_client_account_id
    add_index :entities, [:number], name: :entities_codes
    add_index :entities, [:number], name: :index_entities_on_number
    add_index :entities, [:of_company], name: :index_entities_on_of_company
    add_index :entities, [:payment_mode_id], name: :index_entities_on_payment_mode_id
    add_index :entities, [:proposer_id], name: :index_entities_on_proposer_id
    add_index :entities, [:responsible_id], name: :index_entities_on_responsible_id
    add_index :entities, [:sale_price_listing_id], name: :index_entities_on_sale_price_listing_id
    add_index :entities, [:supplier_account_id], name: :index_entities_on_supplier_account_id

    create_table :entity_addresses do |t|
      t.references :entity,                                                           null: false
      t.boolean  :by_default,                                          default: false, null: false
      t.string   :mail_line_2
      t.string   :mail_line_3
      t.string   :mail_line_5
      t.string   :mail_country,     limit: 2
      t.string   :code,             limit: 4
      t.datetime :deleted_at
      t.references :mail_area
      t.string   :mail_line_6
      t.string   :mail_line_4
      t.string   :canal,            limit: 16,                                         null: false
      t.string   :coordinate,       limit: 511,                                        null: false
      t.string   :name
      t.string   :mail_line_1
      t.point    :mail_geolocation, has_z: true
      t.boolean  :mail_auto_update,                                    default: false, null: false
      t.stamps
    end
    add_index :entity_addresses, [:by_default], name: :index_entity_addresses_on_by_default
    add_index :entity_addresses, [:code], name: :index_entity_addresses_on_code
    add_index :entity_addresses, [:deleted_at], name: :index_entity_addresses_on_deleted_at
    add_index :entity_addresses, [:entity_id], name: :index_entity_addresses_on_entity_id
    add_index :entity_addresses, [:mail_area_id], name: :index_entity_addresses_on_mail_area_id

    create_table :entity_links do |t|
      t.references :entity_1,              null: false
      t.references :entity_2,              null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.text     :description
      t.string   :nature,                   null: false
      t.stamps
    end
    add_index :entity_links, [:entity_1_id], name: :index_entity_links_on_entity1_id
    add_index :entity_links, [:entity_2_id], name: :index_entity_links_on_entity2_id

    create_table :establishments do |t|
      t.string   :name,                     null: false
      t.string   :code
      t.text     :description
      t.stamps
    end

    create_table :events do |t|
      t.string   :place
      t.integer  :duration
      t.datetime :started_at,                    null: false
      t.text     :name
      t.references :meeting_nature
      t.text     :description
      t.datetime :stopped_at
      t.string   :type
      t.references :procedure
      t.stamps
    end
    add_index :events, [:meeting_nature_id], name: :index_events_on_meeting_nature_id
    add_index :events, [:procedure_id], name: :index_events_on_procedure_id

    create_table :financial_years do |t|
      t.string   :code,                  limit: 12,                 null: false
      t.boolean  :closed,                           default: false, null: false
      t.date     :started_on,                                       null: false
      t.date     :stopped_on,                                       null: false
      t.string   :currency,              limit: 3
      t.integer  :currency_precision
      t.references :last_journal_entry
      t.stamps
    end
    add_index :financial_years, [:currency], name: :index_financial_years_on_currency
    add_index :financial_years, [:last_journal_entry_id], name: :index_financial_years_on_last_journal_entry_id

    create_table :incidents do |t|
      t.references :target,    polymorphic: true, null: false
      t.string   :nature,                         null: false
      t.datetime :observed_at,                    null: false
      t.integer  :priority
      t.integer  :gravity
      t.string   :state
      t.string   :name,                           null: false
      t.text     :description
      t.stamps
    end
    add_index :incidents, [:name], name: :index_incidents_on_name
    add_index :incidents, [:nature], name: :index_incidents_on_nature
    add_index :incidents, [:target_id, :target_type], name: :index_incidents_on_target_id_and_target_type

    create_table :incoming_deliveries do |t|
      t.references :purchase
      t.references :address
      t.datetime :received_at
      t.decimal  :weight,           precision: 19, scale: 4
      t.references :mode
      t.string   :number
      t.string   :reference_number
      t.references :sender,                                             null: false
      t.stamps
    end
    add_index :incoming_deliveries, [:address_id], name: :index_incoming_deliveries_on_address_id
    add_index :incoming_deliveries, [:mode_id], name: :index_incoming_deliveries_on_mode_id
    add_index :incoming_deliveries, [:purchase_id], name: :index_incoming_deliveries_on_purchase_id
    add_index :incoming_deliveries, [:sender_id], name: :index_incoming_deliveries_on_sender_id

    create_table :incoming_delivery_items do |t|
      t.references :delivery,                                             null: false
      t.references :purchase_item
      t.references :product,                                              null: false
      t.decimal  :quantity,         precision: 19, scale: 4, default: 1.0, null: false
      t.references :container
      t.references :move
      t.stamps
    end
    add_index :incoming_delivery_items, [:delivery_id], name: :index_incoming_delivery_items_on_delivery_id
    add_index :incoming_delivery_items, [:move_id], name: :index_incoming_delivery_items_on_move_id
    add_index :incoming_delivery_items, [:product_id], name: :index_incoming_delivery_items_on_product_id
    add_index :incoming_delivery_items, [:purchase_item_id], name: :index_incoming_delivery_items_on_purchase_item_id

    create_table :incoming_delivery_modes do |t|
      t.string   :name,                               null: false
      t.string   :code,         limit: 8,             null: false
      t.text     :description
      t.stamps
    end

    create_table :incoming_payment_modes do |t|
      t.string   :name,                    limit: 50,                                          null: false
      t.references :depositables_account
      t.references :cash
      t.boolean  :active,                                                      default: false
      t.boolean  :with_accounting,                                             default: false, null: false
      t.boolean  :with_deposit,                                                default: false, null: false
      t.boolean  :with_commission,                                             default: false, null: false
      t.decimal  :commission_percentage,              precision: 19, scale: 4, default: 0.0,   null: false
      t.decimal  :commission_base_amount,             precision: 19, scale: 4, default: 0.0,   null: false
      t.references :commission_account
      t.integer  :position
      t.references :depositables_journal
      t.boolean  :detail_payments,                                             default: false, null: false
      t.references :attorney_journal
      t.stamps
    end
    add_index :incoming_payment_modes, [:attorney_journal_id], name: :index_incoming_payment_modes_on_attorney_journal_id
    add_index :incoming_payment_modes, [:cash_id], name: :index_incoming_payment_modes_on_cash_id
    add_index :incoming_payment_modes, [:commission_account_id], name: :index_incoming_payment_modes_on_commission_account_id
    add_index :incoming_payment_modes, [:depositables_account_id], name: :index_incoming_payment_modes_on_depositables_account_id
    add_index :incoming_payment_modes, [:depositables_journal_id], name: :index_incoming_payment_modes_on_depositables_journal_id

    create_table :incoming_payments do |t|
      t.date     :paid_on
      t.decimal  :amount,                          precision: 19, scale: 4,                        null: false
      t.references :mode,                                                                         null: false
      t.string   :bank_name
      t.string   :bank_check_number
      t.string   :bank_account_number
      t.references :payer
      t.date     :to_bank_on,                                               default: '0001-01-01', null: false
      t.references :deposit
      t.references :responsible
      t.boolean  :scheduled,                                                default: false,        null: false
      t.boolean  :received,                                                 default: true,         null: false
      t.string   :number
      t.date     :created_on
      t.datetime :accounted_at
      t.text     :receipt
      t.references :journal_entry
      t.references :commission_account
      t.decimal  :commission_amount,               precision: 19, scale: 4, default: 0.0,          null: false
      t.string   :currency,              limit: 3,                                                 null: false
      t.boolean  :downpayment,                                              default: true,         null: false
      t.references :affair
      t.stamps
    end
    add_index :incoming_payments, [:accounted_at], name: :index_payments_on_accounted_at
    add_index :incoming_payments, [:affair_id], name: :index_incoming_payments_on_affair_id
    add_index :incoming_payments, [:commission_account_id], name: :index_incoming_payments_on_commission_account_id
    add_index :incoming_payments, [:deposit_id], name: :index_incoming_payments_on_deposit_id
    add_index :incoming_payments, [:journal_entry_id], name: :index_incoming_payments_on_journal_entry_id
    add_index :incoming_payments, [:mode_id], name: :index_incoming_payments_on_mode_id
    add_index :incoming_payments, [:payer_id], name: :index_incoming_payments_on_payer_id
    add_index :incoming_payments, [:responsible_id], name: :index_incoming_payments_on_responsible_id

    create_table :inventories do |t|
      t.date     :created_on,                               null: false
      t.text     :description
      t.boolean  :changes_reflected
      t.references :responsible
      t.datetime :accounted_at
      t.references :journal_entry
      t.string   :number,            limit: 16
      t.date     :moved_on
      t.stamps
    end
    add_index :inventories, [:journal_entry_id], name: :index_inventories_on_journal_entry_id
    add_index :inventories, [:responsible_id], name: :index_inventories_on_responsible_id

    create_table :inventory_items do |t|
      t.references :product,                                            null: false
      t.references :warehouse,                                          null: false
      t.decimal  :theoric_quantity, precision: 19, scale: 4,             null: false
      t.decimal  :quantity,         precision: 19, scale: 4,             null: false
      t.references :inventory,                                          null: false
      t.references :tracking
      t.references :move
      t.string   :unit
      t.stamps
    end
    add_index :inventory_items, [:inventory_id], name: :index_inventory_items_on_inventory_id
    add_index :inventory_items, [:move_id], name: :index_inventory_items_on_move_id
    add_index :inventory_items, [:product_id], name: :index_inventory_items_on_product_id
    add_index :inventory_items, [:tracking_id], name: :index_inventory_items_on_tracking_id
    add_index :inventory_items, [:unit], name: :index_inventory_items_on_unit

    create_table :journal_entries do |t|
      t.references :resource, polymorphic: true
      t.date     :created_on,                                                            null: false
      t.date     :printed_on,                                                            null: false
      t.string   :number,                                                                null: false
      t.decimal  :debit,                         precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :credit,                        precision: 19, scale: 4,  default: 0.0, null: false
      t.references :journal,                                                            null: false
      t.decimal  :real_debit,                    precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :real_credit,                   precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :real_currency_rate,            precision: 19, scale: 10, default: 0.0, null: false
      t.string   :state,              limit: 32,                                         null: false
      t.decimal  :balance,                       precision: 19, scale: 4,  default: 0.0, null: false
      t.string   :real_currency,      limit: 3
      t.references :financial_year
      t.string   :currency,           limit: 3
      t.decimal  :absolute_debit,                precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :absolute_credit,               precision: 19, scale: 4,  default: 0.0, null: false
      t.string   :absolute_currency,  limit: 3
      t.stamps
    end
    add_index :journal_entries, [:financial_year_id], name: :index_journal_entries_on_financial_year_id
    add_index :journal_entries, [:journal_id], name: :index_journal_records_on_journal_id
    add_index :journal_entries, [:real_currency], name: :index_journal_entries_on_currency
    add_index :journal_entries, [:resource_id, :resource_type], name: :index_journal_entries_on_resource_id_and_resource_type

    create_table :journal_entry_items do |t|
      t.references :entry,                                                                     null: false
      t.references :journal,                                                                   null: false
      t.string   :state,                     limit: 32,                                         null: false
      t.references :financial_year,                                                            null: false
      t.date     :printed_on,                                                                   null: false
      t.string   :entry_number,                                                                 null: false
      t.references :account,                                                                   null: false
      t.string   :name,                                                                         null: false
      t.decimal  :real_debit,                           precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :real_credit,                          precision: 19, scale: 4,  default: 0.0, null: false
      t.string   :real_currency,             limit: 3,                                          null: false
      t.decimal  :real_currency_rate,                   precision: 19, scale: 10, default: 0.0, null: false
      t.decimal  :debit,                                precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :credit,                               precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :balance,                              precision: 19, scale: 4,  default: 0.0, null: false
      t.string   :currency,                  limit: 3,                                          null: false
      t.references :bank_statement
      t.string   :letter,                    limit: 8
      t.integer  :position
      t.text     :description
      t.decimal  :absolute_debit,                       precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :absolute_credit,                      precision: 19, scale: 4,  default: 0.0, null: false
      t.string   :absolute_currency,         limit: 3,                                          null: false
      t.decimal  :cumulated_absolute_debit,             precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal  :cumulated_absolute_credit,            precision: 19, scale: 4,  default: 0.0, null: false
      t.stamps
    end
    add_index :journal_entry_items, [:account_id], name: :index_journal_entry_items_on_account_id
    add_index :journal_entry_items, [:bank_statement_id], name: :index_journal_entry_items_on_bank_statement_id
    add_index :journal_entry_items, [:entry_id], name: :index_journal_entry_items_on_entry_id
    add_index :journal_entry_items, [:journal_id], name: :index_journal_entry_items_on_journal_id
    add_index :journal_entry_items, [:letter], name: :index_journal_entry_items_on_letter
    add_index :journal_entry_items, [:name], name: :index_journal_entry_items_on_name

    create_table :journals do |t|
      t.string   :nature,       limit: 16,             null: false
      t.string   :name,                                null: false
      t.string   :code,         limit: 4,              null: false
      t.date     :closed_on,                           null: false
      t.string   :currency,     limit: 3
      t.stamps
    end
    add_index :journals, [:currency], name: :index_journals_on_currency

    create_table :listing_node_items do |t|
      t.references :node,                            null: false
      t.string   :nature,       limit: 8,             null: false
      t.text     :value
      t.stamps
    end
    add_index :listing_node_items, [:node_id], name: :index_listing_node_items_on_node_id

    create_table :listing_nodes do |t|
      t.string   :name,                                          null: false
      t.string   :label,                                         null: false
      t.string   :nature,                                        null: false
      t.integer  :position
      t.boolean  :exportable,                     default: true, null: false
      t.references :parent
      t.string   :item_nature,          limit: 8
      t.text     :item_value
      t.references :item_listing
      t.references :item_listing_node
      t.references :listing,                                    null: false
      t.string   :key
      t.string   :sql_type
      t.string   :condition_value
      t.string   :condition_operator
      t.string   :attribute_name
      t.integer  :lft
      t.integer  :rgt
      t.integer  :depth,                          default: 0,    null: false
      t.stamps
    end
    add_index :listing_nodes, [:exportable], name: :index_listing_nodes_on_exportable
    add_index :listing_nodes, [:item_listing_id], name: :index_listing_nodes_on_item_listing_id
    add_index :listing_nodes, [:item_listing_node_id], name: :index_listing_nodes_on_item_listing_node_id
    add_index :listing_nodes, [:listing_id], name: :index_listing_nodes_on_listing_id
    add_index :listing_nodes, [:name], name: :index_listing_nodes_on_name
    add_index :listing_nodes, [:nature], name: :index_listing_nodes_on_nature
    add_index :listing_nodes, [:parent_id], name: :index_listing_nodes_on_parent_id

    create_table :listings do |t|
      t.string   :name,                     null: false
      t.string   :root_model,               null: false
      t.text     :query
      t.text     :description
      t.text     :story
      t.text     :conditions
      t.text     :mail
      t.text     :source
      t.stamps
    end
    add_index :listings, [:name], name: :index_listings_on_name
    add_index :listings, [:root_model], name: :index_listings_on_root_model

    create_table :logs do |t|
      t.string     :event,                             null: false
      t.datetime   :observed_at,                       null: false
      t.references :owner,          polymorphic: true, null: false
      t.text       :owner_object
      t.references :origin,         polymorphic: true
      t.text       :origin_object
      t.text       :description
      t.stamps
    end
    add_index :logs, [:description], name: :index_logs_on_description
    add_index :logs, [:observed_at], name: :index_logs_on_observed_at
    add_index :logs, [:origin_type, :origin_id], name: :index_logs_on_origin_type_and_origin_id
    add_index :logs, [:owner_type, :owner_id], name: :index_logs_on_owner_type_and_owner_id

    create_table :mandates do |t|
      t.date     :started_on
      t.date     :stopped_on
      t.string   :family,                   null: false
      t.string   :organization,             null: false
      t.string   :title,                    null: false
      t.references :entity,                null: false
      t.stamps
    end
    add_index :mandates, [:entity_id], name: :index_mandates_on_entity_id

    create_table :meeting_natures do |t|
      t.string   :name,                                   null: false
      t.integer  :duration
      t.string   :usage,        limit: 64
      t.boolean  :active,                  default: true, null: false
      t.stamps
    end
    add_index :meeting_natures, [:name], name: :index_meeting_natures_on_name

    create_table :meeting_participations do |t|
      t.references :meeting,                 null: false
      t.references :participant,             null: false
      t.string   :state
      t.stamps
    end
    add_index :meeting_participations, [:meeting_id], name: :index_meeting_participations_on_meeting_id
    add_index :meeting_participations, [:participant_id], name: :index_meeting_participations_on_participant_id

    create_table :observations do |t|
      t.string   :importance,   limit: 10,             null: false
      t.text     :content,                             null: false
      t.references :subject,    polymorphic: true,     null: false
      t.datetime :observed_at,                         null: false
      t.references :author,                            null: false
      t.stamps
    end
    add_index :observations, [:author_id], name: :index_observations_on_author_id
    add_index :observations, [:subject_id, :subject_type], name: :index_observations_on_subject_id_and_subject_type

    create_table :operation_tasks do |t|
      t.references :operation,                                                null: false
      t.references :parent
      t.boolean  :prorated,                                    default: false, null: false
      t.references :subject,                                                  null: false
      t.string   :verb,                                                        null: false
      t.references :operand
      t.string   :operand_unit
      t.decimal  :operand_quantity,   precision: 19, scale: 4
      t.references :indicator_datum
      t.text     :expression
      t.stamps
    end
    add_index :operation_tasks, [:indicator_datum_id], name: :index_operation_tasks_on_indicator_datum_id
    add_index :operation_tasks, [:operand_id], name: :index_operation_tasks_on_operand_id
    add_index :operation_tasks, [:operand_unit], name: :index_operation_tasks_on_operand_unit
    add_index :operation_tasks, [:operation_id], name: :index_operation_tasks_on_operation_id
    add_index :operation_tasks, [:parent_id], name: :index_operation_tasks_on_parent_id
    add_index :operation_tasks, [:subject_id], name: :index_operation_tasks_on_subject_id

    create_table :outgoing_deliveries do |t|
      t.references :sale
      t.references :address
      t.datetime :sent_at
      t.references :mode
      t.decimal  :weight,           precision: 19, scale: 4
      t.references :transport
      t.references :transporter
      t.string   :number
      t.string   :reference_number
      t.references :recipient,                                          null: false
      t.stamps
    end
    add_index :outgoing_deliveries, [:address_id], name: :index_outgoing_deliveries_on_address_id
    add_index :outgoing_deliveries, [:mode_id], name: :index_outgoing_deliveries_on_mode_id
    add_index :outgoing_deliveries, [:recipient_id], name: :index_outgoing_deliveries_on_recipient_id
    add_index :outgoing_deliveries, [:sale_id], name: :index_outgoing_deliveries_on_sales_order_id
    add_index :outgoing_deliveries, [:transport_id], name: :index_outgoing_deliveries_on_transport_id
    add_index :outgoing_deliveries, [:transporter_id], name: :index_outgoing_deliveries_on_transporter_id

    create_table :outgoing_delivery_items do |t|
      t.references :delivery,                                         null: false
      t.references :sale_item
      t.references :product,                                          null: false
      t.decimal  :quantity,     precision: 19, scale: 4, default: 1.0, null: false
      t.references :move
      t.stamps
    end
    add_index :outgoing_delivery_items, [:delivery_id], name: :index_outgoing_delivery_items_on_delivery_id
    add_index :outgoing_delivery_items, [:move_id], name: :index_outgoing_delivery_items_on_move_id
    add_index :outgoing_delivery_items, [:product_id], name: :index_outgoing_delivery_items_on_product_id
    add_index :outgoing_delivery_items, [:sale_item_id], name: :index_outgoing_delivery_items_on_sale_item_id

    create_table :outgoing_delivery_modes do |t|
      t.string   :name,                                     null: false
      t.string   :code,           limit: 8,                 null: false
      t.text     :description
      t.boolean  :with_transport,           default: false, null: false
      t.stamps
    end

    create_table :outgoing_payment_modes do |t|
      t.string   :name,                limit: 50,                 null: false
      t.boolean  :with_accounting,                default: false, null: false
      t.references :cash
      t.integer  :position
      t.references :attorney_journal
      t.boolean  :active,                         default: false, null: false
      t.stamps
    end
    add_index :outgoing_payment_modes, [:attorney_journal_id], name: :index_outgoing_payment_modes_on_attorney_journal_id
    add_index :outgoing_payment_modes, [:cash_id], name: :index_outgoing_payment_modes_on_cash_id

    create_table :outgoing_payments do |t|
      t.datetime :accounted_at
      t.decimal  :amount,                      precision: 19, scale: 4, default: 0.0,  null: false
      t.string   :bank_check_number
      t.boolean  :delivered,                                            default: true, null: false
      t.date     :created_on
      t.references :journal_entry
      t.references :responsible,                                                      null: false
      t.references :payee,                                                            null: false
      t.references :mode,                                                             null: false
      t.string   :number
      t.date     :paid_on
      t.date     :to_bank_on,                                                          null: false
      t.references :cash,                                                             null: false
      t.string   :currency,          limit: 3,                                         null: false
      t.boolean  :downpayment,                                          default: true, null: false
      t.references :affair
      t.stamps
    end
    add_index :outgoing_payments, [:affair_id], name: :index_outgoing_payments_on_affair_id
    add_index :outgoing_payments, [:cash_id], name: :index_outgoing_payments_on_cash_id
    add_index :outgoing_payments, [:journal_entry_id], name: :index_outgoing_payments_on_journal_entry_id
    add_index :outgoing_payments, [:mode_id], name: :index_outgoing_payments_on_mode_id
    add_index :outgoing_payments, [:payee_id], name: :index_outgoing_payments_on_payee_id
    add_index :outgoing_payments, [:responsible_id], name: :index_outgoing_payments_on_responsible_id

    create_table :preferences do |t|
      t.string   :name,                                                               null: false
      t.string   :nature,            limit: 8,                                        null: false
      t.text     :string_value
      t.boolean  :boolean_value
      t.integer  :integer_value
      t.decimal  :decimal_value,               precision: 19, scale: 4
      t.references :user
      t.references :record_value, polymorphic: true
      t.stamps
    end
    add_index :preferences, [:name], name: :index_parameters_on_name
    add_index :preferences, [:nature], name: :index_parameters_on_nature
    add_index :preferences, [:record_value_id, :record_value_type], name: :index_preferences_on_record_value_id_and_record_value_type
    add_index :preferences, [:user_id], name: :index_parameters_on_user_id

    create_table :prescriptions do |t|
      t.references :document
      t.references :prescriptor
      t.string   :reference_number
      t.date     :delivered_on
      t.text     :description
      t.stamps
    end
    add_index :prescriptions, [:document_id], name: :index_prescriptions_on_document_id
    add_index :prescriptions, [:prescriptor_id], name: :index_prescriptions_on_prescriptor_id
    add_index :prescriptions, [:reference_number], name: :index_prescriptions_on_reference_number

    create_table :procedure_variables do |t|
      t.references :procedure,                                          null: false
      t.references :target,                                             null: false
      t.string   :indicator,                                             null: false
      t.string   :measure_unit,                                          null: false
      t.decimal  :measure_quantity, precision: 19, scale: 4,             null: false
      t.string   :role,                                                  null: false
      t.stamps
    end
    add_index :procedure_variables, [:procedure_id], name: :index_procedure_variables_on_procedure_id
    add_index :procedure_variables, [:target_id], name: :index_procedure_variables_on_target_id

    create_table :procedures do |t|
      t.references :provisional_procedure
      t.boolean  :provisional,              default: false,    null: false
      t.references :incident
      t.references :prescription
      t.references :production,                               null: false
      t.string   :nomen,                                       null: false
      t.string   :natures,                                     null: false
      t.string   :state,                                       null: false
      t.stamps
    end
    add_index :procedures, [:incident_id], name: :index_procedures_on_incident_id
    add_index :procedures, [:nomen], name: :index_procedures_on_nomen
    add_index :procedures, [:prescription_id], name: :index_procedures_on_prescription_id
    add_index :procedures, [:production_id], name: :index_procedures_on_production_id
    add_index :procedures, [:provisional_procedure_id], name: :index_procedures_on_provisional_procedure_id

    create_table :product_indicator_data do |t|
      t.references :product,                                                                                         null: false
      t.string   :indicator,                                                                                          null: false
      t.string   :indicator_datatype,                                                                                 null: false
      t.datetime :measured_at,                                                                                        null: false
      t.decimal  :decimal_value,                                             precision: 19, scale: 4
      t.decimal  :measure_value_value,                                       precision: 19, scale: 4
      t.string   :measure_value_unit
      t.text     :string_value
      t.boolean  :boolean_value,                                                                      default: false, null: false
      t.string   :choice_value
      t.point    :point_value, has_z: true
      t.geometry :geometry_value, has_z: true
      t.multi_polygon :multi_polygon_value, has_z: true
      t.stamps
    end
    add_index :product_indicator_data, [:indicator], name: :index_product_indicator_data_on_indicator
    add_index :product_indicator_data, [:measured_at], name: :index_product_indicator_data_on_measured_at
    add_index :product_indicator_data, [:product_id], name: :index_product_indicator_data_on_product_id

    create_table :product_links do |t|
      t.references :carrier,                    null: false
      t.references :carried,                    null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.references :operation_task
      t.stamps
    end
    add_index :product_links, [:carried_id], name: :index_product_links_on_carried_id
    add_index :product_links, [:carrier_id], name: :index_product_links_on_carrier_id
    add_index :product_links, [:operation_task_id], name: :index_product_links_on_operation_task_id
    add_index :product_links, [:started_at], name: :index_product_links_on_started_at
    add_index :product_links, [:stopped_at], name: :index_product_links_on_stopped_at

    create_table :product_localizations do |t|
      t.references :product,                    null: false
      t.string   :nature,                        null: false
      t.references :container
      t.string   :arrival_cause
      t.string   :departure_cause
      t.datetime :started_at
      t.datetime :stopped_at
      t.references :operation_task
      t.stamps
    end
    add_index :product_localizations, [:container_id], name: :index_product_localizations_on_container_id
    add_index :product_localizations, [:operation_task_id], name: :index_product_localizations_on_operation_task_id
    add_index :product_localizations, [:product_id], name: :index_product_localizations_on_product_id
    add_index :product_localizations, [:started_at], name: :index_product_localizations_on_started_at
    add_index :product_localizations, [:stopped_at], name: :index_product_localizations_on_stopped_at

    create_table :product_memberships do |t|
      t.references :member,                     null: false
      t.references :group,                      null: false
      t.datetime :started_at,                    null: false
      t.datetime :stopped_at
      t.references :operation_task
      t.stamps
    end
    add_index :product_memberships, [:group_id], name: :index_product_memberships_on_group_id
    add_index :product_memberships, [:member_id], name: :index_product_memberships_on_member_id
    add_index :product_memberships, [:operation_task_id], name: :index_product_memberships_on_operation_task_id
    add_index :product_memberships, [:started_at], name: :index_product_memberships_on_started_at
    add_index :product_memberships, [:stopped_at], name: :index_product_memberships_on_stopped_at

    create_table :product_moves do |t|
      t.references :product,                                                null: false
      t.decimal  :population_delta, precision: 19, scale: 4,                 null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.boolean  :initial,                                   default: false, null: false
      t.stamps
    end
    add_index :product_moves, [:product_id], name: :index_product_moves_on_product_id
    add_index :product_moves, [:started_at], name: :index_product_moves_on_started_at
    add_index :product_moves, [:stopped_at], name: :index_product_moves_on_stopped_at

    create_table :product_nature_variant_indicator_data do |t|
      t.references :variant,                                                                                         null: false
      t.string   :indicator,                                                                                          null: false
      t.string   :indicator_datatype,                                                                                 null: false
      t.string   :computation_method,                                                                                 null: false
      t.decimal  :decimal_value,                                             precision: 19, scale: 4
      t.decimal  :measure_value_value,                                       precision: 19, scale: 4
      t.string   :measure_value_unit
      t.text     :string_value
      t.boolean  :boolean_value,                                                                      default: false, null: false
      t.string   :choice_value
      t.point    :point_value, has_z: true
      t.geometry :geometry_value, has_z: true
      t.multi_polygon :multi_polygon_value, has_z: true
      t.stamps
    end
    add_index :product_nature_variant_indicator_data, [:indicator], name: :index_product_nature_variant_indicator_data_on_indicator
    add_index :product_nature_variant_indicator_data, [:variant_id], name: :index_product_nature_variant_indicator_data_on_variant_id

    create_table :product_nature_variants do |t|
      t.references :nature,                              null: false
      t.string   :name
      t.string   :number
      t.string   :nature_name,                            null: false
      t.string   :unit_name,                              null: false
      t.string   :commercial_name,                        null: false
      t.text     :commercial_description
      t.text     :frozen_indicators
      t.text     :variable_indicators
      t.boolean  :active,                 default: false, null: false
      t.string   :picture_file_name
      t.string   :picture_content_type
      t.integer  :picture_file_size
      t.datetime :picture_updated_at
      t.string   :contour
      t.integer  :horizontal_rotation,    default: 0,     null: false
      t.stamps
    end
    add_index :product_nature_variants, [:nature_id], name: :index_product_nature_variants_on_nature_id

    create_table :product_natures do |t|
      t.string   :name,                                               null: false
      t.string   :number,                 limit: 31,                  null: false
      t.text     :description
      t.string   :variety,                limit: 127,                 null: false
      t.string   :derivative_of,          limit: 127
      t.string   :nomen,                  limit: 127
      t.text     :abilities
      t.text     :indicators
      t.string   :population_counting,                                null: false
      t.boolean  :active,                             default: false, null: false
      t.boolean  :depreciable,                        default: false, null: false
      t.boolean  :saleable,                           default: false, null: false
      t.boolean  :purchasable,                        default: false, null: false
      t.boolean  :storable,                           default: false, null: false
      t.boolean  :reductible,                         default: false, null: false
      t.boolean  :subscribing,                        default: false, null: false
      t.references :subscription_nature
      t.string   :subscription_duration
      t.references :charge_account
      t.references :product_account
      t.references :asset_account
      t.references :stock_account
      t.stamps
    end
    add_index :product_natures, [:asset_account_id], name: :index_product_natures_on_asset_account_id
    add_index :product_natures, [:charge_account_id], name: :index_product_natures_on_charge_account_id
    add_index :product_natures, [:number], name: :index_product_natures_on_number, unique: true
    add_index :product_natures, [:product_account_id], name: :index_product_natures_on_product_account_id
    add_index :product_natures, [:stock_account_id], name: :index_product_natures_on_stock_account_id
    add_index :product_natures, [:subscription_nature_id], name: :index_product_natures_on_subscription_nature_id
    add_index :product_natures, [:variety], name: :index_product_natures_on_variety

    create_table :product_ownerships do |t|
      t.references :product,               null: false
      t.string   :nature,                   null: false
      t.references :owner
      t.datetime :started_at
      t.datetime :stopped_at
      t.stamps
    end
    add_index :product_ownerships, [:owner_id], name: :index_product_ownerships_on_owner_id
    add_index :product_ownerships, [:product_id], name: :index_product_ownerships_on_product_id
    add_index :product_ownerships, [:started_at], name: :index_product_ownerships_on_started_at
    add_index :product_ownerships, [:stopped_at], name: :index_product_ownerships_on_stopped_at

    create_table :product_price_listings do |t|
      t.string   :name,                                   null: false
      t.text     :description
      t.boolean  :by_default,             default: false, null: false
      t.string   :code,         limit: 8
      t.stamps
    end

    create_table :product_prices do |t|
      t.references :product
      t.references :variant,                                                   null: false
      t.references :listing
      t.references :supplier,                                                  null: false
      t.decimal  :pretax_amount,           precision: 19, scale: 4,             null: false
      t.decimal  :amount,                  precision: 19, scale: 4,             null: false
      t.references :tax,                                                       null: false
      t.string   :currency,      limit: 3,                                      null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.stamps
    end
    add_index :product_prices, [:listing_id], name: :index_product_prices_on_listing_id
    add_index :product_prices, [:product_id], name: :index_product_prices_on_product_id
    add_index :product_prices, [:supplier_id], name: :index_product_prices_on_supplier_id
    add_index :product_prices, [:tax_id], name: :index_product_prices_on_tax_id
    add_index :product_prices, [:variant_id], name: :index_product_prices_on_variant_id

    create_table :product_process_phases do |t|
      t.references :process,               null: false
      t.string   :name,                     null: false
      t.string   :nature,                   null: false
      t.integer  :position
      t.string   :phase_delay
      t.string   :description
      t.stamps
    end
    add_index :product_process_phases, [:process_id], name: :index_product_process_phases_on_process_id

    create_table :product_processes do |t|
      t.string   :variety,      limit: 127,                 null: false
      t.string   :name,                                     null: false
      t.string   :nature,                                   null: false
      t.string   :description
      t.boolean  :repeatable,               default: false, null: false
      t.stamps
    end
    add_index :product_processes, [:variety], name: :index_product_processes_on_variety

    create_table :production_supports do |t|
      t.references :production,                 null: false
      t.references :storage,                    null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.boolean  :exclusive,     default: false, null: false
      t.stamps
    end
    add_index :production_supports, [:production_id], name: :index_production_supports_on_production_id
    add_index :production_supports, [:storage_id], name: :index_production_supports_on_storage_id

    create_table :productions do |t|
      t.references :activity,                       null: false
      t.references :campaign,                       null: false
      t.references :product_nature
      t.boolean  :static_support,    default: false, null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.integer  :position
      t.string   :state
      t.stamps
    end
    add_index :productions, [:activity_id], name: :index_productions_on_activity_id
    add_index :productions, [:campaign_id], name: :index_productions_on_campaign_id
    add_index :productions, [:product_nature_id], name: :index_productions_on_product_nature_id

    create_table :products do |t|
      t.string   :type
      t.string   :name,                                                                          null: false
      t.string   :number,                                                                        null: false
      t.boolean  :active,                                                        default: false, null: false
      t.string   :variety,                  limit: 127,                                          null: false
      t.references :variant,                                                                    null: false
      t.references :nature,                                                                     null: false
      t.references :tracking
      t.references :asset
      t.datetime :born_at
      t.datetime :dead_at
      t.text     :description
      t.string   :picture_file_name
      t.string   :picture_content_type
      t.integer  :picture_file_size
      t.datetime :picture_updated_at
      t.boolean  :external,                                                      default: false, null: false
      t.references :owner,                                                                      null: false
      t.string   :identification_number
      t.string   :work_number
      t.references :father
      t.references :mother
      t.references :address
      t.boolean  :reservoir,                                                     default: false, null: false
      t.references :content_nature
      t.string   :content_indicator
      t.string   :content_indicator_unit
      t.decimal  :content_maximal_quantity,             precision: 19, scale: 4, default: 0.0,   null: false
      t.references :parent
      t.stamps
    end
    add_index :products, [:address_id], name: :index_products_on_address_id
    add_index :products, [:asset_id], name: :index_products_on_asset_id
    add_index :products, [:content_indicator_unit], name: :index_products_on_content_indicator_unit
    add_index :products, [:content_nature_id], name: :index_products_on_content_nature_id
    add_index :products, [:father_id], name: :index_products_on_father_id
    add_index :products, [:mother_id], name: :index_products_on_mother_id
    add_index :products, [:nature_id], name: :index_products_on_nature_id
    add_index :products, [:number], name: :index_products_on_number, unique: true
    add_index :products, [:owner_id], name: :index_products_on_owner_id
    add_index :products, [:parent_id], name: :index_products_on_parent_id
    add_index :products, [:tracking_id], name: :index_products_on_tracking_id
    add_index :products, [:type], name: :index_products_on_type
    add_index :products, [:variant_id], name: :index_products_on_variant_id
    add_index :products, [:variety], name: :index_products_on_variety

    create_table :professions do |t|
      t.string   :name,                         null: false
      t.string   :code
      t.boolean  :commercial,   default: false, null: false
      t.stamps
    end

    create_table :purchase_items do |t|
      t.references :purchase,                                              null: false
      t.references :product,                                               null: false
      t.references :price,                                                 null: false
      t.decimal  :quantity,          precision: 19, scale: 4, default: 1.0, null: false
      t.decimal  :pretax_amount,     precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :amount,            precision: 19, scale: 4, default: 0.0, null: false
      t.integer  :position
      t.references :account,                                               null: false
      t.references :warehouse
      t.text     :annotation
      t.references :tracking
      t.string   :tracking_serial
      t.decimal  :price_amount,      precision: 19, scale: 4,               null: false
      t.references :tax,                                                   null: false
      t.string   :unit
      t.references :price_template
      t.stamps
    end
    add_index :purchase_items, [:account_id], name: :index_purchase_items_on_account_id
    add_index :purchase_items, [:price_id], name: :index_purchase_items_on_price_id
    add_index :purchase_items, [:product_id], name: :index_purchase_items_on_product_id
    add_index :purchase_items, [:purchase_id], name: :index_purchase_items_on_purchase_id
    add_index :purchase_items, [:tax_id], name: :index_purchase_items_on_tax_id
    add_index :purchase_items, [:tracking_id], name: :index_purchase_items_on_tracking_id
    add_index :purchase_items, [:unit], name: :index_purchase_items_on_unit

    create_table :purchase_natures do |t|
      t.boolean  :active,                    default: true,  null: false
      t.string   :name
      t.text     :description
      t.string   :currency,        limit: 3
      t.boolean  :with_accounting,           default: false, null: false
      t.references :journal
      t.boolean  :by_default,                default: false, null: false
      t.stamps
    end
    add_index :purchase_natures, [:currency], name: :index_purchase_natures_on_currency
    add_index :purchase_natures, [:journal_id], name: :index_purchase_natures_on_journal_id

    create_table :purchases do |t|
      t.references :supplier,                                                           null: false
      t.string   :number,              limit: 64,                                        null: false
      t.decimal  :pretax_amount,                  precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :amount,                         precision: 19, scale: 4, default: 0.0, null: false
      t.references :delivery_address
      t.text     :description
      t.date     :planned_on
      t.date     :invoiced_on
      t.date     :created_on
      t.datetime :accounted_at
      t.references :journal_entry
      t.string   :reference_number
      t.string   :state,               limit: 64
      t.date     :confirmed_on
      t.references :responsible
      t.string   :currency,            limit: 3
      t.references :nature
      t.references :affair
      t.stamps
    end
    add_index :purchases, [:accounted_at], name: :index_purchase_orders_on_accounted_at
    add_index :purchases, [:affair_id], name: :index_purchases_on_affair_id
    add_index :purchases, [:currency], name: :index_purchases_on_currency
    add_index :purchases, [:delivery_address_id], name: :index_purchases_on_delivery_address_id
    add_index :purchases, [:journal_entry_id], name: :index_purchases_on_journal_entry_id
    add_index :purchases, [:nature_id], name: :index_purchases_on_nature_id
    add_index :purchases, [:responsible_id], name: :index_purchases_on_responsible_id
    add_index :purchases, [:supplier_id], name: :index_purchases_on_supplier_id

    create_table :roles do |t|
      t.string   :name,                     null: false
      t.text     :rights
      t.stamps
    end

    create_table :sale_items do |t|
      t.references :sale,                                                     null: false
      t.references :product,                                                  null: false
      t.references :price,                                                    null: false
      t.decimal  :quantity,             precision: 19, scale: 4, default: 1.0, null: false
      t.decimal  :pretax_amount,        precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :amount,               precision: 19, scale: 4, default: 0.0, null: false
      t.integer  :position
      t.references :account
      t.references :warehouse
      t.decimal  :price_amount,         precision: 19, scale: 4
      t.references :tax
      t.text     :annotation
      t.references :reduction_origin
      t.text     :label
      t.references :tracking
      t.decimal  :reduction_percentage, precision: 19, scale: 4, default: 0.0, null: false
      t.references :origin
      t.string   :unit
      t.references :price_template
      t.stamps
    end
    add_index :sale_items, [:account_id], name: :index_sale_items_on_account_id
    add_index :sale_items, [:origin_id], name: :index_sale_items_on_origin_id
    add_index :sale_items, [:price_id], name: :index_sale_items_on_price_id
    add_index :sale_items, [:product_id], name: :index_sale_items_on_product_id
    add_index :sale_items, [:reduction_origin_id], name: :index_sale_items_on_reduction_origin_id
    add_index :sale_items, [:sale_id], name: :index_sale_items_on_sale_id
    add_index :sale_items, [:tax_id], name: :index_sale_items_on_tax_id
    add_index :sale_items, [:tracking_id], name: :index_sale_items_on_tracking_id
    add_index :sale_items, [:unit], name: :index_sale_items_on_unit

    create_table :sale_natures do |t|
      t.string   :name,                                                                       null: false
      t.boolean  :active,                                                     default: true,  null: false
      t.boolean  :downpayment,                                                default: false, null: false
      t.decimal  :downpayment_minimum,               precision: 19, scale: 4, default: 0.0,   null: false
      t.decimal  :downpayment_percentage,            precision: 19, scale: 4, default: 0.0,   null: false
      t.text     :description
      t.references :payment_mode
      t.text     :payment_mode_complement
      t.boolean  :with_accounting,                                            default: false, null: false
      t.string   :currency,                limit: 3
      t.references :journal
      t.text     :sales_conditions
      t.boolean  :by_default,                                                 default: false, null: false
      t.string   :expiration_delay,                                                           null: false
      t.string   :payment_delay,                                                              null: false
      t.stamps
    end
    add_index :sale_natures, [:journal_id], name: :index_sale_natures_on_journal_id
    add_index :sale_natures, [:payment_mode_id], name: :index_sale_natures_on_payment_mode_id

    create_table :sales do |t|
      t.references :client,                                                               null: false
      t.references :nature
      t.date     :created_on,                                                              null: false
      t.string   :number,              limit: 64,                                          null: false
      t.decimal  :pretax_amount,                  precision: 19, scale: 4, default: 0.0,   null: false
      t.decimal  :amount,                         precision: 19, scale: 4, default: 0.0,   null: false
      t.string   :state,               limit: 64,                                          null: false
      t.date     :expired_on
      t.boolean  :has_downpayment,                                         default: false, null: false
      t.decimal  :downpayment_amount,             precision: 19, scale: 4, default: 0.0,   null: false
      t.references :address
      t.references :invoice_address
      t.references :delivery_address
      t.string   :subject
      t.string   :function_title
      t.text     :introduction
      t.text     :conclusion
      t.text     :description
      t.date     :confirmed_on
      t.references :responsible
      t.boolean  :letter_format,                                           default: true,  null: false
      t.text     :annotation
      t.references :transporter
      t.datetime :accounted_at
      t.references :journal_entry
      t.string   :reference_number
      t.date     :invoiced_on
      t.boolean  :credit,                                                  default: false, null: false
      t.date     :payment_on
      t.references :origin
      t.string   :initial_number,      limit: 64
      t.string   :currency,            limit: 3
      t.references :affair
      t.string   :expiration_delay
      t.string   :payment_delay,                                                           null: false
      t.stamps
    end
    add_index :sales, [:accounted_at], name: :index_sale_orders_on_accounted_at
    add_index :sales, [:address_id], name: :index_sales_on_address_id
    add_index :sales, [:affair_id], name: :index_sales_on_affair_id
    add_index :sales, [:client_id], name: :index_sales_on_client_id
    add_index :sales, [:currency], name: :index_sales_on_currency
    add_index :sales, [:delivery_address_id], name: :index_sales_on_delivery_address_id
    add_index :sales, [:invoice_address_id], name: :index_sales_on_invoice_address_id
    add_index :sales, [:journal_entry_id], name: :index_sales_on_journal_entry_id
    add_index :sales, [:nature_id], name: :index_sales_on_nature_id
    add_index :sales, [:origin_id], name: :index_sales_on_origin_id
    add_index :sales, [:responsible_id], name: :index_sales_on_responsible_id
    add_index :sales, [:transporter_id], name: :index_sales_on_transporter_id

    create_table :sequences do |t|
      t.string   :name,                                null: false
      t.string   :number_format,                       null: false
      t.string   :period,           default: "number", null: false
      t.integer  :last_year
      t.integer  :last_month
      t.integer  :last_cweek
      t.integer  :last_number
      t.integer  :number_increment, default: 1,        null: false
      t.integer  :number_start,     default: 1,        null: false
      t.string   :usage
      t.stamps
    end

    create_table :subscription_natures do |t|
      t.string   :name,                                                                   null: false
      t.integer  :actual_number
      t.string   :nature,                                                                 null: false
      t.text     :description
      t.decimal  :reduction_percentage,              precision: 19, scale: 4
      t.string   :entity_link_nature,    limit: 127
      t.string   :entity_link_direction, limit: 31
      t.stamps
    end

    create_table :subscriptions do |t|
      t.date     :started_on
      t.date     :stopped_on
      t.integer  :first_number
      t.integer  :last_number
      t.references :sale
      t.references :product_nature
      t.references :address
      t.decimal  :quantity,          precision: 19, scale: 4
      t.boolean  :suspended,                                  default: false, null: false
      t.references :nature
      t.references :subscriber
      t.text     :description
      t.string   :number
      t.references :sale_item
      t.stamps
    end
    add_index :subscriptions, [:address_id], name: :index_subscriptions_on_address_id
    add_index :subscriptions, [:nature_id], name: :index_subscriptions_on_nature_id
    add_index :subscriptions, [:product_nature_id], name: :index_subscriptions_on_product_nature_id
    add_index :subscriptions, [:sale_id], name: :index_subscriptions_on_sales_order_id
    add_index :subscriptions, [:sale_item_id], name: :index_subscriptions_on_sale_item_id
    add_index :subscriptions, [:subscriber_id], name: :index_subscriptions_on_subscriber_id

    create_table :tax_declarations do |t|
      t.string   :nature,                                            default: "normal", null: false
      t.string   :address
      t.date     :declared_on
      t.date     :paid_on
      t.decimal  :collected_amount,         precision: 19, scale: 4
      t.decimal  :paid_amount,              precision: 19, scale: 4
      t.decimal  :balance_amount,           precision: 19, scale: 4
      t.boolean  :deferred_payment,                                  default: false
      t.decimal  :assimilated_taxes_amount, precision: 19, scale: 4
      t.decimal  :acquisition_amount,       precision: 19, scale: 4
      t.decimal  :amount,                   precision: 19, scale: 4
      t.references :financial_year
      t.date     :started_on
      t.date     :stopped_on
      t.datetime :accounted_at
      t.references :journal_entry
      t.stamps
    end
    add_index :tax_declarations, [:financial_year_id], name: :index_tax_declarations_on_financial_year_id
    add_index :tax_declarations, [:journal_entry_id], name: :index_tax_declarations_on_journal_entry_id

    create_table :taxes do |t|
      t.string   :name,                                                                      null: false
      t.boolean  :included,                                                  default: false, null: false
      t.boolean  :reductible,                                                default: true,  null: false
      t.string   :nature,               limit: 16,                                           null: false
      t.decimal  :amount,                           precision: 19, scale: 4, default: 0.0,   null: false
      t.text     :description
      t.references :collect_account
      t.references :deduction_account
      t.datetime :created_at,                                                                null: false
      t.datetime :updated_at,                                                                null: false
      t.references :creator
      t.references :updater
      t.integer  :lock_version,                                              default: 0,     null: false
      t.string   :nomen,                limit: 127
      t.stamps
    end
    add_index :taxes, [:collect_account_id], name: :index_taxes_on_account_collected_id
    add_index :taxes, [:deduction_account_id], name: :index_taxes_on_account_paid_id

    create_table :trackings do |t|
      t.string   :name,                        null: false
      t.string   :serial
      t.boolean  :active,       default: true, null: false
      t.text     :description
      t.references :product
      t.references :producer
      t.stamps
    end
    add_index :trackings, [:product_id], name: :index_trackings_on_product_id

    create_table :transfers do |t|
      t.decimal  :amount,                     precision: 19, scale: 4, default: 0.0, null: false
      t.string   :currency,         limit: 3,                                        null: false
      t.references :client,                                                         null: false
      t.string   :label
      t.string   :description
      t.date     :started_on
      t.date     :stopped_on
      t.date     :created_on
      t.datetime :accounted_at
      t.references :journal_entry
      t.references :affair
      t.stamps
    end
    add_index :transfers, [:accounted_at], name: :index_transfers_on_accounted_at
    add_index :transfers, [:affair_id], name: :index_transfers_on_affair_id
    add_index :transfers, [:client_id], name: :index_transfers_on_client_id
    add_index :transfers, [:journal_entry_id], name: :index_transfers_on_journal_entry_id

    create_table :transports do |t|
      t.references :transporter,                                          null: false
      t.references :responsible
      t.decimal  :weight,           precision: 19, scale: 4
      t.date     :created_on
      t.date     :transport_on
      t.text     :description
      t.string   :number
      t.string   :reference_number
      t.references :purchase
      t.decimal  :pretax_amount,    precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :amount,           precision: 19, scale: 4, default: 0.0, null: false
      t.stamps
    end
    add_index :transports, [:purchase_id], name: :index_transports_on_purchase_id
    add_index :transports, [:responsible_id], name: :index_transports_on_responsible_id
    add_index :transports, [:transporter_id], name: :index_transports_on_transporter_id

    create_table :users do |t|
      t.string   :first_name,                                                                                null: false
      t.string   :last_name,                                                                                 null: false
      t.boolean  :locked,                                                                    default: false, null: false
      t.string   :email,                                                                                     null: false
      t.references :role,                                                                                   null: false
      t.decimal  :maximal_grantable_reduction_percentage,           precision: 19, scale: 4, default: 5.0,   null: false
      t.boolean  :administrator,                                                             default: true,  null: false
      t.text     :rights
      t.date     :arrived_on
      t.text     :description
      t.boolean  :commercial
      t.datetime :departed_at
      t.references :department
      t.references :establishment
      t.string   :office
      t.references :profession
      t.boolean  :employed,                                                                  default: false, null: false
      t.string   :employment
      t.string   :language,                               limit: 3,                                          null: false
      t.datetime :last_sign_in_at
      t.string   :encrypted_password,                                                        default: "",    null: false
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer  :sign_in_count,                                                             default: 0
      t.datetime :current_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email
      t.integer  :failed_attempts,                                                           default: 0
      t.string   :unlock_token
      t.datetime :locked_at
      t.string   :authentication_token
      t.references :person
      t.stamps
    end
    add_index :users, [:authentication_token], name: :index_users_on_authentication_token, unique: true
    add_index :users, [:confirmation_token], name: :index_users_on_confirmation_token, unique: true
    add_index :users, [:department_id], name: :index_users_on_department_id
    add_index :users, [:email], name: :index_users_on_email, unique: true
    add_index :users, [:establishment_id], name: :index_users_on_establishment_id
    add_index :users, [:person_id], name: :index_users_on_person_id, unique: true
    add_index :users, [:profession_id], name: :index_users_on_profession_id
    add_index :users, [:reset_password_token], name: :index_users_on_reset_password_token, unique: true
    add_index :users, [:role_id], name: :index_users_on_role_id
    add_index :users, [:unlock_token], name: :index_users_on_unlock_token, unique: true
  end

end
