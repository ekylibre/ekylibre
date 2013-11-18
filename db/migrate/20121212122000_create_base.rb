class CreateBase < ActiveRecord::Migration

  def up

    create_table :account_balances do |t|
      t.references :account,                                                null: false, index: true
      t.references :financial_year,                                         null: false, index: true
      t.decimal  :global_debit,      precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :global_credit,     precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :global_balance,    precision: 19, scale: 4, default: 0.0, null: false
      t.integer  :global_count,                               default: 0,   null: false
      t.decimal  :local_debit,       precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :local_credit,      precision: 19, scale: 4, default: 0.0, null: false
      t.decimal  :local_balance,     precision: 19, scale: 4, default: 0.0, null: false
      t.integer  :local_count,                                default: 0,   null: false
      t.string   :currency,                                                 null: false
      t.stamps
    end

    create_table :accounts do |t|
      t.string   :number,       limit: 20,                  null: false
      t.string   :name,         limit: 200,                 null: false
      t.string   :label,                                    null: false
      t.boolean  :debtor,                   default: false, null: false
      t.string   :last_letter,  limit: 10
      t.text     :description
      t.boolean  :reconcilable,             default: false, null: false
      t.text     :usages
      t.stamps
    end

    create_table :activities do |t|
      t.string     :name,                     null: false
      t.string     :description
      t.string     :family
      t.string     :nature,                   null: false
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.references :parent,                                index: true
      t.integer    :lft
      t.integer    :rgt
      t.integer    :depth
      t.stamps
      t.index      :name
      t.index      [:lft, :rgt]
    end

    create_table :affairs do |t|
      t.boolean    :closed,                                            default: false, null: false
      t.datetime   :closed_at
      t.references :third,                                                             null: false, index: true
      t.string     :currency,       limit: 3,                                          null: false
      t.decimal    :debit,                    precision: 19, scale: 4, default: 0.0,   null: false
      t.decimal    :credit,                   precision: 19, scale: 4, default: 0.0,   null: false
      t.datetime   :accounted_at
      t.references :journal_entry,                                                                  index: true
      t.stamps
    end

    create_table :analytic_repartitions do |t|
      t.references :production,                                                null: false, index: true
      t.references :journal_entry_item,                                        null: false, index: true
      t.string     :state,                                                     null: false
      t.date       :affected_on,                                               null: false
      t.decimal    :affectation_percentage, precision: 19, scale: 4,           null: false
      t.stamps
    end

    create_table :areas do |t|
      t.string     :postcode,                              null: false
      t.string     :name,                                  null: false
      t.string     :country,      limit: 2, null: false
      t.references :district,                                          index: true
      t.string     :city
      t.string     :city_name
      t.string     :code
      t.stamps
    end

    create_table :asset_depreciations do |t|
      t.references :asset,                                                       null: false, index: true
      t.references :journal_entry,                                                            index: true
      t.boolean    :accountable,                                 default: false, null: false
      t.date       :created_on,                                                  null: false
      t.datetime   :accounted_at
      t.date       :started_on,                                                  null: false
      t.date       :stopped_on,                                                  null: false
      t.decimal    :amount,             precision: 19, scale: 4,                 null: false
      t.integer    :position
      t.boolean    :locked,                                      default: false, null: false
      t.references :financial_year,                                                           index: true
      t.decimal    :asset_amount,       precision: 19, scale: 4
      t.decimal    :depreciated_amount, precision: 19, scale: 4
      t.stamps
    end

    create_table :assets do |t|
      t.references :allocation_account,                                           null: false, index: true
      t.references :journal,                                                      null: false, index: true
      t.string     :name,                                                         null: false
      t.string     :number,                                                       null: false
      t.text       :description
      t.date       :purchased_on
      t.references :purchase,                                                                  index: true
      t.references :purchase_item,                                                             index: true
      t.boolean    :ceded
      t.date       :ceded_on
      t.references :sale,                                                                      index: true
      t.references :sale_item,                                                                 index: true
      t.decimal    :purchase_amount,                   precision: 19, scale: 4
      t.date       :started_on,                                                   null: false
      t.date       :stopped_on,                                                   null: false
      t.decimal    :depreciable_amount,                precision: 19, scale: 4,   null: false
      t.decimal    :depreciated_amount,                precision: 19, scale: 4,   null: false
      t.string     :depreciation_method,                                          null: false
      t.string     :currency,                limit: 3,                            null: false
      t.decimal    :current_amount,                    precision: 19, scale: 4
      t.references :charges_account,                                                           index: true
      t.decimal    :depreciation_percentage,           precision: 19, scale: 4
      t.stamps
    end

    create_table :bank_statements do |t|
      t.references :cash,                                                null: false, index: true
      t.date       :started_on,                                          null: false
      t.date       :stopped_on,                                          null: false
      t.string     :number,                                              null: false
      t.decimal    :debit,        precision: 19, scale: 4, default: 0.0, null: false
      t.decimal    :credit,       precision: 19, scale: 4, default: 0.0, null: false
      t.string     :currency,     limit: 3,                              null: false
      t.stamps
    end

    create_table :campaigns do |t|
      t.string   :name,                         null: false
      t.text     :description
      t.string   :number,       limit: 60,      null: false
      t.integer  :harvest_year, limit: 4
      t.boolean  :closed,       default: false, null: false
      t.datetime :closed_at
      t.stamps
    end

    create_table :cash_transfers do |t|
      t.string     :number,                                               null: false
      t.text       :description
      t.date       :transfered_on,                                        null: false
      t.datetime   :accounted_at
      t.decimal    :emission_amount,            precision: 19, scale: 4,  null: false
      t.string     :emission_currency,          limit: 3,                 null: false
      t.references :emission_cash,                                        null: false, index: true
      t.references :emission_journal_entry,                                            index: true
      t.decimal    :currency_rate,              precision: 19, scale: 10, null: false
      t.decimal    :reception_amount,           precision: 19, scale: 4,  null: false
      t.string     :reception_currency,         limit: 3,                 null: false
      t.references :reception_cash,                                       null: false, index: true
      t.references :reception_journal_entry,                                           index: true
      t.stamps
    end

    create_table :cashes do |t|
      t.string     :name,                                                   null: false
      t.string     :nature,             limit: 20, default: "bank_account", null: false
      t.references :journal,                                                null: false, index: true
      t.references :account,                                                null: false, index: true
      t.string     :bank_code
      t.string     :bank_agency_code
      t.string     :bank_account_number
      t.string     :bank_account_key
      t.text       :bank_agency_address
      t.string     :bank_name,            limit: 50
      t.string     :mode,                            default: "iban",       null: false
      t.string     :bank_identifier_code, limit: 11
      t.string     :iban,                 limit: 34
      t.string     :spaced_iban,          limit: 42
      # t.boolean    :by_default,                      default: false,        null: false
      t.string     :currency,             limit: 3,                         null: false
      t.string     :country,              limit: 2
      t.stamps
    end

    create_table :catalogs do |t|
      t.string   :name,                                   null: false
      t.string   :usage,         limit: 20,               null: false
      t.string   :code,          limit: 20,               null: false
      t.boolean  :by_default,             default: false, null: false
      t.boolean  :all_taxes_included,     default: false, null: false
      t.string   :currency,      limit: 3,                null: false
      t.text     :description
      t.stamps
    end

    create_table :catalog_prices do |t|
      t.references :variant,                                          null: false, index: true
      t.references :catalog,                                          null: false, index: true
      # t.references :supplier,                                         null: false, index: true
      t.string     :indicator,     limit: 120,                        null: false
      t.references :reference_tax,                                                 index: true
      # t.decimal    :pretax_amount,           precision: 19, scale: 4, null: false
      t.decimal    :amount,                  precision: 19, scale: 4, null: false
      t.boolean    :all_taxes_included,               default: false, null: false
      t.string     :currency,      limit: 3,                          null: false
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.string     :thread,        limit: 20
      t.stamps
      t.index [:started_at, :stopped_at]
    end

    create_table :custom_field_choices do |t|
      t.references :custom_field,              null: false, index: true
      t.string     :name,                      null: false
      t.string     :value
      t.integer    :position
      t.stamps
    end

    create_table :custom_fields do |t|
      t.string   :name,                                                               null: false
      t.string   :nature,          limit: 20,                                         null: false
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

    create_table :deposit_items do |t|
      t.references :deposit,                                                       null: false, index: true
      t.decimal    :quantity,               precision: 19, scale: 4, default: 0.0, null: false
      t.decimal    :amount,                 precision: 19, scale: 4, default: 1.0, null: false
      t.string     :currency,     limit: 3,                                        null: false
      t.stamps
    end

    create_table :deposits do |t|
      t.string     :number,                                                    null: false
      t.references :cash,                                                      null: false, index: true
      t.references :mode,                                                      null: false, index: true
      t.date       :created_on,                                                null: false
      t.decimal    :amount,           precision: 19, scale: 4, default: 0.0,   null: false
      t.integer    :payments_count,                            default: 0,     null: false
      t.text       :description
      t.boolean    :locked,                                    default: false, null: false
      t.references :responsible,                                                            index: true
      t.datetime   :accounted_at
      t.references :journal_entry,                                                          index: true
      t.boolean    :in_cash,                                   default: false, null: false
      t.stamps
    end

    create_table :districts do |t|
      t.string   :name,                     null: false
      t.string   :code
      t.stamps
    end

    create_table :document_archives do |t|
      t.references :document,                   null: false, index: true
      t.datetime   :archived_at,                null: false
      t.references :template,                                index: true
      t.string     :file_file_name
      t.integer    :file_file_size
      t.string     :file_content_type
      t.datetime   :file_updated_at
      t.string     :file_fingerprint
      t.integer    :file_pages_count
      t.text       :file_content_text
      t.stamps
      t.index      :archived_at
    end

    create_table :document_templates do |t|
      t.string   :name,                                    null: false
      t.boolean  :active,                  default: false, null: false
      t.boolean  :by_default,              default: false, null: false
      t.string   :nature,       limit: 60,                 null: false
      t.string   :language,     limit: 3,                  null: false
      t.string   :archiving,    limit: 60,                 null: false
      t.boolean  :managed,                 default: false, null: false
      t.string   :formats
      t.stamps
    end

    create_table :documents do |t|
      t.string   :number,         limit: 60,             null: false
      t.string   :name,                                  null: false
      t.string   :nature,         limit: 120,            null: false
      t.string   :key,                                   null: false
      t.integer  :archives_count,            default: 0, null: false
      t.stamps
      t.index    :name
      t.index    [:nature, :key], unique: true
      t.index    :nature
      t.index    :number
    end

    create_table :entities do |t|
      t.string     :type
      t.string     :nature,                                                                        null: false
      t.string     :last_name,                                                                     null: false
      t.string     :first_name
      t.string     :full_name,                                                                     null: false
      t.string     :number,                    limit: 60
      t.boolean    :active,                                                        default: true,  null: false
      t.date       :born_on
      t.date       :dead_on
      # t.string   :soundex,                   limit: 4
      t.boolean    :client,                                                        default: false, null: false
      t.references :client_account,                                                                            index: true
      t.boolean    :supplier,                                                      default: false, null: false
      t.references :supplier_account,                                                                          index: true
      t.boolean    :transporter,                                                   default: false, null: false
      t.boolean    :prospect,                                                      default: false, null: false
      t.boolean    :vat_subjected,                                                 default: true,  null: false
      t.boolean    :reminder_submissive,                                           default: false, null: false
      t.string     :deliveries_conditions,     limit: 60
      # t.decimal    :discount_percentage,                  precision: 19, scale: 4
      # t.decimal    :reduction_percentage,                 precision: 19, scale: 4
      t.text       :description
      t.string     :language,                  limit: 3,                                           null: false
      t.string     :country,                   limit: 2
      t.string     :currency,                                                                      null: false
      t.integer    :authorized_payments_count
      t.references :responsible,                                                                                index: true
      t.references :proposer,                                                                                   index: true
      # t.references :payment_mode
      # t.string     :payment_delay
      t.integer    :invoices_count
      t.string     :origin
      t.date       :first_met_on
      t.string     :activity_code,             limit: 30
      t.string     :vat_number,                limit: 20
      t.string     :siren,                     limit: 9
      # t.string   :webpass
      # t.boolean    :attorney,                                                      default: false, null: false
      # t.references :attorney_account
      t.boolean    :locked,                                                        default: false, null: false
      t.boolean    :of_company,                                                    default: false, null: false
      t.string     :picture_file_name
      t.integer    :picture_file_size
      t.string     :picture_content_type
      t.datetime   :picture_updated_at
      t.stamps
      t.index      :number
      t.index      :full_name
      t.index      :of_company
    end

    create_table :entity_addresses do |t|
      t.references :entity,                                                              null: false, index: true
      t.string     :canal,            limit: 20,                                         null: false
      t.string     :coordinate,       limit: 500,                                        null: false
      t.boolean    :by_default,                                          default: false, null: false
      t.datetime   :deleted_at
      t.string     :thread,           limit: 10
      t.string     :name
      t.string     :mail_line_1
      t.string     :mail_line_2
      t.string     :mail_line_3
      t.string     :mail_line_4
      t.string     :mail_line_5
      t.string     :mail_line_6
      t.string     :mail_country,     limit: 2
      t.references :mail_area,                                                                        index: true
      t.point      :mail_geolocation, has_z: true
      t.boolean    :mail_auto_update,                                    default: false, null: false
      t.stamps
      t.index :by_default
      t.index :deleted_at
      t.index :thread
    end

    create_table :entity_links do |t|
      t.references :entity_1,              null: false, index: true
      t.references :entity_2,              null: false, index: true
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.text       :description
      t.string     :nature,                null: false
      t.stamps
    end

    create_table :establishments do |t|
      t.string   :name,                    null: false
      t.string   :code
      t.text     :description
      t.stamps
    end

    create_table :event_natures do |t|
      t.string   :name,                                   null: false
      t.string   :usage,        limit: 60
      t.boolean  :active,                  default: true, null: false
      t.stamps
      t.index    :name
    end

    create_table :event_participations do |t|
      t.references :event,                   null: false, index: true
      t.references :participant,             null: false, index: true
      t.string   :state
      t.stamps
    end

    create_table :events do |t|
      t.references :nature,                  null: false, index: true
      t.string     :name,                    null: false
      t.datetime   :started_at,              null: false
      t.datetime   :stopped_at
      t.integer    :duration
      t.string     :place
      t.text       :description
      t.stamps
    end

    create_table :financial_years do |t|
      t.string     :code,                  limit: 20,                 null: false
      t.boolean    :closed,                           default: false, null: false
      t.date       :started_on,                                       null: false
      t.date       :stopped_on,                                       null: false
      t.string     :currency,              limit: 3,                  null: false
      t.integer    :currency_precision
      t.references :last_journal_entry,                                            index: true
      t.stamps
    end

    create_table :gaps do |t|
      t.string     :number,                                                             null: false
      t.string     :direction,                                                          null: false
      t.references :affair,                                                             null: false, index: true
      t.references :entity,                                                             null: false, index: true
      t.decimal    :amount,                    precision: 19, scale: 4, default: 0.0,   null: false
      t.string     :currency,       limit: 3,                                           null: false
      t.datetime   :accounted_at
      t.references :journal_entry,                                                                  index: true
      t.stamps
      t.index      :number
      t.index      :direction
    end

    create_table :incidents do |t|
      t.references :target,      polymorphic: true, null: false, index: true
      t.string     :nature,                         null: false
      t.datetime   :observed_at,                    null: false
      t.integer    :priority
      t.integer    :gravity
      t.string     :state
      t.string     :name,                           null: false
      t.text       :description
      t.string     :picture_file_name
      t.string     :picture_content_type
      t.integer    :picture_file_size
      t.datetime   :picture_updated_at
      t.stamps
      t.index      :name
      t.index      :nature
    end

    create_table :incoming_deliveries do |t|
      t.string     :number,                                             null: false
      t.references :sender,                                             null: false, index: true
      t.string     :reference_number
      t.references :purchase,                                                        index: true
      t.references :address,                                                         index: true
      t.datetime   :received_at
      # t.decimal    :weight,           precision: 19, scale: 4
      t.references :mode,                                                            index: true
      t.stamps
    end

    create_table :incoming_delivery_items do |t|
      t.references :delivery,                                             null: false, index: true
      t.references :purchase_item,                                                     index: true
      t.references :product,                                              null: false, index: true
      t.decimal    :quantity,      precision: 19, scale: 4, default: 1.0, null: false
      t.references :container,                                                         index: true
      # t.references :move
      t.stamps
    end

    create_table :incoming_delivery_modes do |t|
      t.string   :name,                               null: false
      t.string   :code,         limit: 30,            null: false
      t.text     :description
      t.stamps
    end

    create_table :incoming_payment_modes do |t|
      t.string     :name,                    limit: 50,                                          null: false
      t.references :cash,                                                                                     index: true
      t.boolean    :active,                                                      default: false
      t.integer    :position
      t.boolean    :with_accounting,                                             default: false, null: false
      t.references :attorney_journal,                                                                         index: true
      t.boolean    :with_commission,                                             default: false, null: false
      t.decimal    :commission_percentage,              precision: 19, scale: 4, default: 0.0,   null: false
      t.decimal    :commission_base_amount,             precision: 19, scale: 4, default: 0.0,   null: false
      t.references :commission_account,                                                                       index: true
      t.boolean    :with_deposit,                                                default: false, null: false
      t.references :depositables_account,                                                                     index: true
      t.references :depositables_journal,                                                                     index: true
      t.boolean    :detail_payments,                                             default: false, null: false
      t.stamps
    end

    create_table :incoming_payments do |t|
      t.date       :paid_on
      t.decimal    :amount,                          precision: 19, scale: 4,                        null: false
      t.references :mode,                                                                            null: false, index: true
      t.string     :bank_name
      t.string     :bank_check_number
      t.string     :bank_account_number
      t.references :payer,                                                                                        index: true
      t.date       :to_bank_on,                                               default: '0001-01-01', null: false
      t.references :deposit,                                                                                      index: true
      t.references :responsible,                                                                                  index: true
      t.boolean    :scheduled,                                                default: false,        null: false
      t.boolean    :received,                                                 default: true,         null: false
      t.string     :number
      t.date       :created_on
      t.datetime   :accounted_at
      t.text       :receipt
      t.references :journal_entry,                                                                                index: true
      t.references :commission_account,                                                                           index: true
      t.decimal    :commission_amount,               precision: 19, scale: 4, default: 0.0,          null: false
      t.string     :currency,              limit: 3,                                                 null: false
      t.boolean    :downpayment,                                              default: true,         null: false
      t.references :affair,                                                                                       index: true
      t.stamps
      t.index      :accounted_at
    end

    create_table :intervention_casts do |t|
      t.references :intervention,                                          null: false, index: true
      t.references :actor,                                                              index: true
      t.references :variant,                                                            index: true
      t.decimal    :quantity,           precision: 19, scale: 4
      t.string     :roles,              limit: 320
      t.string     :reference_name,                                        null: false
      t.stamps
      t.index      :reference_name
    end

    create_table :interventions do |t|
      t.references :ressource,                polymorphic: true,              index: true
      t.references :provisional_intervention,                                 index: true
      t.references :production_support,                                       index: true
      t.boolean    :provisional,              default: false,    null: false
      t.references :incident,                                                 index: true
      t.references :prescription,                                             index: true
      t.references :production,                                  null: false, index: true
      t.string     :reference_name,                              null: false
      t.string     :natures,                                     null: false
      t.string     :state,                                       null: false
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
      t.index      :reference_name
    end

    create_table :inventories do |t|
      t.string     :number,            limit: 20
      t.date       :created_on,                               null: false
      t.text       :description
      t.boolean    :changes_reflected,        default: false, null: false
      t.references :responsible,                                           index: true
      t.datetime   :accounted_at
      t.references :journal_entry,                                         index: true
      t.date       :moved_on
      t.stamps
    end

    create_table :inventory_items do |t|
      t.references :product,                                             null: false, index: true
      t.references :warehouse,                                           null: false, index: true
      t.decimal    :theoric_quantity, precision: 19, scale: 4,           null: false
      t.decimal    :quantity,         precision: 19, scale: 4,           null: false
      t.references :inventory,                                           null: false, index: true
      t.references :tracking,                                                         index: true
      t.references :move,                                                             index: true
      t.stamps
    end

    create_table :journal_entries do |t|
      t.references :journal,                                                               null: false, index: true
      t.references :financial_year,                                                                     index: true
      t.string     :number,                                                                null: false
      t.references :resource,           polymorphic: true,                                              index: true
      t.string     :state,              limit: 30,                                         null: false
      t.date       :created_on,                                                            null: false
      t.date       :printed_on,                                                            null: false
      t.decimal    :real_debit,                    precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :real_credit,                   precision: 19, scale: 4,  default: 0.0, null: false
      t.string     :real_currency,      limit: 3,                                          null: false
      t.decimal    :real_currency_rate,            precision: 19, scale: 10, default: 0.0, null: false
      t.decimal    :debit,                         precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :credit,                        precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :balance,                       precision: 19, scale: 4,  default: 0.0, null: false
      t.string     :currency,           limit: 3,                                          null: false
      t.decimal    :absolute_debit,                precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :absolute_credit,               precision: 19, scale: 4,  default: 0.0, null: false
      t.string     :absolute_currency,  limit: 3,                                          null: false
      t.stamps
      t.index      :number
    end

    create_table :journal_entry_items do |t|
      t.references :entry,                                                                        null: false, index: true
      t.references :journal,                                                                      null: false, index: true
      t.references :bank_statement,                                                                            index: true
      t.references :financial_year,                                                               null: false, index: true
      t.string     :state,                     limit: 30,                                         null: false
      t.date       :printed_on,                                                                   null: false
      t.string     :entry_number,                                                                 null: false
      t.string     :letter,                    limit: 10
      t.integer    :position
      t.text       :description
      t.references :account,                                                                      null: false, index: true
      t.string     :name,                                                                         null: false
      t.decimal    :real_debit,                           precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :real_credit,                          precision: 19, scale: 4,  default: 0.0, null: false
      t.string     :real_currency,             limit: 3,                                          null: false
      t.decimal    :real_currency_rate,                   precision: 19, scale: 10, default: 0.0, null: false
      t.decimal    :debit,                                precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :credit,                               precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :balance,                              precision: 19, scale: 4,  default: 0.0, null: false
      t.string     :currency,                  limit: 3,                                          null: false
      t.decimal    :absolute_debit,                       precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :absolute_credit,                      precision: 19, scale: 4,  default: 0.0, null: false
      t.string     :absolute_currency,         limit: 3,                                          null: false
      t.decimal    :cumulated_absolute_debit,             precision: 19, scale: 4,  default: 0.0, null: false
      t.decimal    :cumulated_absolute_credit,            precision: 19, scale: 4,  default: 0.0, null: false
      t.stamps
      t.index      :letter
      t.index      :name
    end

    create_table :journals do |t|
      t.string   :nature,       limit: 30,             null: false
      t.string   :name,                                null: false
      t.string   :code,         limit: 4,              null: false
      t.date     :closed_on,                           null: false
      t.string   :currency,     limit: 3,              null: false
      t.stamps
    end

    create_table :listing_node_items do |t|
      t.references :node,                              null: false, index: true
      t.string     :nature,       limit: 10,           null: false
      t.text       :value
      t.stamps
    end

    create_table :listing_nodes do |t|
      t.string   :name,                                          null: false
      t.string   :label,                                         null: false
      t.string   :nature,                                        null: false
      t.integer  :position
      t.boolean  :exportable,                     default: true, null: false
      t.references :parent
      t.string   :item_nature,          limit: 10
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
    add_index :listing_nodes, :exportable
    add_index :listing_nodes, :item_listing_id
    add_index :listing_nodes, :item_listing_node_id
    add_index :listing_nodes, :listing_id
    add_index :listing_nodes, :name
    add_index :listing_nodes, :nature
    add_index :listing_nodes, :parent_id

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
    add_index :listings, :name
    add_index :listings, :root_model

    create_table :logs do |t|
      t.string     :event,                             null: false
      t.datetime   :observed_at,                       null: false
      t.references :owner,          polymorphic: true, null: false, index: true
      t.text       :owner_object
      t.references :origin,         polymorphic: true,              index: true
      t.text       :origin_object
      t.text       :description
      t.stamps
      t.index      :observed_at
    end

    create_table :mandates do |t|
      t.date       :started_on
      t.date       :stopped_on
      t.string     :family,                   null: false
      t.string     :organization,             null: false
      t.string     :title,                    null: false
      t.references :entity,                   null: false, index: true
      t.stamps
    end

    create_table :observations do |t|
      t.string     :importance,   limit: 10,             null: false
      t.text       :content,                             null: false
      t.references :subject,      polymorphic: true,     null: false, index: true
      t.datetime   :observed_at,                         null: false
      t.references :author,                              null: false, index: true
      t.stamps
    end

    create_table :operations do |t|
      t.references :intervention,                  null: false, index: true
      t.datetime   :started_at,                    null: false
      t.datetime   :stopped_at,                    null: false
      t.integer    :duration
      t.string     :reference_name,                null: false
      t.stamps
      t.index      :reference_name
      t.index      :started_at
      t.index      :stopped_at
    end

    create_table :operation_tasks do |t|
      t.references :operation,                                    null: false, index: true
      t.references :parent,                                                    index: true
      t.string     :nature,                                       null: false
      t.string     :reference_name,                               null: false
      t.boolean    :prorated,                     default: false, null: false
      t.stamps
      t.index      :nature
      t.index      :reference_name
    end

    create_table :operation_task_casts do |t|
      t.references :task,                                   null: false, index: true
      t.string     :name,                                   null: false
      t.references :actor,         polymorphic: true,       null: false, index: true
      t.stamps
      t.index      :name
      t.index      [:task_id, :name], unique: true
    end


    create_table :outgoing_deliveries do |t|
      t.references :sale
      t.references :address
      t.datetime   :sent_at
      t.references :mode
      t.decimal    :weight,           precision: 19, scale: 4
      t.references :transport
      t.references :transporter
      t.string     :number
      t.string     :reference_number
      t.references :recipient,                                          null: false
      t.stamps
    end
    add_index :outgoing_deliveries, :address_id
    add_index :outgoing_deliveries, :mode_id
    add_index :outgoing_deliveries, :recipient_id
    add_index :outgoing_deliveries, :sale_id
    add_index :outgoing_deliveries, :transport_id
    add_index :outgoing_deliveries, :transporter_id

    create_table :outgoing_delivery_items do |t|
      t.references :delivery,                                            null: false, index: true
      t.references :sale_item,                                                        index: true
      t.decimal    :quantity,     precision: 19, scale: 4, default: 1.0, null: false
      t.references :product,                                             null: false, index: true
      t.references :source_product,                                      null: false, index: true
      t.stamps
    end

    create_table :outgoing_delivery_modes do |t|
      t.string   :name,                                     null: false
      t.string   :code,           limit: 10,                 null: false
      t.text     :description
      t.boolean  :with_transport,           default: false, null: false
      t.stamps
    end

    create_table :outgoing_payment_modes do |t|
      t.string     :name,                limit: 50,                 null: false
      t.boolean    :with_accounting,                default: false, null: false
      t.references :cash,                                                        index: true
      t.integer    :position
      t.references :attorney_journal,                                            index: true
      t.boolean    :active,                         default: false, null: false
      t.stamps
    end

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
      t.date     :to_bank_on,                                                         null: false
      t.references :cash,                                                             null: false
      t.string   :currency,         limit: 3,                                         null: false
      t.boolean  :downpayment,                                         default: true, null: false
      t.references :affair
      t.stamps
    end
    add_index :outgoing_payments, :affair_id
    add_index :outgoing_payments, :cash_id
    add_index :outgoing_payments, :journal_entry_id
    add_index :outgoing_payments, :mode_id
    add_index :outgoing_payments, :payee_id
    add_index :outgoing_payments, :responsible_id

    create_table :preferences do |t|
      t.string     :name,                                                      null: false
      t.string     :nature,            limit: 10,                              null: false
      t.text       :string_value
      t.boolean    :boolean_value
      t.integer    :integer_value
      t.decimal    :decimal_value,                precision: 19, scale: 4
      t.references :record_value,                 polymorphic: true,                        index: true
      t.references :user,                                                                   index: true
      t.stamps
      t.index      :name
    end

    create_table :prescriptions do |t|
      t.references :prescriptor,       null: false, index: true
      t.references :document,                       index: true
      t.string     :reference_number
      t.date       :delivered_on
      t.text       :description
      t.stamps
      t.index      :reference_number
      t.index      :delivered_on
    end


    create_table :product_indicator_data do |t|
      t.references :product,                                                            null: false, index: true
      t.references :move,                      polymorphic: true,                                    index: true
      t.references :operation_task,                                                                  index: true
      t.string     :indicator,                                                          null: false
      t.string     :indicator_datatype,                                                 null: false
      t.datetime   :measured_at,                                                        null: false
      t.decimal    :decimal_value,             precision: 19, scale: 4
      t.decimal    :measure_value_value,       precision: 19, scale: 4
      t.string     :measure_value_unit
      t.text       :string_value
      t.boolean    :boolean_value,                                      default: false, null: false
      t.string     :choice_value
      t.point      :point_value,               has_z: true
      t.geometry   :geometry_value,            has_z: true
      t.multi_polygon :multi_polygon_value,    has_z: true
      t.stamps
      t.index      :indicator
      t.index      :measured_at
    end

    create_table :product_enjoyments do |t|
      t.references :operation_task,                        index: true
      # t.references :move,  polymorphic: true,              index: true
      t.references :product,                  null: false, index: true
      t.string     :nature,                   null: false
      t.references :enjoyer,                               index: true
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
    end

    create_table :product_links do |t|
      # t.references :move,    polymorphic: true,              index: true
      t.references :carrier,                    null: false, index: true
      t.references :carried,                    null: false, index: true
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.references :operation_task,                          index: true
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
    end

    create_table :product_localizations do |t|
      # t.references :move,     polymorphic: true,              index: true
      t.references :product,                     null: false, index: true
      t.string     :nature,                      null: false
      t.references :container,                                index: true
      t.string     :arrival_cause
      t.string     :departure_cause
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.references :operation_task,                           index: true
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
    end

    create_table :product_measurements do |t|
      t.references :operation_task,                           index: true
      # t.references :move,     polymorphic: true,              index: true
      t.references :product,                     null: false, index: true
      t.string     :indicator,                   null: false, index: true
      t.references :reporter,                                 index: true
      t.references :tool,                                     index: true
      t.datetime   :measured_at,                 null: false
      t.stamps
      t.index      :measured_at
    end

    create_table :product_memberships do |t|
      # t.references :move,     polymorphic: true,              index: true
      t.references :member,                      null: false, index: true
      t.references :group,                       null: false, index: true
      t.datetime   :started_at,                  null: false
      t.datetime   :stopped_at
      t.references :operation_task,                           index: true
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
    end

    create_table :product_ownerships do |t|
      t.references :operation_task,                        index: true
      # t.references :move,  polymorphic: true,              index: true
      t.references :product,                  null: false, index: true
      t.string     :nature,                   null: false
      t.references :owner,                                 index: true
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
    end

    create_table :product_phases do |t|
      t.references :product,                    null: false, index: true
      t.references :variant,                    null: false, index: true
      t.references :nature,                     null: false, index: true
      t.references :category,                   null: false, index: true
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
    end

    # create_table :product_moves do |t|
    #   t.references :product,                                   null: false, index: true
    #   t.decimal    :population_delta, precision: 19, scale: 4, null: false
    #   t.datetime   :started_at
    #   t.datetime   :stopped_at
    #   t.boolean    :initial,                   default: false, null: false
    #   t.stamps
    #   t.index      :started_at
    #   t.index      :stopped_at
    # end

    create_table :product_births do |t|
      t.references :operation_task,                           index: true
      # t.references :move,     polymorphic: true,              index: true
      t.string     :nature,                      null: false
      t.references :producer,                                 index: true
      t.references :product,                     null: false, index: true
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
    end

    create_table :product_deaths do |t|
      t.references :operation_task,                           index: true
      # t.references :move,     polymorphic: true,              index: true
      t.string     :nature,                      null: false
      t.references :absorber,                                 index: true
      t.references :product,                     null: false, index: true
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.stamps
      t.index      :started_at
      t.index      :stopped_at
    end


    create_table :product_nature_variants do |t|
      t.references :nature,                               null: false, index: true
      t.string   :name
      t.string   :number
      t.string   :variety,                limit: 120,                 null: false
      t.string   :derivative_of,          limit: 120
      t.string   :nomen,                  limit: 120
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

    create_table :product_nature_variant_indicator_data do |t|
      t.references :variant,                                                                                            null: false, index: true
      t.string     :indicator,                                                                                          null: false
      t.string     :indicator_datatype,                                                                                 null: false
      t.string     :computation_method,                                                                                 null: false
      t.decimal    :decimal_value,                                             precision: 19, scale: 4
      t.decimal    :measure_value_value,                                       precision: 19, scale: 4
      t.string     :measure_value_unit
      t.text       :string_value
      t.boolean    :boolean_value,                                                                      default: false, null: false
      t.string     :choice_value
      t.point      :point_value,              has_z: true
      t.geometry   :geometry_value,           has_z: true
      t.multi_polygon :multi_polygon_value,   has_z: true
      t.stamps
      t.index      :indicator
    end

    create_table :product_nature_categories do |t|
      t.string     :name,                                               null: false
      t.string     :number,                 limit: 30,                  null: false
      t.text       :description
      t.string     :nomen,                  limit: 120
      t.string     :pictogram,              limit: 120
      t.boolean    :active,                             default: false, null: false
      t.boolean    :depreciable,                        default: false, null: false
      t.boolean    :saleable,                           default: false, null: false
      t.boolean    :purchasable,                        default: false, null: false
      t.boolean    :storable,                           default: false, null: false
      t.boolean    :reductible,                         default: false, null: false
      t.boolean    :subscribing,                        default: false, null: false
      t.references :subscription_nature,                                             index: true
      t.string     :subscription_duration
      t.references :charge_account,                                                  index: true
      t.references :product_account,                                                 index: true
      t.references :asset_account,                                                   index: true
      t.references :stock_account,                                                   index: true
      t.stamps
      t.index      :number,   unique: true
      t.index      :name
    end

    create_join_table :product_nature_categories, :taxes, table_name: :product_cat_sale_taxes do |t|
      t.index :product_nature_category_id
      t.index :tax_id
    end

    create_join_table :product_nature_categories, :taxes, table_name: :product_cat_purchase_taxes do |t|
      t.index :product_nature_category_id
      t.index :tax_id
    end

    create_table :product_natures do |t|
      t.string     :name,                                               null: false
      t.string     :number,                 limit: 30,                  null: false
      t.text       :description
      t.string     :variety,                limit: 120,                 null: false
      t.string     :derivative_of,          limit: 120
      t.string     :nomen,                  limit: 120
      t.text       :abilities
      t.text       :variable_indicators
      t.text       :frozen_indicators
      t.string     :population_counting,                                null: false
      t.string     :picture_file_name
      t.string     :picture_content_type
      t.integer    :picture_file_size
      t.datetime   :picture_updated_at
      t.boolean    :active,                             default: false, null: false
      t.boolean    :evolvable,                          default: false, null: false
      t.references :category,                           index: true, null: false
      t.stamps
      t.index      :number,   unique: true
      t.index      :name
    end

    create_table :product_process_phases do |t|
      t.references :process,                null: false, index: true
      t.string   :name,                     null: false
      t.string   :nature,                   null: false
      t.integer  :position
      t.string   :phase_delay
      t.string   :description
      t.stamps
    end

    create_table :product_processes do |t|
      t.string   :variety,      limit: 120,                 null: false
      t.string   :name,                                     null: false
      t.string   :nature,                                   null: false
      t.string   :description
      t.boolean  :repeatable,               default: false, null: false
      t.stamps
      t.index    :variety
    end

    create_table :production_supports do |t|
      t.references :production,                  null: false, index: true
      t.references :storage,                     null: false, index: true
      t.datetime :started_at
      t.datetime :stopped_at
      t.boolean  :exclusive,     default: false, null: false
      t.stamps
      t.index :started_at
      t.index :stopped_at
    end

    create_table :productions do |t|
      t.references :activity,                        null: false, index: true
      t.references :campaign,                        null: false, index: true
      t.references :variant,                               index: true
      t.string     :name,                            null: false
      t.string     :state,                           null: false
      t.boolean    :static_support,  default: false, null: false
      t.datetime   :started_at
      t.datetime   :stopped_at
      t.integer    :position
      t.stamps
      t.index      :name
    end

    create_table :products do |t|
      t.string     :type
      t.string     :name,                                                                          null: false
      t.string     :number,                                                                        null: false
      t.references :initial_container,                                                                          index: true
      t.string     :initial_arrival_cause,     limit: 120
      t.references :initial_owner,                                                                              index: true
      t.decimal    :initial_population,                   precision: 19, scale: 4, default: 0.0
      t.string     :variety,                  limit: 120,                                          null: false
      t.string     :derivative_of,            limit: 120
      t.references :variant,                                                                       null: false, index: true
      t.references :nature,                                                                        null: false, index: true
      t.references :category,                                                                        null: false, index: true
      t.references :tracking,                                                                                   index: true
      t.references :asset,                                                                                      index: true
      t.datetime   :born_at
      t.datetime   :dead_at
      t.text       :description
      t.string     :picture_file_name
      t.integer    :picture_file_size
      t.string     :picture_content_type
      t.datetime   :picture_updated_at
      t.string     :identification_number
      t.string     :work_number
      t.references :father,                                                                                     index: true
      t.references :mother,                                                                                     index: true
      t.references :address,                                                                                    index: true
      t.boolean    :reservoir,                                                     default: false, null: false
      t.references :content_nature,                                                                             index: true
      t.string     :content_indicator
      t.string     :content_indicator_unit
      t.decimal    :content_maximal_quantity,             precision: 19, scale: 4, default: 0.0,   null: false
      t.references :parent,                                                                                     index: true
      t.references :default_storage,                                                                            index: true
      t.stamps
      t.index      :type
      t.index      :name
      t.index      :variety
      t.index      :number,                 unique: true
    end

    create_table :professions do |t|
      t.string   :name,                         null: false
      t.string   :code
      t.boolean  :commercial,   default: false, null: false
      t.stamps
    end

    create_table :purchase_items do |t|
      t.references :purchase,                                                 null: false, index: true
      t.references :variant,                                                  null: false, index: true
      # t.references :price,                                                    null: false, index: true
      t.decimal    :quantity,          precision: 19, scale: 4, default: 1.0, null: false
      t.decimal    :pretax_amount,     precision: 19, scale: 4, default: 0.0, null: false
      t.decimal    :amount,            precision: 19, scale: 4, default: 0.0, null: false
      t.references :tax,                                                      null: false, index: true
      t.string     :indicator,         limit: 120,                            null: false
      t.string     :currency,          limit: 3,                              null: false
      t.text       :label
      t.text       :annotation
      t.integer    :position
      t.references :account,                                                  null: false, index: true
      # t.references :warehouse
      t.decimal    :unit_price_amount, precision: 19, scale: 4,               null: false
      # t.references :tracking
      # t.string     :tracking_serial
      # t.string     :unit
      # t.references :price_template
      t.stamps
    end

    create_table :purchase_natures do |t|
      t.boolean    :active,                    default: true,  null: false
      t.string     :name
      t.text       :description
      t.string     :currency,        limit: 3,                 null: false
      t.boolean    :with_accounting,           default: false, null: false
      t.references :journal,                                                index: true
      t.boolean    :by_default,                default: false, null: false
      t.stamps
      t.index      :currency
    end

    create_table :purchases do |t|
      t.references :supplier,                                                              null: false
      t.string     :number,              limit: 60,                                        null: false
      t.decimal    :pretax_amount,                  precision: 19, scale: 4, default: 0.0, null: false
      t.decimal    :amount,                         precision: 19, scale: 4, default: 0.0, null: false
      t.references :delivery_address
      t.text       :description
      t.date       :planned_on
      t.date       :invoiced_on
      t.date       :created_on
      t.datetime   :accounted_at
      t.references :journal_entry
      t.string     :reference_number
      t.string     :state,               limit: 60
      t.date       :confirmed_on
      t.references :responsible
      t.string     :currency,            limit: 3,                                         null: false
      t.references :nature
      t.references :affair
      t.stamps
    end
    add_index :purchases, :accounted_at
    add_index :purchases, :affair_id
    add_index :purchases, :currency
    add_index :purchases, :delivery_address_id
    add_index :purchases, :journal_entry_id
    add_index :purchases, :nature_id
    add_index :purchases, :responsible_id
    add_index :purchases, :supplier_id

    create_table :roles do |t|
      t.string   :name,                     null: false
      t.text     :rights
      t.stamps
    end

    create_table :sale_items do |t|
      t.references :sale,                                                        null: false, index: true
      t.references :variant,                                                     null: false, index: true
      t.references :price,                                                       null: false, index: true
      t.decimal    :quantity,             precision: 19, scale: 4, default: 1.0, null: false
      t.decimal    :pretax_amount,        precision: 19, scale: 4, default: 0.0, null: false
      t.decimal    :amount,               precision: 19, scale: 4, default: 0.0, null: false
      t.references :tax,                                                                      index: true
      t.string     :indicator,            limit: 120,                            null: false
      t.string     :currency,             limit: 3,                              null: false
      t.text       :label
      t.text       :annotation
      t.integer    :position
      t.references :account,                                                                  index: true
      # t.references :warehouse
      t.decimal    :unit_price_amount,    precision: 19, scale: 4
      t.decimal    :reduction_percentage, precision: 19, scale: 4, default: 0.0, null: false
      t.references :reduced_item,                                                             index: true
      t.references :credited_item,                                                            index: true
      t.stamps
    end

    create_table :sale_natures do |t|
      t.string     :name,                                                                       null: false
      t.boolean    :active,                                                     default: true,  null: false
      t.boolean    :by_default,                                                 default: false, null: false
      t.boolean    :downpayment,                                                default: false, null: false
      t.decimal    :downpayment_minimum,               precision: 19, scale: 4, default: 0.0
      t.decimal    :downpayment_percentage,            precision: 19, scale: 4, default: 0.0
      t.references :payment_mode,                                                                            index: true
      t.references :catalog,                                                                    null: false, index: true
      t.text       :payment_mode_complement
      t.string     :currency,                limit: 3,                                          null: false
      t.text       :sales_conditions
      t.string     :expiration_delay,                                                           null: false
      t.string     :payment_delay,                                                              null: false
      t.boolean    :with_accounting,                                            default: false, null: false
      t.references :journal,                                                                                 index: true
      t.text       :description
      t.stamps
    end

    create_table :sales do |t|
      t.references :client,                                                                  null: false
      t.references :nature
      t.date       :created_on,                                                              null: false
      t.string     :number,              limit: 60,                                          null: false
      t.decimal    :pretax_amount,                  precision: 19, scale: 4, default: 0.0,   null: false
      t.decimal    :amount,                         precision: 19, scale: 4, default: 0.0,   null: false
      t.string     :state,               limit: 60,                                          null: false
      t.date       :expired_on
      t.boolean    :has_downpayment,                                         default: false, null: false
      t.decimal    :downpayment_amount,             precision: 19, scale: 4, default: 0.0,   null: false
      t.references :address
      t.references :invoice_address
      t.references :delivery_address
      t.string     :subject
      t.string     :function_title
      t.text       :introduction
      t.text       :conclusion
      t.text       :description
      t.date       :confirmed_on
      t.references :responsible
      t.boolean    :letter_format,                                           default: true,  null: false
      t.text       :annotation
      t.references :transporter
      t.datetime   :accounted_at
      t.references :journal_entry
      t.string     :reference_number
      t.date       :invoiced_on
      t.boolean    :credit,                                                  default: false, null: false
      t.date       :payment_on
      t.references :origin
      t.string     :initial_number,      limit: 60
      t.string     :currency,            limit: 3,                                           null: false
      t.references :affair
      t.string     :expiration_delay
      t.string     :payment_delay,                                                           null: false
      t.stamps
    end
    add_index :sales, :accounted_at
    add_index :sales, :address_id
    add_index :sales, :affair_id
    add_index :sales, :client_id
    add_index :sales, :currency
    add_index :sales, :delivery_address_id
    add_index :sales, :invoice_address_id
    add_index :sales, :journal_entry_id
    add_index :sales, :nature_id
    add_index :sales, :origin_id
    add_index :sales, :responsible_id
    add_index :sales, :transporter_id

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
      t.string   :entity_link_nature,    limit: 120
      t.string   :entity_link_direction, limit: 30
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
    add_index :subscriptions, :address_id
    add_index :subscriptions, :nature_id
    add_index :subscriptions, :product_nature_id
    add_index :subscriptions, :sale_id
    add_index :subscriptions, :sale_item_id
    add_index :subscriptions, :subscriber_id

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
    add_index :tax_declarations, :financial_year_id
    add_index :tax_declarations, :journal_entry_id

    create_table :taxes do |t|
      t.string     :name,                                                                      null: false
      t.boolean    :included,                                                  default: false, null: false
      t.boolean    :reductible,                                                default: true,  null: false
      t.string     :computation_method,   limit: 20,                                           null: false
      t.decimal    :amount,                           precision: 19, scale: 4, default: 0.0,   null: false
      t.text       :description
      t.references :collect_account,                                                                        index: true
      t.references :deduction_account,                                                                      index: true
      t.string     :nomen,                limit: 120
      t.stamps
    end

    create_table :teams do |t|
      t.string     :name,                         null: false
      t.text       :description
      t.references :parent,                                    index: true
      t.text       :sales_conditions
      t.integer    :lft
      t.integer    :rgt
      t.integer    :depth,            default: 0, null: false
      t.stamps
    end

    create_table :trackings do |t|
      t.string     :name,                        null: false
      t.string     :serial
      t.boolean    :active,       default: true, null: false
      t.text       :description
      t.references :product,                                 index: true
      t.references :producer,                                index: true
      t.stamps
    end

    create_table :transfers do |t|
      t.decimal  :amount,                     precision: 19, scale: 4, default: 0.0, null: false
      t.string   :currency,         limit: 3,                                        null: false
      t.references :client,                                                          null: false
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
    add_index :transfers, :accounted_at
    add_index :transfers, :affair_id
    add_index :transfers, :client_id
    add_index :transfers, :journal_entry_id

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
    add_index :transports, :purchase_id
    add_index :transports, :responsible_id
    add_index :transports, :transporter_id

    create_table :users do |t|
      t.string     :first_name,                                                                          null: false
      t.string     :last_name,                                                                           null: false
      t.boolean    :locked,                                                              default: false, null: false
      t.string     :email,                                                                               null: false
      t.references :person,                                                                                           index: true, unique: true
      t.references :role,                                                                                null: false, index: true
      t.decimal    :maximal_grantable_reduction_percentage,     precision: 19, scale: 4, default: 5.0,   null: false
      t.boolean    :administrator,                                                       default: true,  null: false
      t.text       :rights
      t.date       :arrived_on
      t.text       :description
      t.boolean    :commercial,                                                          default: false, null: false
      t.datetime   :departed_at
      t.references :team,                                                                                             index: true
      t.references :establishment,                                                                                    index: true
      t.string     :office
      t.references :profession,                                                                                       index: true
      t.boolean    :employed,                                                              default: false, null: false
      t.string     :employment
      t.string     :language,                               limit: 3,                                      null: false
      t.datetime   :last_sign_in_at
      t.string     :encrypted_password,                                                    default: "",    null: false
      t.string     :reset_password_token
      t.datetime   :reset_password_sent_at
      t.datetime   :remember_created_at
      t.integer    :sign_in_count,                                                         default: 0
      t.datetime   :current_sign_in_at
      t.string     :current_sign_in_ip
      t.string     :last_sign_in_ip
      t.string     :confirmation_token
      t.datetime   :confirmed_at
      t.datetime   :confirmation_sent_at
      t.string     :unconfirmed_email
      t.integer    :failed_attempts,                                                        default: 0
      t.string     :unlock_token
      t.datetime   :locked_at
      t.string     :authentication_token
      t.stamps
      t.index    :authentication_token, unique: true
      t.index    :confirmation_token, unique: true
      t.index    :email, unique: true
      t.index    :reset_password_token, unique: true
      t.index    :unlock_token, unique: true
    end

  end

end
