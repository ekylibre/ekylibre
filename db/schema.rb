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

ActiveRecord::Schema.define(:version => 20101123095131) do

  create_table "account_balances", :force => true do |t|
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

  add_index "account_balances", ["account_id", "financial_year_id", "company_id"], :name => "account_balances_unique", :unique => true
  add_index "account_balances", ["company_id"], :name => "index_account_balances_on_company_id"
  add_index "account_balances", ["created_at"], :name => "index_account_balances_on_created_at"
  add_index "account_balances", ["creator_id"], :name => "index_account_balances_on_creator_id"
  add_index "account_balances", ["financial_year_id"], :name => "index_account_balances_on_financialyear_id"
  add_index "account_balances", ["updated_at"], :name => "index_account_balances_on_updated_at"
  add_index "account_balances", ["updater_id"], :name => "index_account_balances_on_updater_id"

  create_table "accounts", :force => true do |t|
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
    t.boolean  "reconcilable",                :default => false, :null => false
  end

  add_index "accounts", ["company_id"], :name => "index_accounts_on_company_id"
  add_index "accounts", ["created_at"], :name => "index_accounts_on_created_at"
  add_index "accounts", ["creator_id"], :name => "index_accounts_on_creator_id"
  add_index "accounts", ["name", "company_id"], :name => "index_accounts_on_name_and_company_id"
  add_index "accounts", ["number", "company_id"], :name => "index_accounts_on_number_and_company_id", :unique => true
  add_index "accounts", ["updated_at"], :name => "index_accounts_on_updated_at"
  add_index "accounts", ["updater_id"], :name => "index_accounts_on_updater_id"

  create_table "areas", :force => true do |t|
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

  add_index "areas", ["created_at"], :name => "index_areas_on_created_at"
  add_index "areas", ["creator_id"], :name => "index_areas_on_creator_id"
  add_index "areas", ["district_id"], :name => "index_areas_on_district_id"
  add_index "areas", ["updated_at"], :name => "index_areas_on_updated_at"
  add_index "areas", ["updater_id"], :name => "index_areas_on_updater_id"

  create_table "bank_statements", :force => true do |t|
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

  add_index "bank_statements", ["cash_id"], :name => "index_bank_account_statements_on_bank_account_id"
  add_index "bank_statements", ["company_id"], :name => "index_bank_account_statements_on_company_id"
  add_index "bank_statements", ["created_at"], :name => "index_bank_account_statements_on_created_at"
  add_index "bank_statements", ["creator_id"], :name => "index_bank_account_statements_on_creator_id"
  add_index "bank_statements", ["updated_at"], :name => "index_bank_account_statements_on_updated_at"
  add_index "bank_statements", ["updater_id"], :name => "index_bank_account_statements_on_updater_id"

  create_table "cash_transfers", :force => true do |t|
    t.integer  "emitter_cash_id",                                                           :null => false
    t.integer  "receiver_cash_id",                                                          :null => false
    t.integer  "emitter_journal_entry_id"
    t.datetime "accounted_at"
    t.string   "number",                                                                    :null => false
    t.text     "comment"
    t.integer  "emitter_currency_id",                                                       :null => false
    t.decimal  "emitter_currency_rate",     :precision => 16, :scale => 6, :default => 1.0, :null => false
    t.decimal  "emitter_amount",            :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "receiver_amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "company_id",                                                                :null => false
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                             :default => 0,   :null => false
    t.integer  "receiver_journal_entry_id"
    t.integer  "receiver_currency_id"
    t.decimal  "receiver_currency_rate",    :precision => 16, :scale => 6
    t.integer  "currency_id"
    t.date     "created_on"
  end

  add_index "cash_transfers", ["company_id"], :name => "index_cash_transfers_on_company_id"
  add_index "cash_transfers", ["created_at"], :name => "index_cash_transfers_on_created_at"
  add_index "cash_transfers", ["creator_id"], :name => "index_cash_transfers_on_creator_id"
  add_index "cash_transfers", ["updated_at"], :name => "index_cash_transfers_on_updated_at"
  add_index "cash_transfers", ["updater_id"], :name => "index_cash_transfers_on_updater_id"

  create_table "cashes", :force => true do |t|
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

  add_index "cashes", ["account_id"], :name => "index_bank_accounts_on_account_id"
  add_index "cashes", ["company_id"], :name => "index_bank_accounts_on_company_id"
  add_index "cashes", ["created_at"], :name => "index_bank_accounts_on_created_at"
  add_index "cashes", ["creator_id"], :name => "index_bank_accounts_on_creator_id"
  add_index "cashes", ["currency_id"], :name => "index_bank_accounts_on_currency_id"
  add_index "cashes", ["entity_id"], :name => "index_bank_accounts_on_entity_id"
  add_index "cashes", ["journal_id"], :name => "index_bank_accounts_on_journal_id"
  add_index "cashes", ["updated_at"], :name => "index_bank_accounts_on_updated_at"
  add_index "cashes", ["updater_id"], :name => "index_bank_accounts_on_updater_id"

  create_table "companies", :force => true do |t|
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
    t.string   "language",                       :default => "eng", :null => false
  end

  add_index "companies", ["code"], :name => "index_companies_on_code", :unique => true
  add_index "companies", ["created_at"], :name => "index_companies_on_created_at"
  add_index "companies", ["creator_id"], :name => "index_companies_on_creator_id"
  add_index "companies", ["name"], :name => "index_companies_on_name"
  add_index "companies", ["updated_at"], :name => "index_companies_on_updated_at"
  add_index "companies", ["updater_id"], :name => "index_companies_on_updater_id"

  create_table "contacts", :force => true do |t|
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

  add_index "contacts", ["by_default"], :name => "index_contacts_on_default"
  add_index "contacts", ["code"], :name => "index_contacts_on_code"
  add_index "contacts", ["company_id"], :name => "index_contacts_on_company_id"
  add_index "contacts", ["created_at"], :name => "index_contacts_on_created_at"
  add_index "contacts", ["creator_id"], :name => "index_contacts_on_creator_id"
  add_index "contacts", ["deleted_at"], :name => "index_contacts_on_stopped_at"
  add_index "contacts", ["entity_id"], :name => "index_contacts_on_entity_id"
  add_index "contacts", ["updated_at"], :name => "index_contacts_on_updated_at"
  add_index "contacts", ["updater_id"], :name => "index_contacts_on_updater_id"

  create_table "cultivations", :force => true do |t|
    t.string   "name",                                            :null => false
    t.date     "started_on",                                      :null => false
    t.date     "stopped_on"
    t.string   "color",        :limit => 6, :default => "FFFFFF", :null => false
    t.text     "comment"
    t.integer  "company_id",                                      :null => false
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0,        :null => false
  end

  add_index "cultivations", ["company_id"], :name => "index_cultivations_on_company_id"
  add_index "cultivations", ["created_at"], :name => "index_cultivations_on_created_at"
  add_index "cultivations", ["creator_id"], :name => "index_cultivations_on_creator_id"
  add_index "cultivations", ["updated_at"], :name => "index_cultivations_on_updated_at"
  add_index "cultivations", ["updater_id"], :name => "index_cultivations_on_updater_id"

  create_table "currencies", :force => true do |t|
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

  add_index "currencies", ["active"], :name => "index_currencies_on_active"
  add_index "currencies", ["code", "company_id"], :name => "index_currencies_on_code_and_company_id", :unique => true
  add_index "currencies", ["company_id"], :name => "index_currencies_on_company_id"
  add_index "currencies", ["created_at"], :name => "index_currencies_on_created_at"
  add_index "currencies", ["creator_id"], :name => "index_currencies_on_creator_id"
  add_index "currencies", ["name"], :name => "index_currencies_on_name"
  add_index "currencies", ["updated_at"], :name => "index_currencies_on_updated_at"
  add_index "currencies", ["updater_id"], :name => "index_currencies_on_updater_id"

  create_table "custom_field_choices", :force => true do |t|
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

  add_index "custom_field_choices", ["company_id"], :name => "index_complement_choices_on_company_id"
  add_index "custom_field_choices", ["created_at"], :name => "index_complement_choices_on_created_at"
  add_index "custom_field_choices", ["creator_id"], :name => "index_complement_choices_on_creator_id"
  add_index "custom_field_choices", ["custom_field_id"], :name => "index_complement_choices_on_complement_id"
  add_index "custom_field_choices", ["updated_at"], :name => "index_complement_choices_on_updated_at"
  add_index "custom_field_choices", ["updater_id"], :name => "index_complement_choices_on_updater_id"

  create_table "custom_field_data", :force => true do |t|
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

  add_index "custom_field_data", ["choice_value_id"], :name => "index_complement_data_on_choice_value_id"
  add_index "custom_field_data", ["company_id", "custom_field_id", "entity_id"], :name => "index_complement_data_on_entity_id_and_complement_id", :unique => true
  add_index "custom_field_data", ["company_id"], :name => "index_complement_data_on_company_id"
  add_index "custom_field_data", ["created_at"], :name => "index_complement_data_on_created_at"
  add_index "custom_field_data", ["creator_id"], :name => "index_complement_data_on_creator_id"
  add_index "custom_field_data", ["custom_field_id"], :name => "index_complement_data_on_complement_id"
  add_index "custom_field_data", ["entity_id"], :name => "index_complement_data_on_entity_id"
  add_index "custom_field_data", ["updated_at"], :name => "index_complement_data_on_updated_at"
  add_index "custom_field_data", ["updater_id"], :name => "index_complement_data_on_updater_id"

  create_table "custom_fields", :force => true do |t|
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

  add_index "custom_fields", ["company_id", "position"], :name => "index_complements_on_company_id_and_position"
  add_index "custom_fields", ["company_id"], :name => "index_complements_on_company_id"
  add_index "custom_fields", ["created_at"], :name => "index_complements_on_created_at"
  add_index "custom_fields", ["creator_id"], :name => "index_complements_on_creator_id"
  add_index "custom_fields", ["required"], :name => "index_complements_on_required"
  add_index "custom_fields", ["updated_at"], :name => "index_complements_on_updated_at"
  add_index "custom_fields", ["updater_id"], :name => "index_complements_on_updater_id"

  create_table "delays", :force => true do |t|
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

  add_index "delays", ["created_at"], :name => "index_delays_on_created_at"
  add_index "delays", ["creator_id"], :name => "index_delays_on_creator_id"
  add_index "delays", ["name", "company_id"], :name => "index_delays_on_name_and_company_id", :unique => true
  add_index "delays", ["updated_at"], :name => "index_delays_on_updated_at"
  add_index "delays", ["updater_id"], :name => "index_delays_on_updater_id"

  create_table "departments", :force => true do |t|
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

  add_index "departments", ["created_at"], :name => "index_departments_on_created_at"
  add_index "departments", ["creator_id"], :name => "index_departments_on_creator_id"
  add_index "departments", ["name", "company_id"], :name => "index_departments_on_name_and_company_id", :unique => true
  add_index "departments", ["parent_id"], :name => "index_departments_on_parent_id"
  add_index "departments", ["updated_at"], :name => "index_departments_on_updated_at"
  add_index "departments", ["updater_id"], :name => "index_departments_on_updater_id"

  create_table "deposit_lines", :force => true do |t|
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

  add_index "deposit_lines", ["company_id"], :name => "index_deposit_lines_on_company_id"
  add_index "deposit_lines", ["created_at"], :name => "index_deposit_lines_on_created_at"
  add_index "deposit_lines", ["creator_id"], :name => "index_deposit_lines_on_creator_id"
  add_index "deposit_lines", ["deposit_id", "company_id"], :name => "index_deposit_lines_on_deposit_id_and_company_id"
  add_index "deposit_lines", ["updated_at"], :name => "index_deposit_lines_on_updated_at"
  add_index "deposit_lines", ["updater_id"], :name => "index_deposit_lines_on_updater_id"

  create_table "deposits", :force => true do |t|
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

  add_index "deposits", ["created_at"], :name => "index_embankments_on_created_at"
  add_index "deposits", ["creator_id"], :name => "index_embankments_on_creator_id"
  add_index "deposits", ["updated_at"], :name => "index_embankments_on_updated_at"
  add_index "deposits", ["updater_id"], :name => "index_embankments_on_updater_id"

  create_table "districts", :force => true do |t|
    t.string   "name",                        :null => false
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
    t.string   "code"
  end

  add_index "districts", ["created_at"], :name => "index_districts_on_created_at"
  add_index "districts", ["creator_id"], :name => "index_districts_on_creator_id"
  add_index "districts", ["updated_at"], :name => "index_districts_on_updated_at"
  add_index "districts", ["updater_id"], :name => "index_districts_on_updater_id"

  create_table "document_templates", :force => true do |t|
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
    t.string   "nature",       :limit => 64
    t.string   "filename"
    t.string   "language",     :limit => 3,  :default => "???", :null => false
  end

  add_index "document_templates", ["company_id", "active"], :name => "index_document_templates_on_company_id_and_active"
  add_index "document_templates", ["company_id", "name"], :name => "index_document_templates_on_company_id_and_name"
  add_index "document_templates", ["company_id"], :name => "index_document_templates_on_company_id"
  add_index "document_templates", ["created_at"], :name => "index_document_templates_on_created_at"
  add_index "document_templates", ["creator_id"], :name => "index_document_templates_on_creator_id"
  add_index "document_templates", ["updated_at"], :name => "index_document_templates_on_updated_at"
  add_index "document_templates", ["updater_id"], :name => "index_document_templates_on_updater_id"

  create_table "documents", :force => true do |t|
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

  add_index "documents", ["company_id"], :name => "index_documents_on_company_id"
  add_index "documents", ["created_at"], :name => "index_documents_on_created_at"
  add_index "documents", ["creator_id"], :name => "index_documents_on_creator_id"
  add_index "documents", ["owner_id"], :name => "index_documents_on_owner_id"
  add_index "documents", ["owner_type"], :name => "index_documents_on_owner_type"
  add_index "documents", ["sha256"], :name => "index_documents_on_sha256"
  add_index "documents", ["updated_at"], :name => "index_documents_on_updated_at"
  add_index "documents", ["updater_id"], :name => "index_documents_on_updater_id"

  create_table "entities", :force => true do |t|
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

  add_index "entities", ["code", "company_id"], :name => "index_entities_on_code_and_company_id", :unique => true
  add_index "entities", ["company_id"], :name => "index_entities_on_company_id"
  add_index "entities", ["created_at"], :name => "index_entities_on_created_at"
  add_index "entities", ["creator_id"], :name => "index_entities_on_creator_id"
  add_index "entities", ["full_name", "company_id"], :name => "index_entities_on_full_name_and_company_id"
  add_index "entities", ["last_name", "company_id"], :name => "index_entities_on_name_and_company_id"
  add_index "entities", ["soundex", "company_id"], :name => "index_entities_on_soundex_and_company_id"
  add_index "entities", ["updated_at"], :name => "index_entities_on_updated_at"
  add_index "entities", ["updater_id"], :name => "index_entities_on_updater_id"

  create_table "entity_categories", :force => true do |t|
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

  add_index "entity_categories", ["code", "company_id"], :name => "index_entity_categories_on_code_and_company_id", :unique => true
  add_index "entity_categories", ["created_at"], :name => "index_entity_categories_on_created_at"
  add_index "entity_categories", ["creator_id"], :name => "index_entity_categories_on_creator_id"
  add_index "entity_categories", ["updated_at"], :name => "index_entity_categories_on_updated_at"
  add_index "entity_categories", ["updater_id"], :name => "index_entity_categories_on_updater_id"

  create_table "entity_link_natures", :force => true do |t|
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

  add_index "entity_link_natures", ["company_id"], :name => "index_entity_link_natures_on_company_id"
  add_index "entity_link_natures", ["created_at"], :name => "index_entity_link_natures_on_created_at"
  add_index "entity_link_natures", ["creator_id"], :name => "index_entity_link_natures_on_creator_id"
  add_index "entity_link_natures", ["name"], :name => "index_entity_link_natures_on_name"
  add_index "entity_link_natures", ["name_1_to_2"], :name => "index_entity_link_natures_on_name_1_to_2"
  add_index "entity_link_natures", ["name_2_to_1"], :name => "index_entity_link_natures_on_name_2_to_1"
  add_index "entity_link_natures", ["updated_at"], :name => "index_entity_link_natures_on_updated_at"
  add_index "entity_link_natures", ["updater_id"], :name => "index_entity_link_natures_on_updater_id"

  create_table "entity_links", :force => true do |t|
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

  add_index "entity_links", ["company_id"], :name => "index_entity_links_on_company_id"
  add_index "entity_links", ["created_at"], :name => "index_entity_links_on_created_at"
  add_index "entity_links", ["creator_id"], :name => "index_entity_links_on_creator_id"
  add_index "entity_links", ["entity_1_id"], :name => "index_entity_links_on_entity1_id"
  add_index "entity_links", ["entity_2_id"], :name => "index_entity_links_on_entity2_id"
  add_index "entity_links", ["nature_id"], :name => "index_entity_links_on_nature_id"
  add_index "entity_links", ["updated_at"], :name => "index_entity_links_on_updated_at"
  add_index "entity_links", ["updater_id"], :name => "index_entity_links_on_updater_id"

  create_table "entity_natures", :force => true do |t|
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

  add_index "entity_natures", ["company_id"], :name => "index_entity_natures_on_company_id"
  add_index "entity_natures", ["created_at"], :name => "index_entity_natures_on_created_at"
  add_index "entity_natures", ["creator_id"], :name => "index_entity_natures_on_creator_id"
  add_index "entity_natures", ["name", "company_id"], :name => "index_entity_natures_on_name_and_company_id", :unique => true
  add_index "entity_natures", ["updated_at"], :name => "index_entity_natures_on_updated_at"
  add_index "entity_natures", ["updater_id"], :name => "index_entity_natures_on_updater_id"

  create_table "establishments", :force => true do |t|
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

  add_index "establishments", ["created_at"], :name => "index_establishments_on_created_at"
  add_index "establishments", ["creator_id"], :name => "index_establishments_on_creator_id"
  add_index "establishments", ["name", "company_id"], :name => "index_establishments_on_name_and_company_id", :unique => true
  add_index "establishments", ["siret", "company_id"], :name => "index_establishments_on_siret_and_company_id", :unique => true
  add_index "establishments", ["updated_at"], :name => "index_establishments_on_updated_at"
  add_index "establishments", ["updater_id"], :name => "index_establishments_on_updater_id"

  create_table "event_natures", :force => true do |t|
    t.string   "name",                                         :null => false
    t.integer  "duration"
    t.integer  "company_id",                                   :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,    :null => false
    t.string   "usage",        :limit => 64
    t.boolean  "active",                     :default => true, :null => false
  end

  add_index "event_natures", ["company_id"], :name => "index_event_natures_on_company_id"
  add_index "event_natures", ["created_at"], :name => "index_event_natures_on_created_at"
  add_index "event_natures", ["creator_id"], :name => "index_event_natures_on_creator_id"
  add_index "event_natures", ["name"], :name => "index_event_natures_on_name"
  add_index "event_natures", ["updated_at"], :name => "index_event_natures_on_updated_at"
  add_index "event_natures", ["updater_id"], :name => "index_event_natures_on_updater_id"

  create_table "events", :force => true do |t|
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

  add_index "events", ["company_id"], :name => "index_events_on_company_id"
  add_index "events", ["created_at"], :name => "index_events_on_created_at"
  add_index "events", ["creator_id"], :name => "index_events_on_creator_id"
  add_index "events", ["entity_id"], :name => "index_events_on_entity_id"
  add_index "events", ["nature_id"], :name => "index_events_on_nature_id"
  add_index "events", ["responsible_id"], :name => "index_events_on_employee_id"
  add_index "events", ["updated_at"], :name => "index_events_on_updated_at"
  add_index "events", ["updater_id"], :name => "index_events_on_updater_id"

  create_table "financial_years", :force => true do |t|
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

  add_index "financial_years", ["code", "company_id"], :name => "index_financialyears_on_code_and_company_id", :unique => true
  add_index "financial_years", ["company_id"], :name => "index_financialyears_on_company_id"
  add_index "financial_years", ["created_at"], :name => "index_financialyears_on_created_at"
  add_index "financial_years", ["creator_id"], :name => "index_financialyears_on_creator_id"
  add_index "financial_years", ["updated_at"], :name => "index_financialyears_on_updated_at"
  add_index "financial_years", ["updater_id"], :name => "index_financialyears_on_updater_id"

  create_table "incoming_deliveries", :force => true do |t|
    t.integer  "purchase_id"
    t.decimal  "pretax_amount",    :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "currency_id"
    t.text     "comment"
    t.integer  "contact_id"
    t.date     "planned_on"
    t.date     "moved_on"
    t.decimal  "weight",           :precision => 16, :scale => 4
    t.integer  "company_id",                                                       :null => false
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,   :null => false
    t.integer  "mode_id"
    t.string   "number"
    t.string   "reference_number"
  end

  add_index "incoming_deliveries", ["company_id"], :name => "index_purchase_deliveries_on_company_id"
  add_index "incoming_deliveries", ["created_at"], :name => "index_purchase_deliveries_on_created_at"
  add_index "incoming_deliveries", ["creator_id"], :name => "index_purchase_deliveries_on_creator_id"
  add_index "incoming_deliveries", ["purchase_id", "company_id"], :name => "index_purchase_deliveries_on_order_id_and_company_id"
  add_index "incoming_deliveries", ["updated_at"], :name => "index_purchase_deliveries_on_updated_at"
  add_index "incoming_deliveries", ["updater_id"], :name => "index_purchase_deliveries_on_updater_id"

  create_table "incoming_delivery_lines", :force => true do |t|
    t.integer  "delivery_id",                                                      :null => false
    t.integer  "purchase_line_id",                                                 :null => false
    t.integer  "product_id",                                                       :null => false
    t.integer  "price_id",                                                         :null => false
    t.decimal  "quantity",         :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.integer  "unit_id",                                                          :null => false
    t.decimal  "pretax_amount",    :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "tracking_id"
    t.integer  "warehouse_id"
    t.decimal  "weight",           :precision => 16, :scale => 4
    t.integer  "company_id",                                                       :null => false
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,   :null => false
    t.integer  "stock_move_id"
  end

  add_index "incoming_delivery_lines", ["company_id"], :name => "index_purchase_delivery_lines_on_company_id"
  add_index "incoming_delivery_lines", ["created_at"], :name => "index_purchase_delivery_lines_on_created_at"
  add_index "incoming_delivery_lines", ["creator_id"], :name => "index_purchase_delivery_lines_on_creator_id"
  add_index "incoming_delivery_lines", ["delivery_id", "company_id"], :name => "index_purchase_delivery_lines_on_delivery_id_and_company_id"
  add_index "incoming_delivery_lines", ["tracking_id", "company_id"], :name => "index_purchase_delivery_lines_on_tracking_id_and_company_id"
  add_index "incoming_delivery_lines", ["updated_at"], :name => "index_purchase_delivery_lines_on_updated_at"
  add_index "incoming_delivery_lines", ["updater_id"], :name => "index_purchase_delivery_lines_on_updater_id"
  add_index "incoming_delivery_lines", ["warehouse_id", "company_id"], :name => "index_purchase_delivery_lines_on_warehouse_id_and_company_id"

  create_table "incoming_delivery_modes", :force => true do |t|
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

  add_index "incoming_delivery_modes", ["company_id"], :name => "index_purchase_delivery_modes_on_company_id"
  add_index "incoming_delivery_modes", ["created_at"], :name => "index_purchase_delivery_modes_on_created_at"
  add_index "incoming_delivery_modes", ["creator_id"], :name => "index_purchase_delivery_modes_on_creator_id"
  add_index "incoming_delivery_modes", ["updated_at"], :name => "index_purchase_delivery_modes_on_updated_at"
  add_index "incoming_delivery_modes", ["updater_id"], :name => "index_purchase_delivery_modes_on_updater_id"

  create_table "incoming_payment_modes", :force => true do |t|
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
    t.decimal  "commission_base_amount",                :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "commission_account_id"
    t.integer  "position"
  end

  add_index "incoming_payment_modes", ["company_id"], :name => "index_payment_modes_on_company_id"
  add_index "incoming_payment_modes", ["created_at"], :name => "index_payment_modes_on_created_at"
  add_index "incoming_payment_modes", ["creator_id"], :name => "index_payment_modes_on_creator_id"
  add_index "incoming_payment_modes", ["updated_at"], :name => "index_payment_modes_on_updated_at"
  add_index "incoming_payment_modes", ["updater_id"], :name => "index_payment_modes_on_updater_id"

  create_table "incoming_payment_uses", :force => true do |t|
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

  add_index "incoming_payment_uses", ["company_id"], :name => "index_payment_parts_on_company_id"
  add_index "incoming_payment_uses", ["created_at"], :name => "index_payment_parts_on_created_at"
  add_index "incoming_payment_uses", ["creator_id"], :name => "index_payment_parts_on_creator_id"
  add_index "incoming_payment_uses", ["expense_id"], :name => "index_payment_parts_on_expense_id"
  add_index "incoming_payment_uses", ["expense_type"], :name => "index_payment_parts_on_expense_type"
  add_index "incoming_payment_uses", ["updated_at"], :name => "index_payment_parts_on_updated_at"
  add_index "incoming_payment_uses", ["updater_id"], :name => "index_payment_parts_on_updater_id"

  create_table "incoming_payments", :force => true do |t|
    t.date     "paid_on"
    t.decimal  "amount",                :precision => 16, :scale => 2,                           :null => false
    t.integer  "mode_id",                                                                        :null => false
    t.integer  "company_id",                                                                     :null => false
    t.datetime "created_at",                                                                     :null => false
    t.datetime "updated_at",                                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                         :default => 0,            :null => false
    t.string   "bank"
    t.string   "check_number"
    t.string   "account_number"
    t.integer  "payer_id"
    t.date     "to_bank_on",                                           :default => '0001-01-01', :null => false
    t.integer  "deposit_id"
    t.integer  "responsible_id"
    t.boolean  "scheduled",                                            :default => false,        :null => false
    t.boolean  "received",                                             :default => true,         :null => false
    t.decimal  "used_amount",           :precision => 16, :scale => 2,                           :null => false
    t.string   "number"
    t.date     "created_on"
    t.datetime "accounted_at"
    t.text     "receipt"
    t.integer  "journal_entry_id"
    t.integer  "commission_account_id"
    t.decimal  "commission_amount",     :precision => 16, :scale => 2, :default => 0.0,          :null => false
  end

  add_index "incoming_payments", ["accounted_at"], :name => "index_payments_on_accounted_at"
  add_index "incoming_payments", ["company_id"], :name => "index_payments_on_company_id"
  add_index "incoming_payments", ["created_at"], :name => "index_payments_on_created_at"
  add_index "incoming_payments", ["creator_id"], :name => "index_payments_on_creator_id"
  add_index "incoming_payments", ["updated_at"], :name => "index_payments_on_updated_at"
  add_index "incoming_payments", ["updater_id"], :name => "index_payments_on_updater_id"

  create_table "inventories", :force => true do |t|
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
    t.date     "moved_on"
  end

  add_index "inventories", ["created_at"], :name => "index_inventories_on_created_at"
  add_index "inventories", ["creator_id"], :name => "index_inventories_on_creator_id"
  add_index "inventories", ["updated_at"], :name => "index_inventories_on_updated_at"
  add_index "inventories", ["updater_id"], :name => "index_inventories_on_updater_id"

  create_table "inventory_lines", :force => true do |t|
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
    t.integer  "stock_move_id"
  end

  add_index "inventory_lines", ["created_at"], :name => "index_inventory_lines_on_created_at"
  add_index "inventory_lines", ["creator_id"], :name => "index_inventory_lines_on_creator_id"
  add_index "inventory_lines", ["updated_at"], :name => "index_inventory_lines_on_updated_at"
  add_index "inventory_lines", ["updater_id"], :name => "index_inventory_lines_on_updater_id"

  create_table "journal_entries", :force => true do |t|
    t.integer  "resource_id"
    t.string   "resource_type"
    t.date     "created_on",                                                                        :null => false
    t.date     "printed_on",                                                                        :null => false
    t.string   "number",                                                                            :null => false
    t.decimal  "debit",                         :precision => 16, :scale => 2, :default => 0.0,     :null => false
    t.decimal  "credit",                        :precision => 16, :scale => 2, :default => 0.0,     :null => false
    t.integer  "journal_id",                                                                        :null => false
    t.integer  "company_id",                                                                        :null => false
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                 :default => 0,       :null => false
    t.decimal  "currency_debit",                :precision => 16, :scale => 2, :default => 0.0,     :null => false
    t.decimal  "currency_credit",               :precision => 16, :scale => 2, :default => 0.0,     :null => false
    t.decimal  "currency_rate",                 :precision => 16, :scale => 6, :default => 0.0,     :null => false
    t.integer  "currency_id",                                                  :default => 0,       :null => false
    t.string   "state",           :limit => 32,                                :default => "draft", :null => false
    t.decimal  "balance",                       :precision => 16, :scale => 2, :default => 0.0,     :null => false
  end

  add_index "journal_entries", ["company_id"], :name => "index_journal_records_on_company_id"
  add_index "journal_entries", ["created_at"], :name => "index_journal_records_on_created_at"
  add_index "journal_entries", ["created_on", "company_id"], :name => "index_journal_records_on_created_on_and_company_id"
  add_index "journal_entries", ["creator_id"], :name => "index_journal_records_on_creator_id"
  add_index "journal_entries", ["journal_id"], :name => "index_journal_records_on_journal_id"
  add_index "journal_entries", ["printed_on", "company_id"], :name => "index_journal_records_on_printed_on_and_company_id"
  add_index "journal_entries", ["updated_at"], :name => "index_journal_records_on_updated_at"
  add_index "journal_entries", ["updater_id"], :name => "index_journal_records_on_updater_id"

  create_table "journal_entry_lines", :force => true do |t|
    t.integer  "entry_id",                                                                            :null => false
    t.integer  "account_id",                                                                          :null => false
    t.string   "name",                                                                                :null => false
    t.decimal  "currency_debit",                  :precision => 16, :scale => 2, :default => 0.0,     :null => false
    t.decimal  "currency_credit",                 :precision => 16, :scale => 2, :default => 0.0,     :null => false
    t.decimal  "debit",                           :precision => 16, :scale => 2, :default => 0.0,     :null => false
    t.decimal  "credit",                          :precision => 16, :scale => 2, :default => 0.0,     :null => false
    t.integer  "bank_statement_id"
    t.string   "letter",            :limit => 8
    t.integer  "position"
    t.text     "comment"
    t.integer  "company_id",                                                                          :null => false
    t.datetime "created_at",                                                                          :null => false
    t.datetime "updated_at",                                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                   :default => 0,       :null => false
    t.integer  "journal_id"
    t.string   "state",             :limit => 32,                                :default => "draft", :null => false
    t.decimal  "balance",                         :precision => 16, :scale => 2, :default => 0.0,     :null => false
  end

  add_index "journal_entry_lines", ["account_id"], :name => "index_entries_on_account_id"
  add_index "journal_entry_lines", ["bank_statement_id"], :name => "index_entries_on_statement_id"
  add_index "journal_entry_lines", ["company_id"], :name => "index_entries_on_company_id"
  add_index "journal_entry_lines", ["created_at"], :name => "index_entries_on_created_at"
  add_index "journal_entry_lines", ["creator_id"], :name => "index_entries_on_creator_id"
  add_index "journal_entry_lines", ["entry_id"], :name => "index_entries_on_record_id"
  add_index "journal_entry_lines", ["letter"], :name => "index_entries_on_letter"
  add_index "journal_entry_lines", ["name"], :name => "index_entries_on_name"
  add_index "journal_entry_lines", ["updated_at"], :name => "index_entries_on_updated_at"
  add_index "journal_entry_lines", ["updater_id"], :name => "index_entries_on_updater_id"

  create_table "journals", :force => true do |t|
    t.string   "nature",       :limit => 16,                           :null => false
    t.string   "name",                                                 :null => false
    t.string   "code",         :limit => 4,                            :null => false
    t.integer  "currency_id",                                          :null => false
    t.date     "closed_on",                  :default => '1970-12-31', :null => false
    t.integer  "company_id",                                           :null => false
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,            :null => false
  end

  add_index "journals", ["code", "company_id"], :name => "index_journals_on_code_and_company_id", :unique => true
  add_index "journals", ["company_id"], :name => "index_journals_on_company_id"
  add_index "journals", ["created_at"], :name => "index_journals_on_created_at"
  add_index "journals", ["creator_id"], :name => "index_journals_on_creator_id"
  add_index "journals", ["currency_id"], :name => "index_journals_on_currency_id"
  add_index "journals", ["name", "company_id"], :name => "index_journals_on_name_and_company_id", :unique => true
  add_index "journals", ["updated_at"], :name => "index_journals_on_updated_at"
  add_index "journals", ["updater_id"], :name => "index_journals_on_updater_id"

  create_table "land_parcel_groups", :force => true do |t|
    t.string   "name",                                            :null => false
    t.text     "comment"
    t.string   "color",        :limit => 6, :default => "000000", :null => false
    t.integer  "company_id",                                      :null => false
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0,        :null => false
  end

  add_index "land_parcel_groups", ["company_id"], :name => "index_land_parcel_groups_on_company_id"
  add_index "land_parcel_groups", ["created_at"], :name => "index_land_parcel_groups_on_created_at"
  add_index "land_parcel_groups", ["creator_id"], :name => "index_land_parcel_groups_on_creator_id"
  add_index "land_parcel_groups", ["updated_at"], :name => "index_land_parcel_groups_on_updated_at"
  add_index "land_parcel_groups", ["updater_id"], :name => "index_land_parcel_groups_on_updater_id"

  create_table "land_parcel_kinships", :force => true do |t|
    t.integer  "parent_land_parcel_id",                              :null => false
    t.integer  "child_land_parcel_id",                               :null => false
    t.string   "nature",                :limit => 16
    t.integer  "company_id",                                         :null => false
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                        :default => 0, :null => false
  end

  add_index "land_parcel_kinships", ["child_land_parcel_id", "company_id"], :name => "index_land_parcel_kinships_child"
  add_index "land_parcel_kinships", ["company_id"], :name => "index_land_parcel_kinships_on_company_id"
  add_index "land_parcel_kinships", ["created_at"], :name => "index_land_parcel_kinships_on_created_at"
  add_index "land_parcel_kinships", ["creator_id"], :name => "index_land_parcel_kinships_on_creator_id"
  add_index "land_parcel_kinships", ["parent_land_parcel_id", "company_id"], :name => "index_land_parcel_kinships_parent"
  add_index "land_parcel_kinships", ["updated_at"], :name => "index_land_parcel_kinships_on_updated_at"
  add_index "land_parcel_kinships", ["updater_id"], :name => "index_land_parcel_kinships_on_updater_id"

  create_table "land_parcels", :force => true do |t|
    t.string   "name",                                                         :null => false
    t.text     "description"
    t.integer  "company_id",                                                   :null => false
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0,   :null => false
    t.string   "number"
    t.decimal  "area_measure", :precision => 16, :scale => 4, :default => 0.0, :null => false
    t.integer  "area_unit_id"
    t.date     "started_on",                                                   :null => false
    t.date     "stopped_on"
    t.integer  "group_id",                                                     :null => false
  end

  add_index "land_parcels", ["created_at"], :name => "index_shapes_on_created_at"
  add_index "land_parcels", ["creator_id"], :name => "index_shapes_on_creator_id"
  add_index "land_parcels", ["updated_at"], :name => "index_shapes_on_updated_at"
  add_index "land_parcels", ["updater_id"], :name => "index_shapes_on_updater_id"

  create_table "listing_node_items", :force => true do |t|
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

  add_index "listing_node_items", ["company_id"], :name => "index_listing_node_items_on_company_id"
  add_index "listing_node_items", ["created_at"], :name => "index_listing_node_items_on_created_at"
  add_index "listing_node_items", ["creator_id"], :name => "index_listing_node_items_on_creator_id"
  add_index "listing_node_items", ["node_id"], :name => "index_listing_node_items_on_node_id"
  add_index "listing_node_items", ["updated_at"], :name => "index_listing_node_items_on_updated_at"
  add_index "listing_node_items", ["updater_id"], :name => "index_listing_node_items_on_updater_id"

  create_table "listing_nodes", :force => true do |t|
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

  add_index "listing_nodes", ["company_id"], :name => "index_listing_nodes_on_company_id"
  add_index "listing_nodes", ["created_at"], :name => "index_listing_nodes_on_created_at"
  add_index "listing_nodes", ["creator_id"], :name => "index_listing_nodes_on_creator_id"
  add_index "listing_nodes", ["exportable"], :name => "index_listing_nodes_on_exportable"
  add_index "listing_nodes", ["item_listing_id"], :name => "index_listing_nodes_on_item_listing_id"
  add_index "listing_nodes", ["item_listing_node_id"], :name => "index_listing_nodes_on_item_listing_node_id"
  add_index "listing_nodes", ["listing_id"], :name => "index_listing_nodes_on_listing_id"
  add_index "listing_nodes", ["name"], :name => "index_listing_nodes_on_name"
  add_index "listing_nodes", ["nature"], :name => "index_listing_nodes_on_nature"
  add_index "listing_nodes", ["parent_id"], :name => "index_listing_nodes_on_parent_id"
  add_index "listing_nodes", ["updated_at"], :name => "index_listing_nodes_on_updated_at"
  add_index "listing_nodes", ["updater_id"], :name => "index_listing_nodes_on_updater_id"

  create_table "listings", :force => true do |t|
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

  add_index "listings", ["company_id"], :name => "index_listings_on_company_id"
  add_index "listings", ["created_at"], :name => "index_listings_on_created_at"
  add_index "listings", ["creator_id"], :name => "index_listings_on_creator_id"
  add_index "listings", ["name"], :name => "index_listings_on_name"
  add_index "listings", ["root_model"], :name => "index_listings_on_root_model"
  add_index "listings", ["updated_at"], :name => "index_listings_on_updated_at"
  add_index "listings", ["updater_id"], :name => "index_listings_on_updater_id"

  create_table "mandates", :force => true do |t|
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

  add_index "mandates", ["created_at"], :name => "index_mandates_on_created_at"
  add_index "mandates", ["creator_id"], :name => "index_mandates_on_creator_id"
  add_index "mandates", ["family", "company_id"], :name => "index_mandates_on_family_and_company_id"
  add_index "mandates", ["organization", "company_id"], :name => "index_mandates_on_organization_and_company_id"
  add_index "mandates", ["title", "company_id"], :name => "index_mandates_on_title_and_company_id"
  add_index "mandates", ["updated_at"], :name => "index_mandates_on_updated_at"
  add_index "mandates", ["updater_id"], :name => "index_mandates_on_updater_id"

  create_table "observations", :force => true do |t|
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

  add_index "observations", ["created_at"], :name => "index_observations_on_created_at"
  add_index "observations", ["creator_id"], :name => "index_observations_on_creator_id"
  add_index "observations", ["updated_at"], :name => "index_observations_on_updated_at"
  add_index "observations", ["updater_id"], :name => "index_observations_on_updater_id"

  create_table "operation_lines", :force => true do |t|
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
    t.integer  "stock_move_id"
  end

  add_index "operation_lines", ["created_at"], :name => "index_shape_operation_lines_on_created_at"
  add_index "operation_lines", ["creator_id"], :name => "index_shape_operation_lines_on_creator_id"
  add_index "operation_lines", ["updated_at"], :name => "index_shape_operation_lines_on_updated_at"
  add_index "operation_lines", ["updater_id"], :name => "index_shape_operation_lines_on_updater_id"

  create_table "operation_natures", :force => true do |t|
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

  add_index "operation_natures", ["created_at"], :name => "index_shape_operation_natures_on_created_at"
  add_index "operation_natures", ["creator_id"], :name => "index_shape_operation_natures_on_creator_id"
  add_index "operation_natures", ["updated_at"], :name => "index_shape_operation_natures_on_updated_at"
  add_index "operation_natures", ["updater_id"], :name => "index_shape_operation_natures_on_updater_id"

  create_table "operation_uses", :force => true do |t|
    t.integer  "operation_id",                :null => false
    t.integer  "tool_id",                     :null => false
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "operation_uses", ["created_at"], :name => "index_tool_uses_on_created_at"
  add_index "operation_uses", ["creator_id"], :name => "index_tool_uses_on_creator_id"
  add_index "operation_uses", ["updated_at"], :name => "index_tool_uses_on_updated_at"
  add_index "operation_uses", ["updater_id"], :name => "index_tool_uses_on_updater_id"

  create_table "operations", :force => true do |t|
    t.string   "name",                                                                          :null => false
    t.text     "description"
    t.integer  "responsible_id",                                                                :null => false
    t.integer  "nature_id"
    t.date     "planned_on",                                                                    :null => false
    t.date     "moved_on"
    t.datetime "started_at",                                                                    :null => false
    t.datetime "stopped_at"
    t.integer  "company_id",                                                                    :null => false
    t.datetime "created_at",                                                                    :null => false
    t.datetime "updated_at",                                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                   :default => 0, :null => false
    t.decimal  "hour_duration",                   :precision => 16, :scale => 4
    t.decimal  "min_duration",                    :precision => 16, :scale => 4
    t.decimal  "duration",                        :precision => 16, :scale => 4
    t.decimal  "consumption",                     :precision => 16, :scale => 4
    t.string   "tools_list"
    t.string   "target_type"
    t.integer  "target_id"
    t.integer  "production_chain_work_center_id"
  end

  add_index "operations", ["created_at"], :name => "index_shape_operations_on_created_at"
  add_index "operations", ["creator_id"], :name => "index_shape_operations_on_creator_id"
  add_index "operations", ["updated_at"], :name => "index_shape_operations_on_updated_at"
  add_index "operations", ["updater_id"], :name => "index_shape_operations_on_updater_id"

  create_table "outgoing_deliveries", :force => true do |t|
    t.integer  "sale_id",                                                          :null => false
    t.decimal  "pretax_amount",    :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.text     "comment"
    t.integer  "company_id",                                                       :null => false
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,   :null => false
    t.integer  "contact_id"
    t.date     "planned_on"
    t.date     "moved_on"
    t.integer  "mode_id"
    t.integer  "currency_id"
    t.decimal  "weight",           :precision => 16, :scale => 4
    t.integer  "transport_id"
    t.integer  "transporter_id"
    t.string   "number"
    t.string   "reference_number"
  end

  add_index "outgoing_deliveries", ["company_id"], :name => "index_deliveries_on_company_id"
  add_index "outgoing_deliveries", ["created_at"], :name => "index_deliveries_on_created_at"
  add_index "outgoing_deliveries", ["creator_id"], :name => "index_deliveries_on_creator_id"
  add_index "outgoing_deliveries", ["sale_id"], :name => "index_outgoing_deliveries_on_sales_order_id"
  add_index "outgoing_deliveries", ["updated_at"], :name => "index_deliveries_on_updated_at"
  add_index "outgoing_deliveries", ["updater_id"], :name => "index_deliveries_on_updater_id"

  create_table "outgoing_delivery_lines", :force => true do |t|
    t.integer  "delivery_id",                                                   :null => false
    t.integer  "sale_line_id",                                                  :null => false
    t.integer  "product_id",                                                    :null => false
    t.integer  "price_id",                                                      :null => false
    t.decimal  "quantity",      :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.integer  "unit_id",                                                       :null => false
    t.decimal  "pretax_amount", :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",        :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "company_id",                                                    :null => false
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                 :default => 0,   :null => false
    t.integer  "tracking_id"
    t.integer  "warehouse_id"
    t.integer  "stock_move_id"
  end

  add_index "outgoing_delivery_lines", ["company_id"], :name => "index_delivery_lines_on_company_id"
  add_index "outgoing_delivery_lines", ["created_at"], :name => "index_delivery_lines_on_created_at"
  add_index "outgoing_delivery_lines", ["creator_id"], :name => "index_delivery_lines_on_creator_id"
  add_index "outgoing_delivery_lines", ["updated_at"], :name => "index_delivery_lines_on_updated_at"
  add_index "outgoing_delivery_lines", ["updater_id"], :name => "index_delivery_lines_on_updater_id"

  create_table "outgoing_delivery_modes", :force => true do |t|
    t.string   "name",                                           :null => false
    t.string   "code",           :limit => 8,                    :null => false
    t.text     "comment"
    t.integer  "company_id",                                     :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                :default => 0,     :null => false
    t.boolean  "with_transport",              :default => false, :null => false
  end

  add_index "outgoing_delivery_modes", ["created_at"], :name => "index_delivery_modes_on_created_at"
  add_index "outgoing_delivery_modes", ["creator_id"], :name => "index_delivery_modes_on_creator_id"
  add_index "outgoing_delivery_modes", ["updated_at"], :name => "index_delivery_modes_on_updated_at"
  add_index "outgoing_delivery_modes", ["updater_id"], :name => "index_delivery_modes_on_updater_id"

  create_table "outgoing_payment_modes", :force => true do |t|
    t.string   "name",            :limit => 50,                    :null => false
    t.boolean  "with_accounting",               :default => false, :null => false
    t.integer  "cash_id"
    t.integer  "company_id",                                       :null => false
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                  :default => 0,     :null => false
    t.integer  "position"
  end

  add_index "outgoing_payment_modes", ["created_at"], :name => "index_purchase_payment_modes_on_created_at"
  add_index "outgoing_payment_modes", ["creator_id"], :name => "index_purchase_payment_modes_on_creator_id"
  add_index "outgoing_payment_modes", ["updated_at"], :name => "index_purchase_payment_modes_on_updated_at"
  add_index "outgoing_payment_modes", ["updater_id"], :name => "index_purchase_payment_modes_on_updater_id"

  create_table "outgoing_payment_uses", :force => true do |t|
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

  add_index "outgoing_payment_uses", ["created_at"], :name => "index_purchase_payment_parts_on_created_at"
  add_index "outgoing_payment_uses", ["creator_id"], :name => "index_purchase_payment_parts_on_creator_id"
  add_index "outgoing_payment_uses", ["updated_at"], :name => "index_purchase_payment_parts_on_updated_at"
  add_index "outgoing_payment_uses", ["updater_id"], :name => "index_purchase_payment_parts_on_updater_id"

  create_table "outgoing_payments", :force => true do |t|
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
    t.decimal  "used_amount",      :precision => 16, :scale => 2, :default => 0.0,  :null => false
    t.date     "to_bank_on",                                                        :null => false
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,    :null => false
  end

  add_index "outgoing_payments", ["created_at"], :name => "index_purchase_payments_on_created_at"
  add_index "outgoing_payments", ["creator_id"], :name => "index_purchase_payments_on_creator_id"
  add_index "outgoing_payments", ["updated_at"], :name => "index_purchase_payments_on_updated_at"
  add_index "outgoing_payments", ["updater_id"], :name => "index_purchase_payments_on_updater_id"

  create_table "preferences", :force => true do |t|
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

  add_index "preferences", ["company_id", "user_id", "name"], :name => "index_parameters_on_company_id_and_user_id_and_name", :unique => true
  add_index "preferences", ["company_id"], :name => "index_parameters_on_company_id"
  add_index "preferences", ["created_at"], :name => "index_parameters_on_created_at"
  add_index "preferences", ["creator_id"], :name => "index_parameters_on_creator_id"
  add_index "preferences", ["name"], :name => "index_parameters_on_name"
  add_index "preferences", ["nature"], :name => "index_parameters_on_nature"
  add_index "preferences", ["updated_at"], :name => "index_parameters_on_updated_at"
  add_index "preferences", ["updater_id"], :name => "index_parameters_on_updater_id"
  add_index "preferences", ["user_id"], :name => "index_parameters_on_user_id"

  create_table "prices", :force => true do |t|
    t.decimal  "pretax_amount", :precision => 16, :scale => 4,                    :null => false
    t.decimal  "amount",        :precision => 16, :scale => 4,                    :null => false
    t.boolean  "use_range",                                    :default => false, :null => false
    t.decimal  "quantity_min",  :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "quantity_max",  :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.integer  "product_id",                                                      :null => false
    t.integer  "tax_id",                                                          :null => false
    t.integer  "company_id",                                                      :null => false
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                 :default => 0,     :null => false
    t.integer  "entity_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.boolean  "active",                                       :default => true,  :null => false
    t.integer  "currency_id"
    t.boolean  "by_default",                                   :default => true
    t.integer  "category_id"
  end

  add_index "prices", ["company_id"], :name => "index_prices_on_company_id"
  add_index "prices", ["created_at"], :name => "index_prices_on_created_at"
  add_index "prices", ["creator_id"], :name => "index_prices_on_creator_id"
  add_index "prices", ["product_id"], :name => "index_prices_on_product_id"
  add_index "prices", ["updated_at"], :name => "index_prices_on_updated_at"
  add_index "prices", ["updater_id"], :name => "index_prices_on_updater_id"

  create_table "product_categories", :force => true do |t|
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

  add_index "product_categories", ["company_id"], :name => "index_shelves_on_company_id"
  add_index "product_categories", ["created_at"], :name => "index_shelves_on_created_at"
  add_index "product_categories", ["creator_id"], :name => "index_shelves_on_creator_id"
  add_index "product_categories", ["name", "company_id"], :name => "index_shelves_on_name_and_company_id", :unique => true
  add_index "product_categories", ["parent_id"], :name => "index_shelves_on_parent_id"
  add_index "product_categories", ["updated_at"], :name => "index_shelves_on_updated_at"
  add_index "product_categories", ["updater_id"], :name => "index_shelves_on_updater_id"

  create_table "product_components", :force => true do |t|
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

  add_index "product_components", ["created_at"], :name => "index_product_components_on_created_at"
  add_index "product_components", ["creator_id"], :name => "index_product_components_on_creator_id"
  add_index "product_components", ["updated_at"], :name => "index_product_components_on_updated_at"
  add_index "product_components", ["updater_id"], :name => "index_product_components_on_updater_id"

  create_table "production_chain_conveyors", :force => true do |t|
    t.integer  "production_chain_id",                                                   :null => false
    t.integer  "product_id",                                                            :null => false
    t.integer  "unit_id",                                                               :null => false
    t.decimal  "flow",                :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.boolean  "check_state",                                        :default => false, :null => false
    t.integer  "source_id"
    t.decimal  "source_quantity",     :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.boolean  "unique_tracking",                                    :default => false, :null => false
    t.integer  "target_id"
    t.decimal  "target_quantity",     :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.text     "comment"
    t.integer  "company_id",                                                            :null => false
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                       :default => 0,     :null => false
  end

  add_index "production_chain_conveyors", ["company_id"], :name => "index_production_chain_conveyors_on_company_id"
  add_index "production_chain_conveyors", ["created_at"], :name => "index_production_chain_conveyors_on_created_at"
  add_index "production_chain_conveyors", ["creator_id"], :name => "index_production_chain_conveyors_on_creator_id"
  add_index "production_chain_conveyors", ["production_chain_id", "company_id"], :name => "index_production_chain_conveyors_chain"
  add_index "production_chain_conveyors", ["updated_at"], :name => "index_production_chain_conveyors_on_updated_at"
  add_index "production_chain_conveyors", ["updater_id"], :name => "index_production_chain_conveyors_on_updater_id"

  create_table "production_chain_work_center_uses", :force => true do |t|
    t.integer  "work_center_id",                :null => false
    t.integer  "tool_id",                       :null => false
    t.integer  "company_id",                    :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   :default => 0, :null => false
  end

  add_index "production_chain_work_center_uses", ["company_id"], :name => "index_production_chain_work_center_uses_on_company_id"
  add_index "production_chain_work_center_uses", ["created_at"], :name => "index_production_chain_work_center_uses_on_created_at"
  add_index "production_chain_work_center_uses", ["creator_id"], :name => "index_production_chain_work_center_uses_on_creator_id"
  add_index "production_chain_work_center_uses", ["updated_at"], :name => "index_production_chain_work_center_uses_on_updated_at"
  add_index "production_chain_work_center_uses", ["updater_id"], :name => "index_production_chain_work_center_uses_on_updater_id"
  add_index "production_chain_work_center_uses", ["work_center_id", "company_id"], :name => "index_production_chain_work_center_uses_work_center"

  create_table "production_chain_work_centers", :force => true do |t|
    t.integer  "production_chain_id",                :null => false
    t.integer  "operation_nature_id",                :null => false
    t.string   "name",                               :null => false
    t.string   "nature",                             :null => false
    t.integer  "building_id",                        :null => false
    t.text     "comment"
    t.integer  "position"
    t.integer  "company_id",                         :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",        :default => 0, :null => false
  end

  add_index "production_chain_work_centers", ["company_id"], :name => "index_production_chain_work_centers_on_company_id"
  add_index "production_chain_work_centers", ["created_at"], :name => "index_production_chain_work_centers_on_created_at"
  add_index "production_chain_work_centers", ["creator_id"], :name => "index_production_chain_work_centers_on_creator_id"
  add_index "production_chain_work_centers", ["operation_nature_id", "company_id"], :name => "index_production_chain_work_centers_nature"
  add_index "production_chain_work_centers", ["production_chain_id", "company_id"], :name => "index_production_chain_work_centers_chain"
  add_index "production_chain_work_centers", ["updated_at"], :name => "index_production_chain_work_centers_on_updated_at"
  add_index "production_chain_work_centers", ["updater_id"], :name => "index_production_chain_work_centers_on_updater_id"

  create_table "production_chains", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "comment"
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "production_chains", ["company_id"], :name => "index_production_chains_on_company_id"
  add_index "production_chains", ["created_at"], :name => "index_production_chains_on_created_at"
  add_index "production_chains", ["creator_id"], :name => "index_production_chains_on_creator_id"
  add_index "production_chains", ["updated_at"], :name => "index_production_chains_on_updated_at"
  add_index "production_chains", ["updater_id"], :name => "index_production_chains_on_updater_id"

  create_table "products", :force => true do |t|
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
    t.boolean  "stockable",                                                               :default => false, :null => false
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
    t.boolean  "deliverable",                                                             :default => false, :null => false
    t.boolean  "trackable",                                                               :default => false, :null => false
  end

  add_index "products", ["category_id"], :name => "index_products_on_shelf_id"
  add_index "products", ["code", "company_id"], :name => "index_products_on_code_and_company_id", :unique => true
  add_index "products", ["company_id"], :name => "index_products_on_company_id"
  add_index "products", ["created_at"], :name => "index_products_on_created_at"
  add_index "products", ["creator_id"], :name => "index_products_on_creator_id"
  add_index "products", ["name", "company_id"], :name => "index_products_on_name_and_company_id", :unique => true
  add_index "products", ["unit_id"], :name => "index_products_on_unit_id"
  add_index "products", ["updated_at"], :name => "index_products_on_updated_at"
  add_index "products", ["updater_id"], :name => "index_products_on_updater_id"

  create_table "professions", :force => true do |t|
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

  add_index "professions", ["created_at"], :name => "index_professions_on_created_at"
  add_index "professions", ["creator_id"], :name => "index_professions_on_creator_id"
  add_index "professions", ["updated_at"], :name => "index_professions_on_updated_at"
  add_index "professions", ["updater_id"], :name => "index_professions_on_updater_id"

  create_table "purchase_lines", :force => true do |t|
    t.integer  "purchase_id",                                                     :null => false
    t.integer  "product_id",                                                      :null => false
    t.integer  "unit_id",                                                         :null => false
    t.integer  "price_id",                                                        :null => false
    t.decimal  "quantity",        :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.decimal  "pretax_amount",   :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",          :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "position"
    t.integer  "account_id",                                                      :null => false
    t.integer  "company_id",                                                      :null => false
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                   :default => 0,   :null => false
    t.integer  "warehouse_id"
    t.text     "annotation"
    t.integer  "tracking_id"
    t.string   "tracking_serial"
  end

  add_index "purchase_lines", ["company_id"], :name => "index_purchase_order_lines_on_company_id"
  add_index "purchase_lines", ["created_at"], :name => "index_purchase_order_lines_on_created_at"
  add_index "purchase_lines", ["creator_id"], :name => "index_purchase_order_lines_on_creator_id"
  add_index "purchase_lines", ["updated_at"], :name => "index_purchase_order_lines_on_updated_at"
  add_index "purchase_lines", ["updater_id"], :name => "index_purchase_order_lines_on_updater_id"

  create_table "purchases", :force => true do |t|
    t.integer  "supplier_id",                                                                       :null => false
    t.string   "number",              :limit => 64,                                                 :null => false
    t.decimal  "pretax_amount",                     :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",                            :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "delivery_contact_id"
    t.text     "comment"
    t.integer  "company_id",                                                                        :null => false
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                     :default => 0,   :null => false
    t.date     "planned_on"
    t.date     "invoiced_on"
    t.date     "created_on"
    t.datetime "accounted_at"
    t.integer  "currency_id"
    t.decimal  "paid_amount",                       :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "journal_entry_id"
    t.string   "reference_number"
    t.string   "state",               :limit => 64
    t.date     "confirmed_on"
    t.integer  "responsible_id"
  end

  add_index "purchases", ["accounted_at"], :name => "index_purchase_orders_on_accounted_at"
  add_index "purchases", ["company_id"], :name => "index_purchase_orders_on_company_id"
  add_index "purchases", ["created_at"], :name => "index_purchase_orders_on_created_at"
  add_index "purchases", ["creator_id"], :name => "index_purchase_orders_on_creator_id"
  add_index "purchases", ["updated_at"], :name => "index_purchase_orders_on_updated_at"
  add_index "purchases", ["updater_id"], :name => "index_purchase_orders_on_updater_id"

  create_table "roles", :force => true do |t|
    t.string   "name",                        :null => false
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
    t.text     "rights"
  end

  add_index "roles", ["company_id", "name"], :name => "index_roles_on_company_id_and_name", :unique => true
  add_index "roles", ["company_id"], :name => "index_roles_on_company_id"
  add_index "roles", ["created_at"], :name => "index_roles_on_created_at"
  add_index "roles", ["creator_id"], :name => "index_roles_on_creator_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"
  add_index "roles", ["updated_at"], :name => "index_roles_on_updated_at"
  add_index "roles", ["updater_id"], :name => "index_roles_on_updater_id"

  create_table "sale_lines", :force => true do |t|
    t.integer  "sale_id",                                                             :null => false
    t.integer  "product_id",                                                          :null => false
    t.integer  "price_id",                                                            :null => false
    t.decimal  "quantity",            :precision => 16, :scale => 4, :default => 1.0, :null => false
    t.integer  "unit_id"
    t.decimal  "pretax_amount",       :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",              :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "position"
    t.integer  "account_id"
    t.integer  "company_id",                                                          :null => false
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                       :default => 0,   :null => false
    t.integer  "warehouse_id"
    t.decimal  "price_amount",        :precision => 16, :scale => 2
    t.integer  "tax_id"
    t.text     "annotation"
    t.integer  "entity_id"
    t.integer  "reduction_origin_id"
    t.text     "label"
    t.integer  "tracking_id"
    t.decimal  "reduction_percent",   :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "origin_id"
  end

  add_index "sale_lines", ["company_id"], :name => "index_sale_order_lines_on_company_id"
  add_index "sale_lines", ["created_at"], :name => "index_sale_order_lines_on_created_at"
  add_index "sale_lines", ["creator_id"], :name => "index_sale_order_lines_on_creator_id"
  add_index "sale_lines", ["reduction_origin_id"], :name => "index_sale_order_lines_on_reduction_origin_id"
  add_index "sale_lines", ["updated_at"], :name => "index_sale_order_lines_on_updated_at"
  add_index "sale_lines", ["updater_id"], :name => "index_sale_order_lines_on_updater_id"

  create_table "sale_natures", :force => true do |t|
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

  add_index "sale_natures", ["company_id"], :name => "index_sale_order_natures_on_company_id"
  add_index "sale_natures", ["created_at"], :name => "index_sale_order_natures_on_created_at"
  add_index "sale_natures", ["creator_id"], :name => "index_sale_order_natures_on_creator_id"
  add_index "sale_natures", ["updated_at"], :name => "index_sale_order_natures_on_updated_at"
  add_index "sale_natures", ["updater_id"], :name => "index_sale_order_natures_on_updater_id"

  create_table "sales", :force => true do |t|
    t.integer  "client_id",                                                                           :null => false
    t.integer  "nature_id"
    t.date     "created_on",                                                                          :null => false
    t.string   "number",              :limit => 64,                                                   :null => false
    t.string   "sum_method",          :limit => 8,                                 :default => "wt",  :null => false
    t.decimal  "pretax_amount",                     :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "amount",                            :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.string   "state",               :limit => 64,                                :default => "O",   :null => false
    t.integer  "expiration_id"
    t.date     "expired_on"
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
    t.decimal  "paid_amount",                       :precision => 16, :scale => 2,                    :null => false
    t.integer  "responsible_id"
    t.boolean  "letter_format",                                                    :default => true,  :null => false
    t.text     "annotation"
    t.integer  "currency_id"
    t.integer  "transporter_id"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.string   "reference_number"
    t.date     "invoiced_on"
    t.boolean  "credit",                                                           :default => false, :null => false
    t.boolean  "lost",                                                             :default => false, :null => false
    t.date     "payment_on"
    t.integer  "origin_id"
    t.string   "initial_number",      :limit => 64
  end

  add_index "sales", ["accounted_at"], :name => "index_sale_orders_on_accounted_at"
  add_index "sales", ["company_id"], :name => "index_sale_orders_on_company_id"
  add_index "sales", ["created_at"], :name => "index_sale_orders_on_created_at"
  add_index "sales", ["creator_id"], :name => "index_sale_orders_on_creator_id"
  add_index "sales", ["updated_at"], :name => "index_sale_orders_on_updated_at"
  add_index "sales", ["updater_id"], :name => "index_sale_orders_on_updater_id"

  create_table "sequences", :force => true do |t|
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

  add_index "sequences", ["company_id"], :name => "index_sequences_on_company_id"
  add_index "sequences", ["created_at"], :name => "index_sequences_on_created_at"
  add_index "sequences", ["creator_id"], :name => "index_sequences_on_creator_id"
  add_index "sequences", ["updated_at"], :name => "index_sequences_on_updated_at"
  add_index "sequences", ["updater_id"], :name => "index_sequences_on_updater_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "stock_moves", :force => true do |t|
    t.string   "name",                                                           :null => false
    t.date     "planned_on",                                                     :null => false
    t.date     "moved_on"
    t.decimal  "quantity",     :precision => 16, :scale => 4,                    :null => false
    t.text     "comment"
    t.integer  "tracking_id"
    t.integer  "warehouse_id",                                                   :null => false
    t.integer  "unit_id",                                                        :null => false
    t.integer  "product_id",                                                     :null => false
    t.integer  "company_id",                                                     :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0,     :null => false
    t.boolean  "virtual",                                                        :null => false
    t.boolean  "generated",                                   :default => false, :null => false
    t.string   "origin_type"
    t.integer  "origin_id"
    t.integer  "stock_id"
  end

  add_index "stock_moves", ["company_id"], :name => "index_stock_moves_on_company_id"
  add_index "stock_moves", ["created_at"], :name => "index_stock_moves_on_created_at"
  add_index "stock_moves", ["creator_id"], :name => "index_stock_moves_on_creator_id"
  add_index "stock_moves", ["updated_at"], :name => "index_stock_moves_on_updated_at"
  add_index "stock_moves", ["updater_id"], :name => "index_stock_moves_on_updater_id"

  create_table "stock_transfers", :force => true do |t|
    t.string   "nature",               :limit => 8,                                                :null => false
    t.integer  "product_id",                                                                       :null => false
    t.decimal  "quantity",                           :precision => 16, :scale => 4,                :null => false
    t.integer  "warehouse_id",                                                                     :null => false
    t.integer  "second_warehouse_id"
    t.date     "planned_on",                                                                       :null => false
    t.date     "moved_on"
    t.text     "comment"
    t.integer  "company_id",                                                                       :null => false
    t.datetime "created_at",                                                                       :null => false
    t.datetime "updated_at",                                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                      :default => 0, :null => false
    t.integer  "tracking_id"
    t.integer  "unit_id"
    t.integer  "stock_move_id"
    t.integer  "second_stock_move_id"
    t.string   "number",               :limit => 64,                                               :null => false
  end

  add_index "stock_transfers", ["created_at"], :name => "index_stock_transfers_on_created_at"
  add_index "stock_transfers", ["creator_id"], :name => "index_stock_transfers_on_creator_id"
  add_index "stock_transfers", ["updated_at"], :name => "index_stock_transfers_on_updated_at"
  add_index "stock_transfers", ["updater_id"], :name => "index_stock_transfers_on_updater_id"

  create_table "stocks", :force => true do |t|
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
    t.integer  "tracking_id"
    t.string   "name"
    t.integer  "unit_id"
  end

  add_index "stocks", ["company_id"], :name => "index_product_stocks_on_company_id"
  add_index "stocks", ["created_at"], :name => "index_product_stocks_on_created_at"
  add_index "stocks", ["creator_id"], :name => "index_product_stocks_on_creator_id"
  add_index "stocks", ["updated_at"], :name => "index_product_stocks_on_updated_at"
  add_index "stocks", ["updater_id"], :name => "index_product_stocks_on_updater_id"

  create_table "subscription_natures", :force => true do |t|
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

  add_index "subscription_natures", ["created_at"], :name => "index_subscription_natures_on_created_at"
  add_index "subscription_natures", ["creator_id"], :name => "index_subscription_natures_on_creator_id"
  add_index "subscription_natures", ["entity_link_nature_id"], :name => "index_subscription_natures_on_entity_link_nature_id"
  add_index "subscription_natures", ["updated_at"], :name => "index_subscription_natures_on_updated_at"
  add_index "subscription_natures", ["updater_id"], :name => "index_subscription_natures_on_updater_id"

  create_table "subscriptions", :force => true do |t|
    t.date     "started_on"
    t.date     "stopped_on"
    t.integer  "first_number"
    t.integer  "last_number"
    t.integer  "sale_id"
    t.integer  "product_id"
    t.integer  "contact_id"
    t.integer  "company_id",                                                     :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0,     :null => false
    t.decimal  "quantity",     :precision => 16, :scale => 4
    t.boolean  "suspended",                                   :default => false, :null => false
    t.integer  "nature_id"
    t.integer  "entity_id"
    t.text     "comment"
    t.string   "number"
    t.integer  "sale_line_id"
  end

  add_index "subscriptions", ["created_at"], :name => "index_subscriptions_on_created_at"
  add_index "subscriptions", ["creator_id"], :name => "index_subscriptions_on_creator_id"
  add_index "subscriptions", ["sale_id"], :name => "index_subscriptions_on_sales_order_id"
  add_index "subscriptions", ["updated_at"], :name => "index_subscriptions_on_updated_at"
  add_index "subscriptions", ["updater_id"], :name => "index_subscriptions_on_updater_id"

  create_table "tax_declarations", :force => true do |t|
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

  add_index "tax_declarations", ["company_id"], :name => "index_tax_declarations_on_company_id"
  add_index "tax_declarations", ["created_at"], :name => "index_tax_declarations_on_created_at"
  add_index "tax_declarations", ["creator_id"], :name => "index_tax_declarations_on_creator_id"
  add_index "tax_declarations", ["updated_at"], :name => "index_tax_declarations_on_updated_at"
  add_index "tax_declarations", ["updater_id"], :name => "index_tax_declarations_on_updater_id"

  create_table "taxes", :force => true do |t|
    t.string   "name",                                                                                :null => false
    t.boolean  "included",                                                         :default => false, :null => false
    t.boolean  "reductible",                                                       :default => true,  :null => false
    t.string   "nature",               :limit => 8,                                                   :null => false
    t.decimal  "amount",                            :precision => 16, :scale => 4, :default => 0.0,   :null => false
    t.text     "description"
    t.integer  "collected_account_id"
    t.integer  "paid_account_id"
    t.integer  "company_id",                                                                          :null => false
    t.datetime "created_at",                                                                          :null => false
    t.datetime "updated_at",                                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                     :default => 0,     :null => false
  end

  add_index "taxes", ["collected_account_id"], :name => "index_taxes_on_account_collected_id"
  add_index "taxes", ["company_id"], :name => "index_taxes_on_company_id"
  add_index "taxes", ["created_at"], :name => "index_taxes_on_created_at"
  add_index "taxes", ["creator_id"], :name => "index_taxes_on_creator_id"
  add_index "taxes", ["name", "company_id"], :name => "index_taxes_on_name_and_company_id", :unique => true
  add_index "taxes", ["nature", "company_id"], :name => "index_taxes_on_nature_and_company_id"
  add_index "taxes", ["paid_account_id"], :name => "index_taxes_on_account_paid_id"
  add_index "taxes", ["updated_at"], :name => "index_taxes_on_updated_at"
  add_index "taxes", ["updater_id"], :name => "index_taxes_on_updater_id"

  create_table "tools", :force => true do |t|
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

  add_index "tools", ["created_at"], :name => "index_tools_on_created_at"
  add_index "tools", ["creator_id"], :name => "index_tools_on_creator_id"
  add_index "tools", ["updated_at"], :name => "index_tools_on_updated_at"
  add_index "tools", ["updater_id"], :name => "index_tools_on_updater_id"

  create_table "tracking_states", :force => true do |t|
    t.integer  "tracking_id",                                                                :null => false
    t.integer  "responsible_id",                                                             :null => false
    t.integer  "production_chain_conveyor_id"
    t.decimal  "temperature",                  :precision => 16, :scale => 2
    t.decimal  "relative_humidity",            :precision => 16, :scale => 2
    t.decimal  "atmospheric_pressure",         :precision => 16, :scale => 2
    t.decimal  "luminance",                    :precision => 16, :scale => 2
    t.decimal  "total_weight",                 :precision => 16, :scale => 2
    t.decimal  "net_weight",                   :precision => 16, :scale => 2
    t.datetime "examinated_at",                                                              :null => false
    t.text     "comment"
    t.integer  "company_id",                                                                 :null => false
    t.datetime "created_at",                                                                 :null => false
    t.datetime "updated_at",                                                                 :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                :default => 0, :null => false
  end

  add_index "tracking_states", ["company_id"], :name => "index_tracking_states_on_company_id"
  add_index "tracking_states", ["created_at"], :name => "index_tracking_states_on_created_at"
  add_index "tracking_states", ["creator_id"], :name => "index_tracking_states_on_creator_id"
  add_index "tracking_states", ["responsible_id", "company_id"], :name => "index_tracking_states_on_responsible_id_and_company_id"
  add_index "tracking_states", ["tracking_id", "company_id"], :name => "index_tracking_states_on_tracking_id_and_company_id"
  add_index "tracking_states", ["updated_at"], :name => "index_tracking_states_on_updated_at"
  add_index "tracking_states", ["updater_id"], :name => "index_tracking_states_on_updater_id"

  create_table "trackings", :force => true do |t|
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

  add_index "trackings", ["company_id"], :name => "index_stock_trackings_on_company_id"
  add_index "trackings", ["created_at"], :name => "index_stock_trackings_on_created_at"
  add_index "trackings", ["creator_id"], :name => "index_stock_trackings_on_creator_id"
  add_index "trackings", ["updated_at"], :name => "index_stock_trackings_on_updated_at"
  add_index "trackings", ["updater_id"], :name => "index_stock_trackings_on_updater_id"

  create_table "transfers", :force => true do |t|
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "paid_amount",      :precision => 16, :scale => 2, :default => 0.0, :null => false
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

  add_index "transfers", ["accounted_at"], :name => "index_transfers_on_accounted_at"
  add_index "transfers", ["company_id"], :name => "index_transfers_on_company_id"
  add_index "transfers", ["created_at"], :name => "index_transfers_on_created_at"
  add_index "transfers", ["creator_id"], :name => "index_transfers_on_creator_id"
  add_index "transfers", ["updated_at"], :name => "index_transfers_on_updated_at"
  add_index "transfers", ["updater_id"], :name => "index_transfers_on_updater_id"

  create_table "transports", :force => true do |t|
    t.integer  "transporter_id",                                                   :null => false
    t.integer  "responsible_id"
    t.decimal  "weight",           :precision => 16, :scale => 4
    t.date     "created_on"
    t.date     "transport_on"
    t.text     "comment"
    t.integer  "company_id",                                                       :null => false
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,   :null => false
    t.string   "number"
    t.string   "reference_number"
    t.integer  "purchase_id"
    t.decimal  "pretax_amount",    :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "amount",           :precision => 16, :scale => 2, :default => 0.0, :null => false
  end

  add_index "transports", ["company_id"], :name => "index_transports_on_company_id"
  add_index "transports", ["created_at"], :name => "index_transports_on_created_at"
  add_index "transports", ["creator_id"], :name => "index_transports_on_creator_id"
  add_index "transports", ["updated_at"], :name => "index_transports_on_updated_at"
  add_index "transports", ["updater_id"], :name => "index_transports_on_updater_id"

  create_table "units", :force => true do |t|
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

  add_index "units", ["company_id"], :name => "index_units_on_company_id"
  add_index "units", ["created_at"], :name => "index_units_on_created_at"
  add_index "units", ["creator_id"], :name => "index_units_on_creator_id"
  add_index "units", ["name", "company_id"], :name => "index_units_on_name_and_company_id", :unique => true
  add_index "units", ["updated_at"], :name => "index_units_on_updated_at"
  add_index "units", ["updater_id"], :name => "index_units_on_updater_id"

  create_table "users", :force => true do |t|
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

  add_index "users", ["company_id"], :name => "index_users_on_company_id"
  add_index "users", ["created_at"], :name => "index_users_on_created_at"
  add_index "users", ["creator_id"], :name => "index_users_on_creator_id"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["name", "company_id"], :name => "index_users_on_name_and_company_id", :unique => true
  add_index "users", ["role_id"], :name => "index_users_on_role_id"
  add_index "users", ["updated_at"], :name => "index_users_on_updated_at"
  add_index "users", ["updater_id"], :name => "index_users_on_updater_id"

  create_table "warehouses", :force => true do |t|
    t.string   "name",                                                               :null => false
    t.string   "x"
    t.string   "y"
    t.string   "z"
    t.text     "comment"
    t.integer  "parent_id"
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

  add_index "warehouses", ["company_id"], :name => "index_stock_locations_on_company_id"
  add_index "warehouses", ["created_at"], :name => "index_stock_locations_on_created_at"
  add_index "warehouses", ["creator_id"], :name => "index_stock_locations_on_creator_id"
  add_index "warehouses", ["updated_at"], :name => "index_stock_locations_on_updated_at"
  add_index "warehouses", ["updater_id"], :name => "index_stock_locations_on_updater_id"

end
