# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100917102657) do

  create_table "eky_account_balances", :force => true do |t|
    t.integer  "account_id",                                                        :null => false
    t.integer  "financial_year_id",                                                 :null => false
    t.decimal  "global_debit",      :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "global_credit",     :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "global_balance",    :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "global_count",                                     :default => 0,   :null => false
    t.decimal  "local_debit",       :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "local_credit",      :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "local_balance",     :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "local_count",                                      :default => 0,   :null => false
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,   :null => false
  end

  add_index "eky_account_balances", ["account_id", "financial_year_id", "company_id"], :name => "eky_account_balances_unique", :unique => true
  add_index "eky_account_balances", ["company_id"], :name => "index_eky_account_balances_on_company_id"
  add_index "eky_account_balances", ["created_at"], :name => "index_eky_account_balances_on_created_at"
  add_index "eky_account_balances", ["creator_id"], :name => "index_eky_account_balances_on_creator_id"
  add_index "eky_account_balances", ["financial_year_id"], :name => "index_eky_account_balances_on_financialyear_id"
  add_index "eky_account_balances", ["updated_at"], :name => "index_eky_account_balances_on_updated_at"
  add_index "eky_account_balances", ["updater_id"], :name => "index_eky_account_balances_on_updater_id"

  create_table "eky_accounts", :force => true do |t|
    t.string   "number",       :limit => 16,                     :null => false
    t.string   "name",         :limit => 208,                    :null => false
    t.string   "label",                                          :null => false
    t.boolean  "is_debit",                    :default => false, :null => false
    t.string   "last_letter",  :limit => 8
    t.text     "comment"
    t.integer  "company_id",                                     :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                :default => 0,     :null => false
  end

  add_index "eky_accounts", ["company_id"], :name => "index_eky_accounts_on_company_id"
  add_index "eky_accounts", ["created_at"], :name => "index_eky_accounts_on_created_at"
  add_index "eky_accounts", ["creator_id"], :name => "index_eky_accounts_on_creator_id"
  add_index "eky_accounts", ["name", "company_id"], :name => "index_eky_accounts_on_name_and_company_id"
  add_index "eky_accounts", ["number", "company_id"], :name => "index_eky_accounts_on_number_and_company_id", :unique => true
  add_index "eky_accounts", ["updated_at"], :name => "index_eky_accounts_on_updated_at"
  add_index "eky_accounts", ["updater_id"], :name => "index_eky_accounts_on_updater_id"

  create_table "eky_areas", :force => true do |t|
    t.string   "postcode",                                    :null => false
    t.string   "name",                                        :null => false
    t.integer  "company_id",                                  :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0,    :null => false
    t.string   "country",      :limit => 2, :default => "??"
    t.integer  "district_id"
    t.string   "city"
    t.string   "city_name"
    t.string   "code"
  end

  add_index "eky_areas", ["created_at"], :name => "index_eky_areas_on_created_at"
  add_index "eky_areas", ["creator_id"], :name => "index_eky_areas_on_creator_id"
  add_index "eky_areas", ["district_id"], :name => "index_eky_areas_on_district_id"
  add_index "eky_areas", ["updated_at"], :name => "index_eky_areas_on_updated_at"
  add_index "eky_areas", ["updater_id"], :name => "index_eky_areas_on_updater_id"

  create_table "eky_bank_statements", :force => true do |t|
    t.integer  "cash_id",                                                         :null => false
    t.date     "started_on",                                                      :null => false
    t.date     "stopped_on",                                                      :null => false
    t.string   "number",                                                          :null => false
    t.decimal  "debit",           :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "credit",          :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "company_id",                                                      :null => false
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                   :default => 0,   :null => false
    t.decimal  "currency_debit",  :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "currency_credit", :precision => 16, :scale => 2, :default => 0.0, :null => false
  end

  add_index "eky_bank_statements", ["cash_id"], :name => "index_eky_bank_account_statements_on_bank_account_id"
  add_index "eky_bank_statements", ["company_id"], :name => "index_eky_bank_account_statements_on_company_id"
  add_index "eky_bank_statements", ["created_at"], :name => "index_eky_bank_account_statements_on_created_at"
  add_index "eky_bank_statements", ["creator_id"], :name => "index_eky_bank_account_statements_on_creator_id"
  add_index "eky_bank_statements", ["updated_at"], :name => "index_eky_bank_account_statements_on_updated_at"
  add_index "eky_bank_statements", ["updater_id"], :name => "index_eky_bank_account_statements_on_updater_id"

  create_table "eky_cash_transfers", :force => true do |t|
    t.integer  "emitter_cash_id",                                                  :null => false
    t.integer  "receiver_cash_id",                                                 :null => false
    t.integer  "journal_entry_id"
    t.datetime "accounted_at"
    t.string   "number",                                                           :null => false
    t.text     "comment"
    t.integer  "currency_id",                                                      :null => false
    t.decimal  "currency_rate",    :precision => 16, :scale => 6, :default => 1.0, :null => false
    t.decimal  "currency_amount",  :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "company_id",                                                       :null => false
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,   :null => false
  end

  add_index "eky_cash_transfers", ["company_id"], :name => "index_eky_cash_transfers_on_company_id"
  add_index "eky_cash_transfers", ["created_at"], :name => "index_eky_cash_transfers_on_created_at"
  add_index "eky_cash_transfers", ["creator_id"], :name => "index_eky_cash_transfers_on_creator_id"
  add_index "eky_cash_transfers", ["updated_at"], :name => "index_eky_cash_transfers_on_updated_at"
  add_index "eky_cash_transfers", ["updater_id"], :name => "index_eky_cash_transfers_on_updater_id"

  create_table "eky_cashes", :force => true do |t|
    t.string   "name",                                                   :null => false
    t.string   "iban",         :limit => 34
    t.string   "iban_label",   :limit => 48
    t.string   "bic",          :limit => 16
    t.integer  "journal_id",                                             :null => false
    t.integer  "currency_id",                                            :null => false
    t.integer  "account_id",                                             :null => false
    t.integer  "company_id",                                             :null => false
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,              :null => false
    t.integer  "entity_id"
    t.string   "bank_code"
    t.string   "agency_code"
    t.string   "number"
    t.string   "key"
    t.string   "mode",                       :default => "IBAN",         :null => false
    t.boolean  "by_default",                 :default => false,          :null => false
    t.text     "address"
    t.string   "bank_name",    :limit => 50
    t.string   "nature",       :limit => 16, :default => "bank_account", :null => false
  end

  add_index "eky_cashes", ["account_id"], :name => "index_eky_bank_accounts_on_account_id"
  add_index "eky_cashes", ["company_id"], :name => "index_eky_bank_accounts_on_company_id"
  add_index "eky_cashes", ["created_at"], :name => "index_eky_bank_accounts_on_created_at"
  add_index "eky_cashes", ["creator_id"], :name => "index_eky_bank_accounts_on_creator_id"
  add_index "eky_cashes", ["currency_id"], :name => "index_eky_bank_accounts_on_currency_id"
  add_index "eky_cashes", ["entity_id"], :name => "index_eky_bank_accounts_on_entity_id"
  add_index "eky_cashes", ["journal_id"], :name => "index_eky_bank_accounts_on_journal_id"
  add_index "eky_cashes", ["updated_at"], :name => "index_eky_bank_accounts_on_updated_at"
  add_index "eky_cashes", ["updater_id"], :name => "index_eky_bank_accounts_on_updater_id"

  create_table "eky_companies", :force => true do |t|
    t.string   "name",                                              :null => false
    t.string   "code",             :limit => 16,                    :null => false
    t.date     "born_on"
    t.boolean  "locked",                         :default => false, :null => false
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                   :default => 0,     :null => false
    t.integer  "entity_id"
    t.text     "sales_conditions"
  end

  add_index "eky_companies", ["code"], :name => "index_eky_companies_on_code", :unique => true
  add_index "eky_companies", ["created_at"], :name => "index_eky_companies_on_created_at"
  add_index "eky_companies", ["creator_id"], :name => "index_eky_companies_on_creator_id"
  add_index "eky_companies", ["name"], :name => "index_eky_companies_on_name"
  add_index "eky_companies", ["updated_at"], :name => "index_eky_companies_on_updated_at"
  add_index "eky_companies", ["updater_id"], :name => "index_eky_companies_on_updater_id"

  create_table "eky_contacts", :force => true do |t|
    t.integer  "entity_id",                                      :null => false
    t.boolean  "by_default",                  :default => false, :null => false
    t.string   "line_2",       :limit => 38
    t.string   "line_3",       :limit => 38
    t.string   "line_5",       :limit => 38
    t.string   "address",      :limit => 280
    t.string   "phone",        :limit => 32
    t.string   "fax",          :limit => 32
    t.string   "mobile",       :limit => 32
    t.string   "email"
    t.string   "website"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "company_id",                                     :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                :default => 0,     :null => false
    t.string   "country",      :limit => 2
    t.string   "code",         :limit => 4
    t.datetime "deleted_at"
    t.integer  "area_id"
    t.string   "line_6"
    t.string   "line_4",       :limit => 48
  end

  add_index "eky_contacts", ["by_default"], :name => "index_eky_contacts_on_default"
  add_index "eky_contacts", ["code"], :name => "index_eky_contacts_on_code"
  add_index "eky_contacts", ["company_id"], :name => "index_eky_contacts_on_company_id"
  add_index "eky_contacts", ["created_at"], :name => "index_eky_contacts_on_created_at"
  add_index "eky_contacts", ["creator_id"], :name => "index_eky_contacts_on_creator_id"
  add_index "eky_contacts", ["deleted_at"], :name => "index_eky_contacts_on_stopped_at"
  add_index "eky_contacts", ["entity_id"], :name => "index_eky_contacts_on_entity_id"
  add_index "eky_contacts", ["updated_at"], :name => "index_eky_contacts_on_updated_at"
  add_index "eky_contacts", ["updater_id"], :name => "index_eky_contacts_on_updater_id"

  create_table "eky_currencies", :force => true do |t|
    t.string   "name",                                                                         :null => false
    t.string   "code",                                                                         :null => false
    t.string   "format",       :limit => 16,                                                   :null => false
    t.decimal  "rate",                       :precision => 16, :scale => 6, :default => 1.0,   :null => false
    t.boolean  "active",                                                    :default => true,  :null => false
    t.text     "comment"
    t.integer  "company_id",                                                                   :null => false
    t.datetime "created_at",                                                                   :null => false
    t.datetime "updated_at",                                                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                              :default => 0,     :null => false
    t.boolean  "by_default",                                                :default => false, :null => false
    t.string   "symbol",                                                    :default => "-",   :null => false
  end

  add_index "eky_currencies", ["active"], :name => "index_eky_currencies_on_active"
  add_index "eky_currencies", ["code", "company_id"], :name => "index_eky_currencies_on_code_and_company_id", :unique => true
  add_index "eky_currencies", ["company_id"], :name => "index_eky_currencies_on_company_id"
  add_index "eky_currencies", ["created_at"], :name => "index_eky_currencies_on_created_at"
  add_index "eky_currencies", ["creator_id"], :name => "index_eky_currencies_on_creator_id"
  add_index "eky_currencies", ["name"], :name => "index_eky_currencies_on_name"
  add_index "eky_currencies", ["updated_at"], :name => "index_eky_currencies_on_updated_at"
  add_index "eky_currencies", ["updater_id"], :name => "index_eky_currencies_on_updater_id"

  create_table "eky_custom_field_choices", :force => true do |t|
    t.integer  "custom_field_id",                :null => false
    t.string   "name",                           :null => false
    t.string   "value",                          :null => false
    t.integer  "company_id",                     :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    :default => 0, :null => false
    t.integer  "position"
  end

  add_index "eky_custom_field_choices", ["company_id"], :name => "index_eky_complement_choices_on_company_id"
  add_index "eky_custom_field_choices", ["created_at"], :name => "index_eky_complement_choices_on_created_at"
  add_index "eky_custom_field_choices", ["creator_id"], :name => "index_eky_complement_choices_on_creator_id"
  add_index "eky_custom_field_choices", ["custom_field_id"], :name => "index_eky_complement_choices_on_complement_id"
  add_index "eky_custom_field_choices", ["updated_at"], :name => "index_eky_complement_choices_on_updated_at"
  add_index "eky_custom_field_choices", ["updater_id"], :name => "index_eky_complement_choices_on_updater_id"

  create_table "eky_custom_field_data", :force => true do |t|
    t.integer  "entity_id",                                                     :null => false
    t.integer  "custom_field_id",                                               :null => false
    t.decimal  "decimal_value",   :precision => 16, :scale => 4
    t.text     "string_value"
    t.boolean  "boolean_value"
    t.date     "date_value"
    t.datetime "datetime_value"
    t.integer  "choice_value_id"
    t.integer  "company_id",                                                    :null => false
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                   :default => 0, :null => false
  end

  add_index "eky_custom_field_data", ["choice_value_id"], :name => "index_eky_complement_data_on_choice_value_id"
  add_index "eky_custom_field_data", ["company_id", "custom_field_id", "entity_id"], :name => "index_eky_complement_data_on_entity_id_and_complement_id", :unique => true
  add_index "eky_custom_field_data", ["company_id"], :name => "index_eky_complement_data_on_company_id"
  add_index "eky_custom_field_data", ["created_at"], :name => "index_eky_complement_data_on_created_at"
  add_index "eky_custom_field_data", ["creator_id"], :name => "index_eky_complement_data_on_creator_id"
  add_index "eky_custom_field_data", ["custom_field_id"], :name => "index_eky_complement_data_on_complement_id"
  add_index "eky_custom_field_data", ["entity_id"], :name => "index_eky_complement_data_on_entity_id"
  add_index "eky_custom_field_data", ["updated_at"], :name => "index_eky_complement_data_on_updated_at"
  add_index "eky_custom_field_data", ["updater_id"], :name => "index_eky_complement_data_on_updater_id"

  create_table "eky_custom_fields", :force => true do |t|
    t.string   "name",                                                                        :null => false
    t.string   "nature",       :limit => 8,                                                   :null => false
    t.integer  "position"
    t.boolean  "active",                                                   :default => true,  :null => false
    t.boolean  "required",                                                 :default => false, :null => false
    t.integer  "length_max"
    t.decimal  "decimal_min",               :precision => 16, :scale => 4
    t.decimal  "decimal_max",               :precision => 16, :scale => 4
    t.integer  "company_id",                                                                  :null => false
    t.datetime "created_at",                                                                  :null => false
    t.datetime "updated_at",                                                                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                             :default => 0,     :null => false
  end

  add_index "eky_custom_fields", ["company_id", "position"], :name => "index_eky_complements_on_company_id_and_position"
  add_index "eky_custom_fields", ["company_id"], :name => "index_eky_complements_on_company_id"
  add_index "eky_custom_fields", ["created_at"], :name => "index_eky_complements_on_created_at"
  add_index "eky_custom_fields", ["creator_id"], :name => "index_eky_complements_on_creator_id"
  add_index "eky_custom_fields", ["required"], :name => "index_eky_complements_on_required"
  add_index "eky_custom_fields", ["updated_at"], :name => "index_eky_complements_on_updated_at"
  add_index "eky_custom_fields", ["updater_id"], :name => "index_eky_complements_on_updater_id"

  create_table "eky_delays", :force => true do |t|
    t.string   "name",                           :null => false
    t.boolean  "active",       :default => true, :null => false
    t.string   "expression",                     :null => false
    t.text     "comment"
    t.integer  "company_id",                     :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0,    :null => false
  end

  add_index "eky_delays", ["created_at"], :name => "index_eky_delays_on_created_at"
  add_index "eky_delays", ["creator_id"], :name => "index_eky_delays_on_creator_id"
  add_index "eky_delays", ["name", "company_id"], :name => "index_eky_delays_on_name_and_company_id", :unique => true
  add_index "eky_delays", ["updated_at"], :name => "index_eky_delays_on_updated_at"
  add_index "eky_delays", ["updater_id"], :name => "index_eky_delays_on_updater_id"

  create_table "eky_departments", :force => true do |t|
    t.string   "name",                            :null => false
    t.text     "comment"
    t.integer  "parent_id"
    t.integer  "company_id",                      :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     :default => 0, :null => false
    t.text     "sales_conditions"
  end

  add_index "eky_departments", ["created_at"], :name => "index_eky_departments_on_created_at"
  add_index "eky_departments", ["creator_id"], :name => "index_eky_departments_on_creator_id"
  add_index "eky_departments", ["name", "company_id"], :name => "index_eky_departments_on_name_and_company_id", :unique => true
  add_index "eky_departments", ["parent_id"], :name => "index_eky_departments_on_parent_id"
  add_index "eky_departments", ["updated_at"], :name => "index_eky_departments_on_updated_at"
  add_index "eky_departments", ["updater_id"], :name => "index_eky_departments_on_updater_id"

  create_table "eky_deposit_lines", :force => true do |t|
    t.integer  "deposit_id",                                                   :null => false
    t.decimal  "quantity",     :precision => 16, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",       :precision => 16, :scale => 2, :default => 1.0, :null => false
    t.integer  "company_id",                                                   :null => false
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0,   :null => false
  end

  add_index "eky_deposit_lines", ["company_id"], :name => "index_eky_deposit_lines_on_company_id"
  add_index "eky_deposit_lines", ["created_at"], :name => "index_eky_deposit_lines_on_created_at"
  add_index "eky_deposit_lines", ["creator_id"], :name => "index_eky_deposit_lines_on_creator_id"
  add_index "eky_deposit_lines", ["deposit_id", "company_id"], :name => "index_eky_deposit_lines_on_deposit_id_and_company_id"
  add_index "eky_deposit_lines", ["updated_at"], :name => "index_eky_deposit_lines_on_updated_at"
  add_index "eky_deposit_lines", ["updater_id"], :name => "index_eky_deposit_lines_on_updater_id"

  create_table "eky_deposits", :force => true do |t|
    t.decimal  "amount",           :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.integer  "payments_count",                                  :default => 0,     :null => false
    t.date     "created_on",                                                         :null => false
    t.text     "comment"
    t.integer  "cash_id",                                                            :null => false
    t.integer  "mode_id",                                                            :null => false
    t.integer  "company_id",                                                         :null => false
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,     :null => false
    t.boolean  "locked",                                          :default => false, :null => false
    t.integer  "responsible_id"
    t.string   "number"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.boolean  "in_cash",                                         :default => false, :null => false
  end

  add_index "eky_deposits", ["created_at"], :name => "index_eky_embankments_on_created_at"
  add_index "eky_deposits", ["creator_id"], :name => "index_eky_embankments_on_creator_id"
  add_index "eky_deposits", ["updated_at"], :name => "index_eky_embankments_on_updated_at"
  add_index "eky_deposits", ["updater_id"], :name => "index_eky_embankments_on_updater_id"

  create_table "eky_districts", :force => true do |t|
    t.string   "name",                        :null => false
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
    t.string   "code"
  end

  add_index "eky_districts", ["created_at"], :name => "index_eky_districts_on_created_at"
  add_index "eky_districts", ["creator_id"], :name => "index_eky_districts_on_creator_id"
  add_index "eky_districts", ["updated_at"], :name => "index_eky_districts_on_updated_at"
  add_index "eky_districts", ["updater_id"], :name => "index_eky_districts_on_updater_id"

  create_table "eky_document_templates", :force => true do |t|
    t.string   "name",                                          :null => false
    t.boolean  "active",                     :default => false, :null => false
    t.text     "source"
    t.text     "cache"
    t.string   "country",      :limit => 2
    t.integer  "company_id",                                    :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,     :null => false
    t.string   "code",         :limit => 32
    t.string   "family",       :limit => 32
    t.boolean  "to_archive"
    t.boolean  "by_default",                 :default => true,  :null => false
    t.string   "nature",       :limit => 20
    t.string   "filename"
    t.string   "language",     :limit => 3,  :default => "???", :null => false
  end

  add_index "eky_document_templates", ["company_id", "active"], :name => "index_eky_document_templates_on_company_id_and_active"
  add_index "eky_document_templates", ["company_id", "name"], :name => "index_eky_document_templates_on_company_id_and_name"
  add_index "eky_document_templates", ["company_id"], :name => "index_eky_document_templates_on_company_id"
  add_index "eky_document_templates", ["created_at"], :name => "index_eky_document_templates_on_created_at"
  add_index "eky_document_templates", ["creator_id"], :name => "index_eky_document_templates_on_creator_id"
  add_index "eky_document_templates", ["updated_at"], :name => "index_eky_document_templates_on_updated_at"
  add_index "eky_document_templates", ["updater_id"], :name => "index_eky_document_templates_on_updater_id"

  create_table "eky_documents", :force => true do |t|
    t.string   "filename"
    t.string   "original_name",                :null => false
    t.integer  "filesize"
    t.binary   "crypt_key"
    t.string   "crypt_mode",                   :null => false
    t.string   "sha256",                       :null => false
    t.datetime "printed_at"
    t.integer  "company_id",                   :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",  :default => 0, :null => false
    t.string   "subdir"
    t.string   "extension"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "template_id"
    t.string   "nature_code"
  end

  add_index "eky_documents", ["company_id"], :name => "index_eky_documents_on_company_id"
  add_index "eky_documents", ["created_at"], :name => "index_eky_documents_on_created_at"
  add_index "eky_documents", ["creator_id"], :name => "index_eky_documents_on_creator_id"
  add_index "eky_documents", ["owner_id"], :name => "index_eky_documents_on_owner_id"
  add_index "eky_documents", ["owner_type"], :name => "index_eky_documents_on_owner_type"
  add_index "eky_documents", ["sha256"], :name => "index_eky_documents_on_sha256"
  add_index "eky_documents", ["updated_at"], :name => "index_eky_documents_on_updated_at"
  add_index "eky_documents", ["updater_id"], :name => "index_eky_documents_on_updater_id"

  create_table "eky_entities", :force => true do |t|
    t.integer  "nature_id",                                                                                :null => false
    t.string   "last_name",                                                                                :null => false
    t.string   "first_name"
    t.string   "full_name",                                                                                :null => false
    t.string   "code",                      :limit => 64
    t.boolean  "active",                                                                :default => true,  :null => false
    t.date     "born_on"
    t.date     "dead_on"
    t.string   "ean13",                     :limit => 13
    t.string   "soundex",                   :limit => 4
    t.string   "website"
    t.boolean  "client",                                                                :default => false, :null => false
    t.boolean  "supplier",                                                              :default => false, :null => false
    t.integer  "company_id",                                                                               :null => false
    t.datetime "created_at",                                                                               :null => false
    t.datetime "updated_at",                                                                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                          :default => 0,     :null => false
    t.integer  "client_account_id"
    t.integer  "supplier_account_id"
    t.boolean  "vat_submissive",                                                        :default => true,  :null => false
    t.boolean  "reflation_submissive",                                                  :default => false, :null => false
    t.string   "deliveries_conditions",     :limit => 60
    t.decimal  "discount_rate",                           :precision => 8, :scale => 2
    t.decimal  "reduction_rate",                          :precision => 8, :scale => 2
    t.text     "comment"
    t.string   "excise",                    :limit => 15
    t.string   "vat_number",                :limit => 15
    t.string   "country",                   :limit => 2
    t.integer  "authorized_payments_count"
    t.integer  "responsible_id"
    t.integer  "proposer_id"
    t.integer  "payment_mode_id"
    t.integer  "payment_delay_id"
    t.integer  "invoices_count"
    t.date     "first_met_on"
    t.integer  "category_id"
    t.string   "siren",                     :limit => 9
    t.string   "origin"
    t.string   "webpass"
    t.string   "activity_code",             :limit => 32
    t.string   "photo"
    t.boolean  "transporter",                                                           :default => false, :null => false
    t.string   "language",                  :limit => 3,                                :default => "???", :null => false
    t.boolean  "prospect",                                                              :default => false, :null => false
    t.boolean  "attorney",                                                              :default => false, :null => false
    t.integer  "attorney_account_id"
    t.string   "name",                      :limit => 32
    t.string   "salt",                      :limit => 64
    t.string   "hashed_password",           :limit => 64
    t.boolean  "locked",                                                                :default => false, :null => false
  end

  add_index "eky_entities", ["code", "company_id"], :name => "index_eky_entities_on_code_and_company_id", :unique => true
  add_index "eky_entities", ["company_id"], :name => "index_eky_entities_on_company_id"
  add_index "eky_entities", ["created_at"], :name => "index_eky_entities_on_created_at"
  add_index "eky_entities", ["creator_id"], :name => "index_eky_entities_on_creator_id"
  add_index "eky_entities", ["full_name", "company_id"], :name => "index_eky_entities_on_full_name_and_company_id"
  add_index "eky_entities", ["last_name", "company_id"], :name => "index_eky_entities_on_name_and_company_id"
  add_index "eky_entities", ["soundex", "company_id"], :name => "index_eky_entities_on_soundex_and_company_id"
  add_index "eky_entities", ["updated_at"], :name => "index_eky_entities_on_updated_at"
  add_index "eky_entities", ["updater_id"], :name => "index_eky_entities_on_updater_id"

  create_table "eky_entity_categories", :force => true do |t|
    t.string   "name",                                         :null => false
    t.text     "description"
    t.boolean  "by_default",                :default => false, :null => false
    t.integer  "company_id",                                   :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0,     :null => false
    t.string   "code",         :limit => 8
  end

  add_index "eky_entity_categories", ["code", "company_id"], :name => "index_eky_entity_categories_on_code_and_company_id", :unique => true
  add_index "eky_entity_categories", ["created_at"], :name => "index_eky_entity_categories_on_created_at"
  add_index "eky_entity_categories", ["creator_id"], :name => "index_eky_entity_categories_on_creator_id"
  add_index "eky_entity_categories", ["updated_at"], :name => "index_eky_entity_categories_on_updated_at"
  add_index "eky_entity_categories", ["updater_id"], :name => "index_eky_entity_categories_on_updater_id"

  create_table "eky_entity_link_natures", :force => true do |t|
    t.string   "name",                                  :null => false
    t.string   "name_1_to_2"
    t.string   "name_2_to_1"
    t.boolean  "symmetric",          :default => false, :null => false
    t.integer  "company_id",                            :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",       :default => 0,     :null => false
    t.boolean  "propagate_contacts", :default => false, :null => false
    t.text     "comment"
  end

  add_index "eky_entity_link_natures", ["company_id"], :name => "index_eky_entity_link_natures_on_company_id"
  add_index "eky_entity_link_natures", ["created_at"], :name => "index_eky_entity_link_natures_on_created_at"
  add_index "eky_entity_link_natures", ["creator_id"], :name => "index_eky_entity_link_natures_on_creator_id"
  add_index "eky_entity_link_natures", ["name"], :name => "index_eky_entity_link_natures_on_name"
  add_index "eky_entity_link_natures", ["name_1_to_2"], :name => "index_eky_entity_link_natures_on_name_1_to_2"
  add_index "eky_entity_link_natures", ["name_2_to_1"], :name => "index_eky_entity_link_natures_on_name_2_to_1"
  add_index "eky_entity_link_natures", ["updated_at"], :name => "index_eky_entity_link_natures_on_updated_at"
  add_index "eky_entity_link_natures", ["updater_id"], :name => "index_eky_entity_link_natures_on_updater_id"

  create_table "eky_entity_links", :force => true do |t|
    t.integer  "entity_1_id",                 :null => false
    t.integer  "entity_2_id",                 :null => false
    t.integer  "nature_id",                   :null => false
    t.date     "started_on"
    t.date     "stopped_on"
    t.text     "comment"
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "eky_entity_links", ["company_id"], :name => "index_eky_entity_links_on_company_id"
  add_index "eky_entity_links", ["created_at"], :name => "index_eky_entity_links_on_created_at"
  add_index "eky_entity_links", ["creator_id"], :name => "index_eky_entity_links_on_creator_id"
  add_index "eky_entity_links", ["entity_1_id"], :name => "index_eky_entity_links_on_entity1_id"
  add_index "eky_entity_links", ["entity_2_id"], :name => "index_eky_entity_links_on_entity2_id"
  add_index "eky_entity_links", ["nature_id"], :name => "index_eky_entity_links_on_nature_id"
  add_index "eky_entity_links", ["updated_at"], :name => "index_eky_entity_links_on_updated_at"
  add_index "eky_entity_links", ["updater_id"], :name => "index_eky_entity_links_on_updater_id"

  create_table "eky_entity_natures", :force => true do |t|
    t.string   "name",                            :null => false
    t.string   "title"
    t.boolean  "active",       :default => true,  :null => false
    t.boolean  "physical",     :default => false, :null => false
    t.boolean  "in_name",      :default => true,  :null => false
    t.text     "description"
    t.integer  "company_id",                      :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0,     :null => false
    t.string   "format"
  end

  add_index "eky_entity_natures", ["company_id"], :name => "index_eky_entity_natures_on_company_id"
  add_index "eky_entity_natures", ["created_at"], :name => "index_eky_entity_natures_on_created_at"
  add_index "eky_entity_natures", ["creator_id"], :name => "index_eky_entity_natures_on_creator_id"
  add_index "eky_entity_natures", ["name", "company_id"], :name => "index_eky_entity_natures_on_name_and_company_id", :unique => true
  add_index "eky_entity_natures", ["updated_at"], :name => "index_eky_entity_natures_on_updated_at"
  add_index "eky_entity_natures", ["updater_id"], :name => "index_eky_entity_natures_on_updater_id"

  create_table "eky_establishments", :force => true do |t|
    t.string   "name",                                     :null => false
    t.string   "nic",          :limit => 5,                :null => false
    t.string   "siret",                                    :null => false
    t.text     "comment"
    t.integer  "company_id",                               :null => false
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0, :null => false
  end

  add_index "eky_establishments", ["created_at"], :name => "index_eky_establishments_on_created_at"
  add_index "eky_establishments", ["creator_id"], :name => "index_eky_establishments_on_creator_id"
  add_index "eky_establishments", ["name", "company_id"], :name => "index_eky_establishments_on_name_and_company_id", :unique => true
  add_index "eky_establishments", ["siret", "company_id"], :name => "index_eky_establishments_on_siret_and_company_id", :unique => true
  add_index "eky_establishments", ["updated_at"], :name => "index_eky_establishments_on_updated_at"
  add_index "eky_establishments", ["updater_id"], :name => "index_eky_establishments_on_updater_id"

  create_table "eky_event_natures", :force => true do |t|
    t.string   "name",                                         :null => false
    t.integer  "duration"
    t.integer  "company_id",                                   :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,    :null => false
    t.string   "usage",        :limit => 16
    t.boolean  "active",                     :default => true, :null => false
  end

  add_index "eky_event_natures", ["company_id"], :name => "index_eky_event_natures_on_company_id"
  add_index "eky_event_natures", ["created_at"], :name => "index_eky_event_natures_on_created_at"
  add_index "eky_event_natures", ["creator_id"], :name => "index_eky_event_natures_on_creator_id"
  add_index "eky_event_natures", ["name"], :name => "index_eky_event_natures_on_name"
  add_index "eky_event_natures", ["updated_at"], :name => "index_eky_event_natures_on_updated_at"
  add_index "eky_event_natures", ["updater_id"], :name => "index_eky_event_natures_on_updater_id"

  create_table "eky_events", :force => true do |t|
    t.string   "location"
    t.integer  "duration"
    t.datetime "started_at",                    :null => false
    t.integer  "started_sec",                   :null => false
    t.text     "reason"
    t.integer  "entity_id",                     :null => false
    t.integer  "nature_id",                     :null => false
    t.integer  "responsible_id",                :null => false
    t.integer  "company_id",                    :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   :default => 0, :null => false
  end

  add_index "eky_events", ["company_id"], :name => "index_eky_events_on_company_id"
  add_index "eky_events", ["created_at"], :name => "index_eky_events_on_created_at"
  add_index "eky_events", ["creator_id"], :name => "index_eky_events_on_creator_id"
  add_index "eky_events", ["entity_id"], :name => "index_eky_events_on_entity_id"
  add_index "eky_events", ["nature_id"], :name => "index_eky_events_on_nature_id"
  add_index "eky_events", ["responsible_id"], :name => "index_eky_events_on_employee_id"
  add_index "eky_events", ["updated_at"], :name => "index_eky_events_on_updated_at"
  add_index "eky_events", ["updater_id"], :name => "index_eky_events_on_updater_id"

  create_table "eky_financial_years", :force => true do |t|
    t.string   "code",         :limit => 12,                    :null => false
    t.boolean  "closed",                     :default => false, :null => false
    t.date     "started_on",                                    :null => false
    t.date     "stopped_on",                                    :null => false
    t.integer  "company_id",                                    :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,     :null => false
  end

  add_index "eky_financial_years", ["code", "company_id"], :name => "index_eky_financialyears_on_code_and_company_id", :unique => true
  add_index "eky_financial_years", ["company_id"], :name => "index_eky_financialyears_on_company_id"
  add_index "eky_financial_years", ["created_at"], :name => "index_eky_financialyears_on_created_at"
  add_index "eky_financial_years", ["creator_id"], :name => "index_eky_financialyears_on_creator_id"
  add_index "eky_financial_years", ["updated_at"], :name => "index_eky_financialyears_on_updated_at"
  add_index "eky_financial_years", ["updater_id"], :name => "index_eky_financialyears_on_updater_id"

  create_table "eky_inventories", :force => true do |t|
    t.date     "created_on",                                     :null => false
    t.text     "comment"
    t.boolean  "changes_reflected"
    t.integer  "company_id",                                     :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                    :default => 0, :null => false
    t.integer  "responsible_id"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.string   "number",            :limit => 16
  end

  add_index "eky_inventories", ["created_at"], :name => "index_eky_inventories_on_created_at"
  add_index "eky_inventories", ["creator_id"], :name => "index_eky_inventories_on_creator_id"
  add_index "eky_inventories", ["updated_at"], :name => "index_eky_inventories_on_updated_at"
  add_index "eky_inventories", ["updater_id"], :name => "index_eky_inventories_on_updater_id"

  create_table "eky_inventory_lines", :force => true do |t|
    t.integer  "product_id",                                                     :null => false
    t.integer  "warehouse_id",                                                   :null => false
    t.decimal  "theoric_quantity", :precision => 16, :scale => 4,                :null => false
    t.decimal  "quantity",         :precision => 16, :scale => 4,                :null => false
    t.integer  "inventory_id",                                                   :null => false
    t.integer  "company_id",                                                     :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0, :null => false
    t.integer  "tracking_id"
    t.integer  "unit_id"
  end

  add_index "eky_inventory_lines", ["created_at"], :name => "index_eky_inventory_lines_on_created_at"
  add_index "eky_inventory_lines", ["creator_id"], :name => "index_eky_inventory_lines_on_creator_id"
  add_index "eky_inventory_lines", ["updated_at"], :name => "index_eky_inventory_lines_on_updated_at"
  add_index "eky_inventory_lines", ["updater_id"], :name => "index_eky_inventory_lines_on_updater_id"

  create_table "eky_invoice_lines", :force => true do |t|
    t.integer  "order_line_id"
    t.integer  "product_id",                                                        :null => false
    t.integer  "price_id",                                                          :null => false
    t.decimal  "quantity",          :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.decimal  "amount",            :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount_with_taxes", :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "position"
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,   :null => false
    t.integer  "invoice_id"
    t.integer  "origin_id"
    t.text     "annotation"
    t.integer  "entity_id"
    t.integer  "unit_id"
    t.integer  "tracking_id"
    t.integer  "warehouse_id"
  end

  add_index "eky_invoice_lines", ["company_id"], :name => "index_eky_invoice_lines_on_company_id"
  add_index "eky_invoice_lines", ["created_at"], :name => "index_eky_invoice_lines_on_created_at"
  add_index "eky_invoice_lines", ["creator_id"], :name => "index_eky_invoice_lines_on_creator_id"
  add_index "eky_invoice_lines", ["updated_at"], :name => "index_eky_invoice_lines_on_updated_at"
  add_index "eky_invoice_lines", ["updater_id"], :name => "index_eky_invoice_lines_on_updater_id"

  create_table "eky_invoices", :force => true do |t|
    t.integer  "client_id",                                                                          :null => false
    t.string   "nature",             :limit => 1,                                                    :null => false
    t.string   "number",             :limit => 64,                                                   :null => false
    t.decimal  "amount",                           :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "amount_with_taxes",                :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "payment_delay_id",                                                                   :null => false
    t.date     "payment_on",                                                                         :null => false
    t.boolean  "paid",                                                            :default => false, :null => false
    t.boolean  "lost",                                                            :default => false, :null => false
    t.boolean  "has_downpayment",                                                 :default => false, :null => false
    t.decimal  "downpayment_amount",               :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "contact_id"
    t.integer  "company_id",                                                                         :null => false
    t.datetime "created_at",                                                                         :null => false
    t.datetime "updated_at",                                                                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                    :default => 0,     :null => false
    t.integer  "sale_order_id"
    t.integer  "origin_id"
    t.boolean  "credit",                                                          :default => false, :null => false
    t.date     "created_on"
    t.text     "annotation"
    t.integer  "currency_id"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
  end

  add_index "eky_invoices", ["accounted_at"], :name => "index_eky_invoices_on_accounted_at"
  add_index "eky_invoices", ["company_id"], :name => "index_eky_invoices_on_company_id"
  add_index "eky_invoices", ["created_at"], :name => "index_eky_invoices_on_created_at"
  add_index "eky_invoices", ["creator_id"], :name => "index_eky_invoices_on_creator_id"
  add_index "eky_invoices", ["updated_at"], :name => "index_eky_invoices_on_updated_at"
  add_index "eky_invoices", ["updater_id"], :name => "index_eky_invoices_on_updater_id"

  create_table "eky_journal_entries", :force => true do |t|
    t.integer  "resource_id"
    t.string   "resource_type"
    t.date     "created_on",                                                        :null => false
    t.date     "printed_on",                                                        :null => false
    t.string   "number",                                                            :null => false
    t.decimal  "debit",           :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "credit",          :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "position"
    t.integer  "journal_id",                                                        :null => false
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                   :default => 0,     :null => false
    t.boolean  "closed",                                         :default => false
    t.decimal  "currency_debit",  :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "currency_credit", :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "currency_rate",   :precision => 16, :scale => 6, :default => 0.0,   :null => false
    t.integer  "currency_id",                                    :default => 0,     :null => false
    t.boolean  "draft_mode",                                     :default => false, :null => false
    t.boolean  "draft",                                          :default => false, :null => false
  end

  add_index "eky_journal_entries", ["company_id"], :name => "index_eky_journal_records_on_company_id"
  add_index "eky_journal_entries", ["created_at"], :name => "index_eky_journal_records_on_created_at"
  add_index "eky_journal_entries", ["created_on", "company_id"], :name => "index_eky_journal_records_on_created_on_and_company_id"
  add_index "eky_journal_entries", ["creator_id"], :name => "index_eky_journal_records_on_creator_id"
  add_index "eky_journal_entries", ["journal_id"], :name => "index_eky_journal_records_on_journal_id"
  add_index "eky_journal_entries", ["printed_on", "company_id"], :name => "index_eky_journal_records_on_printed_on_and_company_id"
  add_index "eky_journal_entries", ["updated_at"], :name => "index_eky_journal_records_on_updated_at"
  add_index "eky_journal_entries", ["updater_id"], :name => "index_eky_journal_records_on_updater_id"

  create_table "eky_journal_entry_lines", :force => true do |t|
    t.integer  "entry_id",                                                                         :null => false
    t.integer  "account_id",                                                                       :null => false
    t.string   "name",                                                                             :null => false
    t.decimal  "currency_debit",                 :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "currency_credit",                :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "debit",                          :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "credit",                         :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "bank_statement_id"
    t.string   "letter",            :limit => 8
    t.date     "expired_on"
    t.integer  "position"
    t.text     "comment"
    t.integer  "company_id",                                                                       :null => false
    t.datetime "created_at",                                                                       :null => false
    t.datetime "updated_at",                                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                  :default => 0,     :null => false
    t.boolean  "draft",                                                         :default => false, :null => false
    t.integer  "journal_id"
    t.boolean  "closed",                                                        :default => false, :null => false
  end

  add_index "eky_journal_entry_lines", ["account_id"], :name => "index_eky_entries_on_account_id"
  add_index "eky_journal_entry_lines", ["bank_statement_id"], :name => "index_eky_entries_on_statement_id"
  add_index "eky_journal_entry_lines", ["company_id"], :name => "index_eky_entries_on_company_id"
  add_index "eky_journal_entry_lines", ["created_at"], :name => "index_eky_entries_on_created_at"
  add_index "eky_journal_entry_lines", ["creator_id"], :name => "index_eky_entries_on_creator_id"
  add_index "eky_journal_entry_lines", ["entry_id"], :name => "index_eky_entries_on_record_id"
  add_index "eky_journal_entry_lines", ["letter"], :name => "index_eky_entries_on_letter"
  add_index "eky_journal_entry_lines", ["name"], :name => "index_eky_entries_on_name"
  add_index "eky_journal_entry_lines", ["updated_at"], :name => "index_eky_entries_on_updated_at"
  add_index "eky_journal_entry_lines", ["updater_id"], :name => "index_eky_entries_on_updater_id"

  create_table "eky_journals", :force => true do |t|
    t.string   "nature",         :limit => 16,                           :null => false
    t.string   "name",                                                   :null => false
    t.string   "code",           :limit => 4,                            :null => false
    t.integer  "currency_id",                                            :null => false
    t.integer  "counterpart_id"
    t.date     "closed_on",                    :default => '1970-12-31', :null => false
    t.integer  "company_id",                                             :null => false
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                 :default => 0,            :null => false
  end

  add_index "eky_journals", ["code", "company_id"], :name => "index_eky_journals_on_code_and_company_id", :unique => true
  add_index "eky_journals", ["company_id"], :name => "index_eky_journals_on_company_id"
  add_index "eky_journals", ["created_at"], :name => "index_eky_journals_on_created_at"
  add_index "eky_journals", ["creator_id"], :name => "index_eky_journals_on_creator_id"
  add_index "eky_journals", ["currency_id"], :name => "index_eky_journals_on_currency_id"
  add_index "eky_journals", ["name", "company_id"], :name => "index_eky_journals_on_name_and_company_id", :unique => true
  add_index "eky_journals", ["updated_at"], :name => "index_eky_journals_on_updated_at"
  add_index "eky_journals", ["updater_id"], :name => "index_eky_journals_on_updater_id"

  create_table "eky_land_parcels", :force => true do |t|
    t.string   "name",                                                          :null => false
    t.string   "polygon",                                                       :null => false
    t.boolean  "master",                                      :default => true, :null => false
    t.text     "description"
    t.integer  "parent_id"
    t.integer  "company_id",                                                    :null => false
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0,    :null => false
    t.string   "number"
    t.decimal  "area_measure", :precision => 16, :scale => 4, :default => 0.0,  :null => false
    t.integer  "area_unit_id"
  end

  add_index "eky_land_parcels", ["created_at"], :name => "index_eky_shapes_on_created_at"
  add_index "eky_land_parcels", ["creator_id"], :name => "index_eky_shapes_on_creator_id"
  add_index "eky_land_parcels", ["updated_at"], :name => "index_eky_shapes_on_updated_at"
  add_index "eky_land_parcels", ["updater_id"], :name => "index_eky_shapes_on_updater_id"

  create_table "eky_listing_node_items", :force => true do |t|
    t.integer  "node_id",                                  :null => false
    t.string   "nature",       :limit => 8,                :null => false
    t.text     "value"
    t.integer  "company_id",                               :null => false
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0, :null => false
  end

  add_index "eky_listing_node_items", ["company_id"], :name => "index_eky_listing_node_items_on_company_id"
  add_index "eky_listing_node_items", ["created_at"], :name => "index_eky_listing_node_items_on_created_at"
  add_index "eky_listing_node_items", ["creator_id"], :name => "index_eky_listing_node_items_on_creator_id"
  add_index "eky_listing_node_items", ["node_id"], :name => "index_eky_listing_node_items_on_node_id"
  add_index "eky_listing_node_items", ["updated_at"], :name => "index_eky_listing_node_items_on_updated_at"
  add_index "eky_listing_node_items", ["updater_id"], :name => "index_eky_listing_node_items_on_updater_id"

  create_table "eky_listing_nodes", :force => true do |t|
    t.string   "name",                                                :null => false
    t.string   "label",                                               :null => false
    t.string   "nature",                                              :null => false
    t.integer  "position"
    t.boolean  "exportable",                        :default => true, :null => false
    t.integer  "parent_id"
    t.string   "item_nature",          :limit => 8
    t.text     "item_value"
    t.integer  "item_listing_id"
    t.integer  "item_listing_node_id"
    t.integer  "listing_id",                                          :null => false
    t.integer  "company_id",                                          :null => false
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                      :default => 0,    :null => false
    t.string   "key"
    t.string   "sql_type"
    t.string   "condition_value"
    t.string   "condition_operator"
    t.string   "attribute_name"
  end

  add_index "eky_listing_nodes", ["company_id"], :name => "index_eky_listing_nodes_on_company_id"
  add_index "eky_listing_nodes", ["created_at"], :name => "index_eky_listing_nodes_on_created_at"
  add_index "eky_listing_nodes", ["creator_id"], :name => "index_eky_listing_nodes_on_creator_id"
  add_index "eky_listing_nodes", ["exportable"], :name => "index_eky_listing_nodes_on_exportable"
  add_index "eky_listing_nodes", ["item_listing_id"], :name => "index_eky_listing_nodes_on_item_listing_id"
  add_index "eky_listing_nodes", ["item_listing_node_id"], :name => "index_eky_listing_nodes_on_item_listing_node_id"
  add_index "eky_listing_nodes", ["listing_id"], :name => "index_eky_listing_nodes_on_listing_id"
  add_index "eky_listing_nodes", ["name"], :name => "index_eky_listing_nodes_on_name"
  add_index "eky_listing_nodes", ["nature"], :name => "index_eky_listing_nodes_on_nature"
  add_index "eky_listing_nodes", ["parent_id"], :name => "index_eky_listing_nodes_on_parent_id"
  add_index "eky_listing_nodes", ["updated_at"], :name => "index_eky_listing_nodes_on_updated_at"
  add_index "eky_listing_nodes", ["updater_id"], :name => "index_eky_listing_nodes_on_updater_id"

  create_table "eky_listings", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "root_model",                  :null => false
    t.text     "query"
    t.text     "comment"
    t.text     "story"
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
    t.text     "conditions"
    t.text     "mail"
    t.text     "source"
  end

  add_index "eky_listings", ["company_id"], :name => "index_eky_listings_on_company_id"
  add_index "eky_listings", ["created_at"], :name => "index_eky_listings_on_created_at"
  add_index "eky_listings", ["creator_id"], :name => "index_eky_listings_on_creator_id"
  add_index "eky_listings", ["name"], :name => "index_eky_listings_on_name"
  add_index "eky_listings", ["root_model"], :name => "index_eky_listings_on_root_model"
  add_index "eky_listings", ["updated_at"], :name => "index_eky_listings_on_updated_at"
  add_index "eky_listings", ["updater_id"], :name => "index_eky_listings_on_updater_id"

  create_table "eky_mandates", :force => true do |t|
    t.date     "started_on"
    t.date     "stopped_on"
    t.string   "family",                      :null => false
    t.string   "organization",                :null => false
    t.string   "title",                       :null => false
    t.integer  "entity_id",                   :null => false
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "eky_mandates", ["created_at"], :name => "index_eky_mandates_on_created_at"
  add_index "eky_mandates", ["creator_id"], :name => "index_eky_mandates_on_creator_id"
  add_index "eky_mandates", ["family", "company_id"], :name => "index_eky_mandates_on_family_and_company_id"
  add_index "eky_mandates", ["organization", "company_id"], :name => "index_eky_mandates_on_organization_and_company_id"
  add_index "eky_mandates", ["title", "company_id"], :name => "index_eky_mandates_on_title_and_company_id"
  add_index "eky_mandates", ["updated_at"], :name => "index_eky_mandates_on_updated_at"
  add_index "eky_mandates", ["updater_id"], :name => "index_eky_mandates_on_updater_id"

  create_table "eky_observations", :force => true do |t|
    t.string   "importance",   :limit => 10,                :null => false
    t.text     "description",                               :null => false
    t.integer  "entity_id",                                 :null => false
    t.integer  "company_id",                                :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0, :null => false
  end

  add_index "eky_observations", ["created_at"], :name => "index_eky_observations_on_created_at"
  add_index "eky_observations", ["creator_id"], :name => "index_eky_observations_on_creator_id"
  add_index "eky_observations", ["updated_at"], :name => "index_eky_observations_on_updated_at"
  add_index "eky_observations", ["updater_id"], :name => "index_eky_observations_on_updater_id"

  create_table "eky_operation_lines", :force => true do |t|
    t.integer  "operation_id",                                                                  :null => false
    t.integer  "product_id"
    t.decimal  "unit_quantity",                :precision => 16, :scale => 4, :default => 0.0,  :null => false
    t.decimal  "quantity",                     :precision => 16, :scale => 4, :default => 0.0,  :null => false
    t.integer  "unit_id"
    t.integer  "area_unit_id"
    t.integer  "tracking_id"
    t.integer  "company_id",                                                                    :null => false
    t.datetime "created_at",                                                                    :null => false
    t.datetime "updated_at",                                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                :default => 0,    :null => false
    t.integer  "warehouse_id"
    t.string   "direction",       :limit => 4,                                :default => "in", :null => false
    t.string   "tracking_serial"
  end

  add_index "eky_operation_lines", ["created_at"], :name => "index_eky_shape_operation_lines_on_created_at"
  add_index "eky_operation_lines", ["creator_id"], :name => "index_eky_shape_operation_lines_on_creator_id"
  add_index "eky_operation_lines", ["updated_at"], :name => "index_eky_shape_operation_lines_on_updated_at"
  add_index "eky_operation_lines", ["updater_id"], :name => "index_eky_shape_operation_lines_on_updater_id"

  create_table "eky_operation_natures", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "description"
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
    t.string   "target_type"
  end

  add_index "eky_operation_natures", ["created_at"], :name => "index_eky_shape_operation_natures_on_created_at"
  add_index "eky_operation_natures", ["creator_id"], :name => "index_eky_shape_operation_natures_on_creator_id"
  add_index "eky_operation_natures", ["updated_at"], :name => "index_eky_shape_operation_natures_on_updated_at"
  add_index "eky_operation_natures", ["updater_id"], :name => "index_eky_shape_operation_natures_on_updater_id"

  create_table "eky_operations", :force => true do |t|
    t.string   "name",                                                         :null => false
    t.text     "description"
    t.integer  "responsible_id",                                               :null => false
    t.integer  "nature_id"
    t.date     "planned_on",                                                   :null => false
    t.date     "moved_on"
    t.datetime "started_at",                                                   :null => false
    t.datetime "stopped_at"
    t.integer  "company_id",                                                   :null => false
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                  :default => 0, :null => false
    t.decimal  "hour_duration",  :precision => 16, :scale => 4
    t.decimal  "min_duration",   :precision => 16, :scale => 4
    t.decimal  "duration",       :precision => 16, :scale => 4
    t.decimal  "consumption",    :precision => 16, :scale => 4
    t.string   "tools_list"
    t.string   "target_type"
    t.integer  "target_id"
  end

  add_index "eky_operations", ["created_at"], :name => "index_eky_shape_operations_on_created_at"
  add_index "eky_operations", ["creator_id"], :name => "index_eky_shape_operations_on_creator_id"
  add_index "eky_operations", ["updated_at"], :name => "index_eky_shape_operations_on_updated_at"
  add_index "eky_operations", ["updater_id"], :name => "index_eky_shape_operations_on_updater_id"

  create_table "eky_preferences", :force => true do |t|
    t.string   "name",                                                                           :null => false
    t.string   "nature",            :limit => 8,                                :default => "u", :null => false
    t.text     "string_value"
    t.boolean  "boolean_value"
    t.integer  "integer_value"
    t.decimal  "decimal_value",                  :precision => 16, :scale => 4
    t.integer  "user_id"
    t.integer  "company_id",                                                                     :null => false
    t.datetime "created_at",                                                                     :null => false
    t.datetime "updated_at",                                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                  :default => 0,   :null => false
    t.integer  "record_value_id"
    t.string   "record_value_type"
  end

  add_index "eky_preferences", ["company_id", "user_id", "name"], :name => "index_eky_parameters_on_company_id_and_user_id_and_name", :unique => true
  add_index "eky_preferences", ["company_id"], :name => "index_eky_parameters_on_company_id"
  add_index "eky_preferences", ["created_at"], :name => "index_eky_parameters_on_created_at"
  add_index "eky_preferences", ["creator_id"], :name => "index_eky_parameters_on_creator_id"
  add_index "eky_preferences", ["name"], :name => "index_eky_parameters_on_name"
  add_index "eky_preferences", ["nature"], :name => "index_eky_parameters_on_nature"
  add_index "eky_preferences", ["updated_at"], :name => "index_eky_parameters_on_updated_at"
  add_index "eky_preferences", ["updater_id"], :name => "index_eky_parameters_on_updater_id"
  add_index "eky_preferences", ["user_id"], :name => "index_eky_parameters_on_user_id"

  create_table "eky_prices", :force => true do |t|
    t.decimal  "amount",            :precision => 16, :scale => 4,                    :null => false
    t.decimal  "amount_with_taxes", :precision => 16, :scale => 4,                    :null => false
    t.boolean  "use_range",                                        :default => false, :null => false
    t.decimal  "quantity_min",      :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "quantity_max",      :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.integer  "product_id",                                                          :null => false
    t.integer  "tax_id",                                                              :null => false
    t.integer  "company_id",                                                          :null => false
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,     :null => false
    t.integer  "entity_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.boolean  "active",                                           :default => true,  :null => false
    t.integer  "currency_id"
    t.boolean  "by_default",                                       :default => true
    t.integer  "category_id"
  end

  add_index "eky_prices", ["company_id"], :name => "index_eky_prices_on_company_id"
  add_index "eky_prices", ["created_at"], :name => "index_eky_prices_on_created_at"
  add_index "eky_prices", ["creator_id"], :name => "index_eky_prices_on_creator_id"
  add_index "eky_prices", ["product_id"], :name => "index_eky_prices_on_product_id"
  add_index "eky_prices", ["updated_at"], :name => "index_eky_prices_on_updated_at"
  add_index "eky_prices", ["updater_id"], :name => "index_eky_prices_on_updater_id"

  create_table "eky_product_categories", :force => true do |t|
    t.string   "name",                                   :null => false
    t.string   "catalog_name",                           :null => false
    t.text     "catalog_description"
    t.text     "comment"
    t.integer  "parent_id"
    t.integer  "company_id",                             :null => false
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",        :default => 0,     :null => false
    t.boolean  "published",           :default => false, :null => false
  end

  add_index "eky_product_categories", ["company_id"], :name => "index_eky_shelves_on_company_id"
  add_index "eky_product_categories", ["created_at"], :name => "index_eky_shelves_on_created_at"
  add_index "eky_product_categories", ["creator_id"], :name => "index_eky_shelves_on_creator_id"
  add_index "eky_product_categories", ["name", "company_id"], :name => "index_eky_shelves_on_name_and_company_id", :unique => true
  add_index "eky_product_categories", ["parent_id"], :name => "index_eky_shelves_on_parent_id"
  add_index "eky_product_categories", ["updated_at"], :name => "index_eky_shelves_on_updated_at"
  add_index "eky_product_categories", ["updater_id"], :name => "index_eky_shelves_on_updater_id"

  create_table "eky_product_components", :force => true do |t|
    t.string   "name",                                                       :null => false
    t.integer  "product_id",                                                 :null => false
    t.integer  "component_id",                                               :null => false
    t.integer  "warehouse_id",                                               :null => false
    t.decimal  "quantity",     :precision => 16, :scale => 4,                :null => false
    t.text     "comment"
    t.boolean  "active",                                                     :null => false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.integer  "company_id",                                                 :null => false
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0, :null => false
  end

  add_index "eky_product_components", ["created_at"], :name => "index_eky_product_components_on_created_at"
  add_index "eky_product_components", ["creator_id"], :name => "index_eky_product_components_on_creator_id"
  add_index "eky_product_components", ["updated_at"], :name => "index_eky_product_components_on_updated_at"
  add_index "eky_product_components", ["updater_id"], :name => "index_eky_product_components_on_updater_id"

  create_table "eky_products", :force => true do |t|
    t.boolean  "for_purchases",                                                           :default => false, :null => false
    t.boolean  "for_sales",                                                               :default => true,  :null => false
    t.string   "nature",                     :limit => 8,                                                    :null => false
    t.string   "name",                                                                                       :null => false
    t.integer  "number",                                                                                     :null => false
    t.boolean  "active",                                                                  :default => true,  :null => false
    t.string   "code",                       :limit => 16
    t.string   "code2",                      :limit => 64
    t.string   "ean13",                      :limit => 13
    t.string   "catalog_name",                                                                               :null => false
    t.text     "catalog_description"
    t.text     "description"
    t.text     "comment"
    t.decimal  "service_coeff",                            :precision => 16, :scale => 4
    t.integer  "category_id",                                                                                :null => false
    t.integer  "unit_id",                                                                                    :null => false
    t.integer  "company_id",                                                                                 :null => false
    t.datetime "created_at",                                                                                 :null => false
    t.datetime "updated_at",                                                                                 :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                            :default => 0,     :null => false
    t.decimal  "weight",                                   :precision => 16, :scale => 3
    t.decimal  "price",                                    :precision => 16, :scale => 2, :default => 0.0
    t.decimal  "quantity_min",                             :precision => 16, :scale => 4, :default => 0.0
    t.decimal  "critic_quantity_min",                      :precision => 16, :scale => 4, :default => 1.0
    t.decimal  "quantity_max",                             :precision => 16, :scale => 4, :default => 0.0
    t.boolean  "manage_stocks",                                                           :default => false, :null => false
    t.integer  "sales_account_id"
    t.integer  "purchases_account_id"
    t.integer  "subscription_quantity"
    t.string   "subscription_period"
    t.integer  "subscription_nature_id"
    t.boolean  "reduction_submissive",                                                    :default => false, :null => false
    t.boolean  "unquantifiable",                                                          :default => false, :null => false
    t.boolean  "for_productions",                                                         :default => false, :null => false
    t.boolean  "for_immobilizations",                                                     :default => false, :null => false
    t.integer  "immobilizations_account_id"
    t.boolean  "published",                                                               :default => false, :null => false
    t.boolean  "with_tracking",                                                           :default => false, :null => false
  end

  add_index "eky_products", ["category_id"], :name => "index_eky_products_on_shelf_id"
  add_index "eky_products", ["code", "company_id"], :name => "index_eky_products_on_code_and_company_id", :unique => true
  add_index "eky_products", ["company_id"], :name => "index_eky_products_on_company_id"
  add_index "eky_products", ["created_at"], :name => "index_eky_products_on_created_at"
  add_index "eky_products", ["creator_id"], :name => "index_eky_products_on_creator_id"
  add_index "eky_products", ["name", "company_id"], :name => "index_eky_products_on_name_and_company_id", :unique => true
  add_index "eky_products", ["unit_id"], :name => "index_eky_products_on_unit_id"
  add_index "eky_products", ["updated_at"], :name => "index_eky_products_on_updated_at"
  add_index "eky_products", ["updater_id"], :name => "index_eky_products_on_updater_id"

  create_table "eky_professions", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "code"
    t.string   "rome"
    t.boolean  "commercial"
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "eky_professions", ["created_at"], :name => "index_eky_professions_on_created_at"
  add_index "eky_professions", ["creator_id"], :name => "index_eky_professions_on_creator_id"
  add_index "eky_professions", ["updated_at"], :name => "index_eky_professions_on_updated_at"
  add_index "eky_professions", ["updater_id"], :name => "index_eky_professions_on_updater_id"

  create_table "eky_purchase_deliveries", :force => true do |t|
    t.integer  "order_id",                                                          :null => false
    t.decimal  "amount",            :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount_with_taxes", :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "currency_id"
    t.text     "comment"
    t.integer  "contact_id"
    t.date     "planned_on"
    t.date     "moved_on"
    t.decimal  "weight",            :precision => 16, :scale => 4
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,   :null => false
  end

  add_index "eky_purchase_deliveries", ["company_id"], :name => "index_eky_purchase_deliveries_on_company_id"
  add_index "eky_purchase_deliveries", ["created_at"], :name => "index_eky_purchase_deliveries_on_created_at"
  add_index "eky_purchase_deliveries", ["creator_id"], :name => "index_eky_purchase_deliveries_on_creator_id"
  add_index "eky_purchase_deliveries", ["order_id", "company_id"], :name => "index_eky_purchase_deliveries_on_order_id_and_company_id"
  add_index "eky_purchase_deliveries", ["updated_at"], :name => "index_eky_purchase_deliveries_on_updated_at"
  add_index "eky_purchase_deliveries", ["updater_id"], :name => "index_eky_purchase_deliveries_on_updater_id"

  create_table "eky_purchase_delivery_lines", :force => true do |t|
    t.integer  "delivery_id",                                                       :null => false
    t.integer  "order_line_id",                                                     :null => false
    t.integer  "product_id",                                                        :null => false
    t.integer  "price_id",                                                          :null => false
    t.decimal  "quantity",          :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.integer  "unit_id",                                                           :null => false
    t.decimal  "amount",            :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount_with_taxes", :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "tracking_id"
    t.integer  "warehouse_id"
    t.decimal  "weight",            :precision => 16, :scale => 4
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,   :null => false
  end

  add_index "eky_purchase_delivery_lines", ["company_id"], :name => "index_eky_purchase_delivery_lines_on_company_id"
  add_index "eky_purchase_delivery_lines", ["created_at"], :name => "index_eky_purchase_delivery_lines_on_created_at"
  add_index "eky_purchase_delivery_lines", ["creator_id"], :name => "index_eky_purchase_delivery_lines_on_creator_id"
  add_index "eky_purchase_delivery_lines", ["delivery_id", "company_id"], :name => "index_eky_purchase_delivery_lines_on_delivery_id_and_company_id"
  add_index "eky_purchase_delivery_lines", ["tracking_id", "company_id"], :name => "index_eky_purchase_delivery_lines_on_tracking_id_and_company_id"
  add_index "eky_purchase_delivery_lines", ["updated_at"], :name => "index_eky_purchase_delivery_lines_on_updated_at"
  add_index "eky_purchase_delivery_lines", ["updater_id"], :name => "index_eky_purchase_delivery_lines_on_updater_id"

  create_table "eky_purchase_delivery_modes", :force => true do |t|
    t.string   "name",                                     :null => false
    t.string   "code",         :limit => 8,                :null => false
    t.text     "comment"
    t.integer  "company_id",                               :null => false
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0, :null => false
  end

  add_index "eky_purchase_delivery_modes", ["company_id"], :name => "index_eky_purchase_delivery_modes_on_company_id"
  add_index "eky_purchase_delivery_modes", ["created_at"], :name => "index_eky_purchase_delivery_modes_on_created_at"
  add_index "eky_purchase_delivery_modes", ["creator_id"], :name => "index_eky_purchase_delivery_modes_on_creator_id"
  add_index "eky_purchase_delivery_modes", ["updated_at"], :name => "index_eky_purchase_delivery_modes_on_updated_at"
  add_index "eky_purchase_delivery_modes", ["updater_id"], :name => "index_eky_purchase_delivery_modes_on_updater_id"

  create_table "eky_purchase_order_lines", :force => true do |t|
    t.integer  "order_id",                                                          :null => false
    t.integer  "product_id",                                                        :null => false
    t.integer  "unit_id",                                                           :null => false
    t.integer  "price_id",                                                          :null => false
    t.decimal  "quantity",          :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.decimal  "amount",            :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount_with_taxes", :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "position"
    t.integer  "account_id",                                                        :null => false
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,   :null => false
    t.integer  "warehouse_id"
    t.text     "annotation"
    t.integer  "tracking_id"
    t.string   "tracking_serial"
  end

  add_index "eky_purchase_order_lines", ["company_id"], :name => "index_eky_purchase_order_lines_on_company_id"
  add_index "eky_purchase_order_lines", ["created_at"], :name => "index_eky_purchase_order_lines_on_created_at"
  add_index "eky_purchase_order_lines", ["creator_id"], :name => "index_eky_purchase_order_lines_on_creator_id"
  add_index "eky_purchase_order_lines", ["updated_at"], :name => "index_eky_purchase_order_lines_on_updated_at"
  add_index "eky_purchase_order_lines", ["updater_id"], :name => "index_eky_purchase_order_lines_on_updater_id"

  create_table "eky_purchase_orders", :force => true do |t|
    t.integer  "supplier_id",                                                                       :null => false
    t.string   "number",            :limit => 64,                                                   :null => false
    t.boolean  "shipped",                                                        :default => false, :null => false
    t.decimal  "amount",                          :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "amount_with_taxes",               :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "dest_contact_id"
    t.text     "comment"
    t.integer  "company_id",                                                                        :null => false
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                   :default => 0,     :null => false
    t.date     "planned_on"
    t.date     "moved_on"
    t.date     "created_on"
    t.datetime "accounted_at"
    t.integer  "currency_id"
    t.decimal  "parts_amount",                    :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "journal_entry_id"
    t.string   "reference_number"
  end

  add_index "eky_purchase_orders", ["accounted_at"], :name => "index_eky_purchase_orders_on_accounted_at"
  add_index "eky_purchase_orders", ["company_id"], :name => "index_eky_purchase_orders_on_company_id"
  add_index "eky_purchase_orders", ["created_at"], :name => "index_eky_purchase_orders_on_created_at"
  add_index "eky_purchase_orders", ["creator_id"], :name => "index_eky_purchase_orders_on_creator_id"
  add_index "eky_purchase_orders", ["updated_at"], :name => "index_eky_purchase_orders_on_updated_at"
  add_index "eky_purchase_orders", ["updater_id"], :name => "index_eky_purchase_orders_on_updater_id"

  create_table "eky_purchase_payment_modes", :force => true do |t|
    t.string   "name",            :limit => 50,                    :null => false
    t.boolean  "with_accounting",               :default => false, :null => false
    t.integer  "cash_id"
    t.integer  "company_id",                                       :null => false
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                  :default => 0,     :null => false
  end

  add_index "eky_purchase_payment_modes", ["created_at"], :name => "index_eky_purchase_payment_modes_on_created_at"
  add_index "eky_purchase_payment_modes", ["creator_id"], :name => "index_eky_purchase_payment_modes_on_creator_id"
  add_index "eky_purchase_payment_modes", ["updated_at"], :name => "index_eky_purchase_payment_modes_on_updated_at"
  add_index "eky_purchase_payment_modes", ["updater_id"], :name => "index_eky_purchase_payment_modes_on_updater_id"

  create_table "eky_purchase_payment_parts", :force => true do |t|
    t.datetime "accounted_at"
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.boolean  "downpayment",                                     :default => false, :null => false
    t.integer  "expense_id",                                                         :null => false
    t.integer  "payment_id",                                                         :null => false
    t.integer  "journal_entry_id"
    t.integer  "company_id",                                                         :null => false
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,     :null => false
  end

  add_index "eky_purchase_payment_parts", ["created_at"], :name => "index_eky_purchase_payment_parts_on_created_at"
  add_index "eky_purchase_payment_parts", ["creator_id"], :name => "index_eky_purchase_payment_parts_on_creator_id"
  add_index "eky_purchase_payment_parts", ["updated_at"], :name => "index_eky_purchase_payment_parts_on_updated_at"
  add_index "eky_purchase_payment_parts", ["updater_id"], :name => "index_eky_purchase_payment_parts_on_updater_id"

  create_table "eky_purchase_payments", :force => true do |t|
    t.datetime "accounted_at"
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0,  :null => false
    t.string   "check_number"
    t.boolean  "delivered",                                       :default => true, :null => false
    t.date     "created_on"
    t.integer  "journal_entry_id"
    t.integer  "responsible_id",                                                    :null => false
    t.integer  "payee_id",                                                          :null => false
    t.integer  "mode_id",                                                           :null => false
    t.string   "number"
    t.date     "paid_on"
    t.decimal  "parts_amount",     :precision => 16, :scale => 2, :default => 0.0,  :null => false
    t.date     "to_bank_on",                                                        :null => false
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,    :null => false
  end

  add_index "eky_purchase_payments", ["created_at"], :name => "index_eky_purchase_payments_on_created_at"
  add_index "eky_purchase_payments", ["creator_id"], :name => "index_eky_purchase_payments_on_creator_id"
  add_index "eky_purchase_payments", ["updated_at"], :name => "index_eky_purchase_payments_on_updated_at"
  add_index "eky_purchase_payments", ["updater_id"], :name => "index_eky_purchase_payments_on_updater_id"

  create_table "eky_roles", :force => true do |t|
    t.string   "name",                        :null => false
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
    t.text     "rights"
  end

  add_index "eky_roles", ["company_id", "name"], :name => "index_eky_roles_on_company_id_and_name", :unique => true
  add_index "eky_roles", ["company_id"], :name => "index_eky_roles_on_company_id"
  add_index "eky_roles", ["created_at"], :name => "index_eky_roles_on_created_at"
  add_index "eky_roles", ["creator_id"], :name => "index_eky_roles_on_creator_id"
  add_index "eky_roles", ["name"], :name => "index_eky_roles_on_name"
  add_index "eky_roles", ["updated_at"], :name => "index_eky_roles_on_updated_at"
  add_index "eky_roles", ["updater_id"], :name => "index_eky_roles_on_updater_id"

  create_table "eky_sale_deliveries", :force => true do |t|
    t.integer  "order_id",                                                          :null => false
    t.integer  "invoice_id"
    t.decimal  "amount",            :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount_with_taxes", :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.text     "comment"
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,   :null => false
    t.integer  "contact_id"
    t.date     "planned_on"
    t.date     "moved_on"
    t.integer  "mode_id"
    t.integer  "currency_id"
    t.decimal  "weight",            :precision => 16, :scale => 4
    t.integer  "transport_id"
    t.integer  "transporter_id"
  end

  add_index "eky_sale_deliveries", ["company_id"], :name => "index_eky_deliveries_on_company_id"
  add_index "eky_sale_deliveries", ["created_at"], :name => "index_eky_deliveries_on_created_at"
  add_index "eky_sale_deliveries", ["creator_id"], :name => "index_eky_deliveries_on_creator_id"
  add_index "eky_sale_deliveries", ["updated_at"], :name => "index_eky_deliveries_on_updated_at"
  add_index "eky_sale_deliveries", ["updater_id"], :name => "index_eky_deliveries_on_updater_id"

  create_table "eky_sale_delivery_lines", :force => true do |t|
    t.integer  "delivery_id",                                                       :null => false
    t.integer  "order_line_id",                                                     :null => false
    t.integer  "product_id",                                                        :null => false
    t.integer  "price_id",                                                          :null => false
    t.decimal  "quantity",          :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.integer  "unit_id",                                                           :null => false
    t.decimal  "amount",            :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount_with_taxes", :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,   :null => false
    t.integer  "tracking_id"
    t.integer  "warehouse_id"
  end

  add_index "eky_sale_delivery_lines", ["company_id"], :name => "index_eky_delivery_lines_on_company_id"
  add_index "eky_sale_delivery_lines", ["created_at"], :name => "index_eky_delivery_lines_on_created_at"
  add_index "eky_sale_delivery_lines", ["creator_id"], :name => "index_eky_delivery_lines_on_creator_id"
  add_index "eky_sale_delivery_lines", ["updated_at"], :name => "index_eky_delivery_lines_on_updated_at"
  add_index "eky_sale_delivery_lines", ["updater_id"], :name => "index_eky_delivery_lines_on_updater_id"

  create_table "eky_sale_delivery_modes", :force => true do |t|
    t.string   "name",                                     :null => false
    t.string   "code",         :limit => 8,                :null => false
    t.text     "comment"
    t.integer  "company_id",                               :null => false
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0, :null => false
  end

  add_index "eky_sale_delivery_modes", ["created_at"], :name => "index_eky_delivery_modes_on_created_at"
  add_index "eky_sale_delivery_modes", ["creator_id"], :name => "index_eky_delivery_modes_on_creator_id"
  add_index "eky_sale_delivery_modes", ["updated_at"], :name => "index_eky_delivery_modes_on_updated_at"
  add_index "eky_sale_delivery_modes", ["updater_id"], :name => "index_eky_delivery_modes_on_updater_id"

  create_table "eky_sale_order_lines", :force => true do |t|
    t.integer  "order_id",                                                              :null => false
    t.integer  "product_id",                                                            :null => false
    t.integer  "price_id",                                                              :null => false
    t.boolean  "invoiced",                                           :default => false, :null => false
    t.decimal  "quantity",            :precision => 16, :scale => 4, :default => 1.0,   :null => false
    t.integer  "unit_id",                                                               :null => false
    t.decimal  "amount",              :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "amount_with_taxes",   :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "position"
    t.integer  "account_id",                                                            :null => false
    t.integer  "company_id",                                                            :null => false
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                       :default => 0,     :null => false
    t.integer  "warehouse_id"
    t.decimal  "price_amount",        :precision => 16, :scale => 2
    t.integer  "tax_id"
    t.text     "annotation"
    t.integer  "entity_id"
    t.integer  "reduction_origin_id"
    t.text     "label"
    t.integer  "tracking_id"
    t.decimal  "reduction_percent",   :precision => 16, :scale => 2, :default => 0.0,   :null => false
  end

  add_index "eky_sale_order_lines", ["company_id"], :name => "index_eky_sale_order_lines_on_company_id"
  add_index "eky_sale_order_lines", ["created_at"], :name => "index_eky_sale_order_lines_on_created_at"
  add_index "eky_sale_order_lines", ["creator_id"], :name => "index_eky_sale_order_lines_on_creator_id"
  add_index "eky_sale_order_lines", ["reduction_origin_id"], :name => "index_eky_sale_order_lines_on_reduction_origin_id"
  add_index "eky_sale_order_lines", ["updated_at"], :name => "index_eky_sale_order_lines_on_updated_at"
  add_index "eky_sale_order_lines", ["updater_id"], :name => "index_eky_sale_order_lines_on_updater_id"

  create_table "eky_sale_order_natures", :force => true do |t|
    t.string   "name",                                                                      :null => false
    t.integer  "expiration_id",                                                             :null => false
    t.boolean  "active",                                                 :default => true,  :null => false
    t.integer  "payment_delay_id",                                                          :null => false
    t.boolean  "downpayment",                                            :default => false, :null => false
    t.decimal  "downpayment_minimum",     :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "downpayment_rate",        :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.text     "comment"
    t.integer  "company_id",                                                                :null => false
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                           :default => 0,     :null => false
    t.integer  "payment_mode_id"
    t.text     "payment_mode_complement"
  end

  add_index "eky_sale_order_natures", ["company_id"], :name => "index_eky_sale_order_natures_on_company_id"
  add_index "eky_sale_order_natures", ["created_at"], :name => "index_eky_sale_order_natures_on_created_at"
  add_index "eky_sale_order_natures", ["creator_id"], :name => "index_eky_sale_order_natures_on_creator_id"
  add_index "eky_sale_order_natures", ["updated_at"], :name => "index_eky_sale_order_natures_on_updated_at"
  add_index "eky_sale_order_natures", ["updater_id"], :name => "index_eky_sale_order_natures_on_updater_id"

  create_table "eky_sale_orders", :force => true do |t|
    t.integer  "client_id",                                                                           :null => false
    t.integer  "nature_id",                                                                           :null => false
    t.date     "created_on",                                                                          :null => false
    t.string   "number",              :limit => 64,                                                   :null => false
    t.string   "sum_method",          :limit => 8,                                 :default => "wt",  :null => false
    t.boolean  "invoiced",                                                         :default => false, :null => false
    t.decimal  "amount",                            :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "amount_with_taxes",                 :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.string   "state",               :limit => 1,                                 :default => "O",   :null => false
    t.integer  "expiration_id",                                                                       :null => false
    t.date     "expired_on",                                                                          :null => false
    t.integer  "payment_delay_id",                                                                    :null => false
    t.boolean  "has_downpayment",                                                  :default => false, :null => false
    t.decimal  "downpayment_amount",                :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "contact_id"
    t.integer  "invoice_contact_id"
    t.integer  "delivery_contact_id"
    t.string   "subject"
    t.string   "function_title"
    t.text     "introduction"
    t.text     "conclusion"
    t.text     "comment"
    t.integer  "company_id",                                                                          :null => false
    t.datetime "created_at",                                                                          :null => false
    t.datetime "updated_at",                                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                     :default => 0,     :null => false
    t.date     "confirmed_on"
    t.decimal  "parts_amount",                      :precision => 16, :scale => 2
    t.integer  "responsible_id"
    t.boolean  "letter_format",                                                    :default => true,  :null => false
    t.text     "annotation"
    t.integer  "currency_id"
    t.integer  "transporter_id"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
  end

  add_index "eky_sale_orders", ["accounted_at"], :name => "index_eky_sale_orders_on_accounted_at"
  add_index "eky_sale_orders", ["company_id"], :name => "index_eky_sale_orders_on_company_id"
  add_index "eky_sale_orders", ["created_at"], :name => "index_eky_sale_orders_on_created_at"
  add_index "eky_sale_orders", ["creator_id"], :name => "index_eky_sale_orders_on_creator_id"
  add_index "eky_sale_orders", ["updated_at"], :name => "index_eky_sale_orders_on_updated_at"
  add_index "eky_sale_orders", ["updater_id"], :name => "index_eky_sale_orders_on_updater_id"

  create_table "eky_sale_payment_modes", :force => true do |t|
    t.string   "name",                    :limit => 50,                                                   :null => false
    t.integer  "depositables_account_id"
    t.integer  "company_id",                                                                              :null => false
    t.datetime "created_at",                                                                              :null => false
    t.datetime "updated_at",                                                                              :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                         :default => 0,     :null => false
    t.integer  "cash_id"
    t.boolean  "published",                                                            :default => false
    t.boolean  "with_accounting",                                                      :default => false, :null => false
    t.boolean  "with_deposit",                                                         :default => false, :null => false
    t.boolean  "with_commission",                                                      :default => false, :null => false
    t.decimal  "commission_percent",                    :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "commission_amount",                     :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "commission_account_id"
  end

  add_index "eky_sale_payment_modes", ["company_id"], :name => "index_eky_payment_modes_on_company_id"
  add_index "eky_sale_payment_modes", ["created_at"], :name => "index_eky_payment_modes_on_created_at"
  add_index "eky_sale_payment_modes", ["creator_id"], :name => "index_eky_payment_modes_on_creator_id"
  add_index "eky_sale_payment_modes", ["updated_at"], :name => "index_eky_payment_modes_on_updated_at"
  add_index "eky_sale_payment_modes", ["updater_id"], :name => "index_eky_payment_modes_on_updater_id"

  create_table "eky_sale_payment_parts", :force => true do |t|
    t.decimal  "amount",           :precision => 16, :scale => 2
    t.integer  "payment_id",                                                                  :null => false
    t.integer  "company_id",                                                                  :null => false
    t.datetime "created_at",                                                                  :null => false
    t.datetime "updated_at",                                                                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,              :null => false
    t.boolean  "downpayment",                                     :default => false,          :null => false
    t.string   "expense_type",                                    :default => "UnknownModel", :null => false
    t.integer  "expense_id",                                      :default => 0,              :null => false
    t.integer  "journal_entry_id"
    t.datetime "accounted_at"
  end

  add_index "eky_sale_payment_parts", ["company_id"], :name => "index_eky_payment_parts_on_company_id"
  add_index "eky_sale_payment_parts", ["created_at"], :name => "index_eky_payment_parts_on_created_at"
  add_index "eky_sale_payment_parts", ["creator_id"], :name => "index_eky_payment_parts_on_creator_id"
  add_index "eky_sale_payment_parts", ["expense_id"], :name => "index_eky_payment_parts_on_expense_id"
  add_index "eky_sale_payment_parts", ["expense_type"], :name => "index_eky_payment_parts_on_expense_type"
  add_index "eky_sale_payment_parts", ["updated_at"], :name => "index_eky_payment_parts_on_updated_at"
  add_index "eky_sale_payment_parts", ["updater_id"], :name => "index_eky_payment_parts_on_updater_id"

  create_table "eky_sale_payments", :force => true do |t|
    t.date     "paid_on"
    t.decimal  "amount",           :precision => 16, :scale => 2,                           :null => false
    t.integer  "mode_id",                                                                   :null => false
    t.integer  "company_id",                                                                :null => false
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,            :null => false
    t.string   "bank"
    t.string   "check_number"
    t.string   "account_number"
    t.integer  "payer_id"
    t.date     "to_bank_on",                                      :default => '2010-09-22', :null => false
    t.integer  "deposit_id"
    t.integer  "responsible_id"
    t.boolean  "scheduled",                                       :default => false,        :null => false
    t.boolean  "received",                                        :default => true,         :null => false
    t.decimal  "parts_amount",     :precision => 16, :scale => 2,                           :null => false
    t.string   "number"
    t.date     "created_on"
    t.datetime "accounted_at"
    t.text     "receipt"
    t.integer  "journal_entry_id"
  end

  add_index "eky_sale_payments", ["accounted_at"], :name => "index_eky_payments_on_accounted_at"
  add_index "eky_sale_payments", ["company_id"], :name => "index_eky_payments_on_company_id"
  add_index "eky_sale_payments", ["created_at"], :name => "index_eky_payments_on_created_at"
  add_index "eky_sale_payments", ["creator_id"], :name => "index_eky_payments_on_creator_id"
  add_index "eky_sale_payments", ["updated_at"], :name => "index_eky_payments_on_updated_at"
  add_index "eky_sale_payments", ["updater_id"], :name => "index_eky_payments_on_updater_id"

  create_table "eky_schema_migrations", :id => false, :force => true do |t|
    t.string "version", :null => false
  end

  add_index "eky_schema_migrations", ["version"], :name => "eky_unique_schema_migrations", :unique => true

  create_table "eky_sequences", :force => true do |t|
    t.string   "name",                                   :null => false
    t.string   "format",                                 :null => false
    t.integer  "company_id",                             :null => false
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     :default => 0,        :null => false
    t.string   "period",           :default => "number", :null => false
    t.integer  "last_year"
    t.integer  "last_month"
    t.integer  "last_cweek"
    t.integer  "last_number"
    t.integer  "number_increment", :default => 1,        :null => false
    t.integer  "number_start",     :default => 1,        :null => false
  end

  add_index "eky_sequences", ["company_id"], :name => "index_eky_sequences_on_company_id"
  add_index "eky_sequences", ["created_at"], :name => "index_eky_sequences_on_created_at"
  add_index "eky_sequences", ["creator_id"], :name => "index_eky_sequences_on_creator_id"
  add_index "eky_sequences", ["updated_at"], :name => "index_eky_sequences_on_updated_at"
  add_index "eky_sequences", ["updater_id"], :name => "index_eky_sequences_on_updater_id"

  create_table "eky_sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "eky_sessions", ["session_id"], :name => "index_eky_sessions_on_session_id"
  add_index "eky_sessions", ["updated_at"], :name => "index_eky_sessions_on_updated_at"

  create_table "eky_stock_moves", :force => true do |t|
    t.string   "name",                                                                  :null => false
    t.date     "planned_on",                                                            :null => false
    t.date     "moved_on"
    t.decimal  "quantity",            :precision => 16, :scale => 4,                    :null => false
    t.text     "comment"
    t.integer  "second_move_id"
    t.integer  "second_warehouse_id"
    t.integer  "tracking_id"
    t.integer  "warehouse_id",                                                          :null => false
    t.integer  "unit_id",                                                               :null => false
    t.integer  "product_id",                                                            :null => false
    t.integer  "company_id",                                                            :null => false
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                       :default => 0,     :null => false
    t.boolean  "virtual"
    t.boolean  "generated",                                          :default => false
    t.string   "origin_type"
    t.integer  "origin_id"
    t.integer  "stock_id"
  end

  add_index "eky_stock_moves", ["company_id"], :name => "index_eky_stock_moves_on_company_id"
  add_index "eky_stock_moves", ["created_at"], :name => "index_eky_stock_moves_on_created_at"
  add_index "eky_stock_moves", ["creator_id"], :name => "index_eky_stock_moves_on_creator_id"
  add_index "eky_stock_moves", ["updated_at"], :name => "index_eky_stock_moves_on_updated_at"
  add_index "eky_stock_moves", ["updater_id"], :name => "index_eky_stock_moves_on_updater_id"

  create_table "eky_stock_transfers", :force => true do |t|
    t.string   "nature",              :limit => 8,                                               :null => false
    t.integer  "product_id",                                                                     :null => false
    t.decimal  "quantity",                         :precision => 16, :scale => 4,                :null => false
    t.integer  "warehouse_id",                                                                   :null => false
    t.integer  "second_warehouse_id"
    t.date     "planned_on",                                                                     :null => false
    t.date     "moved_on"
    t.text     "comment"
    t.integer  "company_id",                                                                     :null => false
    t.datetime "created_at",                                                                     :null => false
    t.datetime "updated_at",                                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                    :default => 0, :null => false
    t.integer  "tracking_id"
    t.integer  "unit_id"
  end

  add_index "eky_stock_transfers", ["created_at"], :name => "index_eky_stock_transfers_on_created_at"
  add_index "eky_stock_transfers", ["creator_id"], :name => "index_eky_stock_transfers_on_creator_id"
  add_index "eky_stock_transfers", ["updated_at"], :name => "index_eky_stock_transfers_on_updated_at"
  add_index "eky_stock_transfers", ["updater_id"], :name => "index_eky_stock_transfers_on_updater_id"

  create_table "eky_stocks", :force => true do |t|
    t.integer  "product_id",                                                          :null => false
    t.integer  "warehouse_id",                                                        :null => false
    t.decimal  "quantity",            :precision => 16, :scale => 4, :default => 0.0, :null => false
    t.decimal  "virtual_quantity",    :precision => 16, :scale => 4, :default => 0.0, :null => false
    t.decimal  "quantity_min",        :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.decimal  "critic_quantity_min", :precision => 16, :scale => 4, :default => 0.0, :null => false
    t.decimal  "quantity_max",        :precision => 16, :scale => 4, :default => 0.0, :null => false
    t.integer  "company_id",                                                          :null => false
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                       :default => 0,   :null => false
    t.integer  "origin_id"
    t.string   "origin_type"
    t.integer  "tracking_id"
    t.string   "name"
    t.integer  "unit_id"
  end

  add_index "eky_stocks", ["company_id"], :name => "index_eky_product_stocks_on_company_id"
  add_index "eky_stocks", ["created_at"], :name => "index_eky_product_stocks_on_created_at"
  add_index "eky_stocks", ["creator_id"], :name => "index_eky_product_stocks_on_creator_id"
  add_index "eky_stocks", ["updated_at"], :name => "index_eky_product_stocks_on_updated_at"
  add_index "eky_stocks", ["updater_id"], :name => "index_eky_product_stocks_on_updater_id"

  create_table "eky_subscription_natures", :force => true do |t|
    t.string   "name",                                                                            :null => false
    t.integer  "actual_number"
    t.string   "nature",                :limit => 8,                                              :null => false
    t.text     "comment"
    t.integer  "company_id",                                                                      :null => false
    t.datetime "created_at",                                                                      :null => false
    t.datetime "updated_at",                                                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                     :default => 0, :null => false
    t.decimal  "reduction_rate",                     :precision => 8, :scale => 2
    t.integer  "entity_link_nature_id"
  end

  add_index "eky_subscription_natures", ["created_at"], :name => "index_eky_subscription_natures_on_created_at"
  add_index "eky_subscription_natures", ["creator_id"], :name => "index_eky_subscription_natures_on_creator_id"
  add_index "eky_subscription_natures", ["entity_link_nature_id"], :name => "index_eky_subscription_natures_on_entity_link_nature_id"
  add_index "eky_subscription_natures", ["updated_at"], :name => "index_eky_subscription_natures_on_updated_at"
  add_index "eky_subscription_natures", ["updater_id"], :name => "index_eky_subscription_natures_on_updater_id"

  create_table "eky_subscriptions", :force => true do |t|
    t.date     "started_on"
    t.date     "stopped_on"
    t.integer  "first_number"
    t.integer  "last_number"
    t.integer  "sale_order_id"
    t.integer  "product_id"
    t.integer  "contact_id"
    t.integer  "company_id",                                                           :null => false
    t.datetime "created_at",                                                           :null => false
    t.datetime "updated_at",                                                           :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                      :default => 0,     :null => false
    t.decimal  "quantity",           :precision => 16, :scale => 4
    t.boolean  "suspended",                                         :default => false, :null => false
    t.integer  "nature_id"
    t.integer  "invoice_id"
    t.integer  "entity_id"
    t.text     "comment"
    t.string   "number"
    t.integer  "sale_order_line_id"
  end

  add_index "eky_subscriptions", ["created_at"], :name => "index_eky_subscriptions_on_created_at"
  add_index "eky_subscriptions", ["creator_id"], :name => "index_eky_subscriptions_on_creator_id"
  add_index "eky_subscriptions", ["updated_at"], :name => "index_eky_subscriptions_on_updated_at"
  add_index "eky_subscriptions", ["updater_id"], :name => "index_eky_subscriptions_on_updater_id"

  create_table "eky_tax_declarations", :force => true do |t|
    t.string   "nature",                                                  :default => "normal", :null => false
    t.string   "address"
    t.date     "declared_on"
    t.date     "paid_on"
    t.decimal  "collected_amount",         :precision => 16, :scale => 2
    t.decimal  "paid_amount",              :precision => 16, :scale => 2
    t.decimal  "balance_amount",           :precision => 16, :scale => 2
    t.boolean  "deferred_payment",                                        :default => false
    t.decimal  "assimilated_taxes_amount", :precision => 16, :scale => 2
    t.decimal  "acquisition_amount",       :precision => 16, :scale => 2
    t.decimal  "amount",                   :precision => 16, :scale => 2
    t.integer  "company_id",                                                                    :null => false
    t.integer  "financial_year_id"
    t.date     "started_on"
    t.date     "stopped_on"
    t.datetime "created_at",                                                                    :null => false
    t.datetime "updated_at",                                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                            :default => 0,        :null => false
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
  end

  add_index "eky_tax_declarations", ["company_id"], :name => "index_eky_tax_declarations_on_company_id"
  add_index "eky_tax_declarations", ["created_at"], :name => "index_eky_tax_declarations_on_created_at"
  add_index "eky_tax_declarations", ["creator_id"], :name => "index_eky_tax_declarations_on_creator_id"
  add_index "eky_tax_declarations", ["updated_at"], :name => "index_eky_tax_declarations_on_updated_at"
  add_index "eky_tax_declarations", ["updater_id"], :name => "index_eky_tax_declarations_on_updater_id"

  create_table "eky_taxes", :force => true do |t|
    t.string   "name",                                                                                :null => false
    t.boolean  "included",                                                         :default => false, :null => false
    t.boolean  "reductible",                                                       :default => true,  :null => false
    t.string   "nature",               :limit => 8,                                                   :null => false
    t.decimal  "amount",                            :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.text     "description"
    t.integer  "account_collected_id"
    t.integer  "account_paid_id"
    t.integer  "company_id",                                                                          :null => false
    t.datetime "created_at",                                                                          :null => false
    t.datetime "updated_at",                                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                     :default => 0,     :null => false
  end

  add_index "eky_taxes", ["account_collected_id"], :name => "index_eky_taxes_on_account_collected_id"
  add_index "eky_taxes", ["account_paid_id"], :name => "index_eky_taxes_on_account_paid_id"
  add_index "eky_taxes", ["company_id"], :name => "index_eky_taxes_on_company_id"
  add_index "eky_taxes", ["created_at"], :name => "index_eky_taxes_on_created_at"
  add_index "eky_taxes", ["creator_id"], :name => "index_eky_taxes_on_creator_id"
  add_index "eky_taxes", ["name", "company_id"], :name => "index_eky_taxes_on_name_and_company_id", :unique => true
  add_index "eky_taxes", ["nature", "company_id"], :name => "index_eky_taxes_on_nature_and_company_id"
  add_index "eky_taxes", ["updated_at"], :name => "index_eky_taxes_on_updated_at"
  add_index "eky_taxes", ["updater_id"], :name => "index_eky_taxes_on_updater_id"

  create_table "eky_tool_uses", :force => true do |t|
    t.integer  "operation_id",                :null => false
    t.integer  "tool_id",                     :null => false
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "eky_tool_uses", ["created_at"], :name => "index_eky_tool_uses_on_created_at"
  add_index "eky_tool_uses", ["creator_id"], :name => "index_eky_tool_uses_on_creator_id"
  add_index "eky_tool_uses", ["updated_at"], :name => "index_eky_tool_uses_on_updated_at"
  add_index "eky_tool_uses", ["updater_id"], :name => "index_eky_tool_uses_on_updater_id"

  create_table "eky_tools", :force => true do |t|
    t.string   "name",                                                                    :null => false
    t.string   "nature",       :limit => 8,                                               :null => false
    t.decimal  "consumption",               :precision => 16, :scale => 4
    t.integer  "company_id",                                                              :null => false
    t.datetime "created_at",                                                              :null => false
    t.datetime "updated_at",                                                              :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                             :default => 0, :null => false
  end

  add_index "eky_tools", ["created_at"], :name => "index_eky_tools_on_created_at"
  add_index "eky_tools", ["creator_id"], :name => "index_eky_tools_on_creator_id"
  add_index "eky_tools", ["updated_at"], :name => "index_eky_tools_on_updated_at"
  add_index "eky_tools", ["updater_id"], :name => "index_eky_tools_on_updater_id"

  create_table "eky_trackings", :force => true do |t|
    t.string   "name",                           :null => false
    t.string   "serial"
    t.boolean  "active",       :default => true, :null => false
    t.text     "comment"
    t.integer  "company_id",                     :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0,    :null => false
    t.integer  "product_id"
    t.integer  "producer_id"
  end

  add_index "eky_trackings", ["company_id"], :name => "index_eky_stock_trackings_on_company_id"
  add_index "eky_trackings", ["created_at"], :name => "index_eky_stock_trackings_on_created_at"
  add_index "eky_trackings", ["creator_id"], :name => "index_eky_stock_trackings_on_creator_id"
  add_index "eky_trackings", ["updated_at"], :name => "index_eky_stock_trackings_on_updated_at"
  add_index "eky_trackings", ["updater_id"], :name => "index_eky_stock_trackings_on_updater_id"

  create_table "eky_transfers", :force => true do |t|
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "parts_amount",     :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "supplier_id"
    t.string   "label"
    t.string   "comment"
    t.date     "started_on"
    t.date     "stopped_on"
    t.integer  "company_id",                                                       :null => false
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,   :null => false
    t.date     "created_on"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
  end

  add_index "eky_transfers", ["accounted_at"], :name => "index_eky_transfers_on_accounted_at"
  add_index "eky_transfers", ["company_id"], :name => "index_eky_transfers_on_company_id"
  add_index "eky_transfers", ["created_at"], :name => "index_eky_transfers_on_created_at"
  add_index "eky_transfers", ["creator_id"], :name => "index_eky_transfers_on_creator_id"
  add_index "eky_transfers", ["updated_at"], :name => "index_eky_transfers_on_updated_at"
  add_index "eky_transfers", ["updater_id"], :name => "index_eky_transfers_on_updater_id"

  create_table "eky_transports", :force => true do |t|
    t.integer  "transporter_id",                                                 :null => false
    t.integer  "responsible_id"
    t.decimal  "weight",           :precision => 16, :scale => 4
    t.date     "created_on"
    t.date     "transport_on"
    t.text     "comment"
    t.integer  "company_id",                                                     :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0, :null => false
    t.string   "number"
    t.string   "reference_number"
  end

  add_index "eky_transports", ["company_id"], :name => "index_eky_transports_on_company_id"
  add_index "eky_transports", ["created_at"], :name => "index_eky_transports_on_created_at"
  add_index "eky_transports", ["creator_id"], :name => "index_eky_transports_on_creator_id"
  add_index "eky_transports", ["updated_at"], :name => "index_eky_transports_on_updated_at"
  add_index "eky_transports", ["updater_id"], :name => "index_eky_transports_on_updater_id"

  create_table "eky_units", :force => true do |t|
    t.string   "name",         :limit => 8,                                                 :null => false
    t.string   "label",                                                                     :null => false
    t.string   "base"
    t.decimal  "coefficient",               :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.integer  "company_id",                                                                :null => false
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                             :default => 0,   :null => false
    t.decimal  "start",                     :precision => 16, :scale => 4, :default => 0.0, :null => false
  end

  add_index "eky_units", ["company_id"], :name => "index_eky_units_on_company_id"
  add_index "eky_units", ["created_at"], :name => "index_eky_units_on_created_at"
  add_index "eky_units", ["creator_id"], :name => "index_eky_units_on_creator_id"
  add_index "eky_units", ["name", "company_id"], :name => "index_eky_units_on_name_and_company_id", :unique => true
  add_index "eky_units", ["updated_at"], :name => "index_eky_units_on_updated_at"
  add_index "eky_units", ["updater_id"], :name => "index_eky_units_on_updater_id"

  create_table "eky_users", :force => true do |t|
    t.string   "name",              :limit => 32,                                                   :null => false
    t.string   "first_name",                                                                        :null => false
    t.string   "last_name",                                                                         :null => false
    t.string   "salt",              :limit => 64
    t.string   "hashed_password",   :limit => 64
    t.boolean  "locked",                                                         :default => false, :null => false
    t.string   "email"
    t.integer  "company_id",                                                                        :null => false
    t.integer  "role_id",                                                                           :null => false
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                   :default => 0,     :null => false
    t.decimal  "reduction_percent",               :precision => 16, :scale => 4, :default => 5.0,   :null => false
    t.boolean  "admin",                                                          :default => true,  :null => false
    t.text     "rights"
    t.date     "arrived_on"
    t.text     "comment"
    t.boolean  "commercial"
    t.date     "departed_on"
    t.integer  "department_id"
    t.integer  "establishment_id"
    t.string   "office"
    t.integer  "profession_id"
    t.boolean  "employed",                                                       :default => false, :null => false
    t.string   "employment"
    t.string   "language",          :limit => 3,                                 :default => "???", :null => false
    t.datetime "connected_at"
  end

  add_index "eky_users", ["company_id"], :name => "index_eky_users_on_company_id"
  add_index "eky_users", ["created_at"], :name => "index_eky_users_on_created_at"
  add_index "eky_users", ["creator_id"], :name => "index_eky_users_on_creator_id"
  add_index "eky_users", ["email"], :name => "index_eky_users_on_email"
  add_index "eky_users", ["name", "company_id"], :name => "index_eky_users_on_name_and_company_id", :unique => true
  add_index "eky_users", ["role_id"], :name => "index_eky_users_on_role_id"
  add_index "eky_users", ["updated_at"], :name => "index_eky_users_on_updated_at"
  add_index "eky_users", ["updater_id"], :name => "index_eky_users_on_updater_id"

  create_table "eky_warehouses", :force => true do |t|
    t.string   "name",                                                               :null => false
    t.string   "x"
    t.string   "y"
    t.string   "z"
    t.text     "comment"
    t.integer  "parent_id"
    t.integer  "account_id",                                                         :null => false
    t.integer  "establishment_id"
    t.integer  "contact_id"
    t.integer  "company_id",                                                         :null => false
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,     :null => false
    t.boolean  "reservoir",                                       :default => false
    t.integer  "product_id"
    t.decimal  "quantity_max",     :precision => 16, :scale => 4
    t.integer  "unit_id"
    t.integer  "number"
  end

  add_index "eky_warehouses", ["company_id"], :name => "index_eky_stock_locations_on_company_id"
  add_index "eky_warehouses", ["created_at"], :name => "index_eky_stock_locations_on_created_at"
  add_index "eky_warehouses", ["creator_id"], :name => "index_eky_stock_locations_on_creator_id"
  add_index "eky_warehouses", ["updated_at"], :name => "index_eky_stock_locations_on_updated_at"
  add_index "eky_warehouses", ["updater_id"], :name => "index_eky_stock_locations_on_updater_id"

end
