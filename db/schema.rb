# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080819191919) do

  create_table "account_balances", :force => true do |t|
    t.integer  "account_id",                                                       :null => false
    t.integer  "financialyear_id",                                                 :null => false
    t.decimal  "global_debit",     :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "global_credit",    :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "global_balance",   :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "global_count",                                    :default => 0,   :null => false
    t.decimal  "local_debit",      :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "local_credit",     :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "local_balance",    :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "local_count",                                     :default => 0,   :null => false
    t.integer  "company_id",                                                       :null => false
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                                    :default => 0,   :null => false
  end

  add_index "account_balances", ["account_id", "company_id", "financialyear_id"], :name => "index_account_balances_on_account_id_and_financialyear_id_and_c", :unique => true
  add_index "account_balances", ["company_id"], :name => "index_account_balances_on_company_id"
  add_index "account_balances", ["created_at"], :name => "index_account_balances_on_created_at"
  add_index "account_balances", ["created_by"], :name => "index_account_balances_on_created_by"
  add_index "account_balances", ["financialyear_id"], :name => "index_account_balances_on_financialyear_id"
  add_index "account_balances", ["updated_at"], :name => "index_account_balances_on_updated_at"
  add_index "account_balances", ["updated_by"], :name => "index_account_balances_on_updated_by"

  create_table "accounts", :force => true do |t|
    t.string   "number",       :limit => 16,                     :null => false
    t.string   "alpha",        :limit => 16
    t.string   "name",         :limit => 208,                    :null => false
    t.string   "label",                                          :null => false
    t.boolean  "usable",                      :default => false, :null => false
    t.boolean  "groupable",                   :default => false, :null => false
    t.boolean  "keep_entries",                :default => false, :null => false
    t.boolean  "transferable",                :default => false, :null => false
    t.boolean  "letterable",                  :default => false, :null => false
    t.boolean  "pointable",                   :default => false, :null => false
    t.boolean  "is_debit",                    :default => false, :null => false
    t.string   "last_letter",  :limit => 8
    t.text     "comment"
    t.integer  "delay_id"
    t.integer  "entity_id"
    t.integer  "parent_id",                                      :null => false
    t.integer  "company_id",                                     :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                :default => 0,     :null => false
  end

  add_index "accounts", ["alpha", "company_id"], :name => "index_accounts_on_alpha_and_company_id", :unique => true
  add_index "accounts", ["company_id"], :name => "index_accounts_on_company_id"
  add_index "accounts", ["created_at"], :name => "index_accounts_on_created_at"
  add_index "accounts", ["created_by"], :name => "index_accounts_on_created_by"
  add_index "accounts", ["delay_id"], :name => "index_accounts_on_delay_id"
  add_index "accounts", ["entity_id"], :name => "index_accounts_on_entity_id"
  add_index "accounts", ["company_id", "entity_id"], :name => "index_accounts_on_entity_id_and_company_id"
  add_index "accounts", ["company_id", "label"], :name => "index_accounts_on_label_and_company_id", :unique => true
  add_index "accounts", ["company_id", "name"], :name => "index_accounts_on_name_and_company_id"
  add_index "accounts", ["company_id", "number"], :name => "index_accounts_on_number_and_company_id", :unique => true
  add_index "accounts", ["parent_id"], :name => "index_accounts_on_parent_id"
  add_index "accounts", ["updated_at"], :name => "index_accounts_on_updated_at"
  add_index "accounts", ["updated_by"], :name => "index_accounts_on_updated_by"

  create_table "actions", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "desc"
    t.integer  "parent_id",                   :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "actions", ["created_at"], :name => "index_actions_on_created_at"
  add_index "actions", ["created_by"], :name => "index_actions_on_created_by"
  add_index "actions", ["name"], :name => "index_actions_on_name", :unique => true
  add_index "actions", ["updated_at"], :name => "index_actions_on_updated_at"
  add_index "actions", ["updated_by"], :name => "index_actions_on_updated_by"

  create_table "actions_roles", :force => true do |t|
    t.integer  "action_id",                   :null => false
    t.integer  "role_id",                     :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "actions_roles", ["created_at"], :name => "index_actions_roles_on_created_at"
  add_index "actions_roles", ["created_by"], :name => "index_actions_roles_on_created_by"
  add_index "actions_roles", ["updated_at"], :name => "index_actions_roles_on_updated_at"
  add_index "actions_roles", ["updated_by"], :name => "index_actions_roles_on_updated_by"

  create_table "address_norm_items", :force => true do |t|
    t.integer  "contact_norm_id",                                      :null => false
    t.string   "name",                                                 :null => false
    t.string   "nature",          :limit => 15, :default => "content", :null => false
    t.integer  "maxlength",                     :default => 38,        :null => false
    t.string   "content"
    t.string   "left_nature",     :limit => 15
    t.string   "left_value",      :limit => 63
    t.string   "right_nature",    :limit => 15, :default => "space"
    t.string   "right_value",     :limit => 63
    t.integer  "position"
    t.integer  "company_id",                                           :null => false
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                  :default => 0,         :null => false
  end

  add_index "address_norm_items", ["company_id"], :name => "index_address_norm_items_on_company_id"
  add_index "address_norm_items", ["created_at"], :name => "index_address_norm_items_on_created_at"
  add_index "address_norm_items", ["created_by"], :name => "index_address_norm_items_on_created_by"
  add_index "address_norm_items", ["company_id", "contact_norm_id", "name"], :name => "index_address_norm_items_on_name_and_contact_norm_id_and_compan", :unique => true
  add_index "address_norm_items", ["company_id", "contact_norm_id", "nature"], :name => "index_address_norm_items_on_nature_and_contact_norm_id_and_comp", :unique => true
  add_index "address_norm_items", ["updated_at"], :name => "index_address_norm_items_on_updated_at"
  add_index "address_norm_items", ["updated_by"], :name => "index_address_norm_items_on_updated_by"

  create_table "address_norms", :force => true do |t|
    t.string   "name",                                          :null => false
    t.string   "reference"
    t.boolean  "default",                   :default => false,  :null => false
    t.boolean  "rtl",                       :default => false,  :null => false
    t.string   "align",        :limit => 8, :default => "left", :null => false
    t.integer  "company_id",                                    :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",              :default => 0,      :null => false
  end

  add_index "address_norms", ["company_id"], :name => "index_address_norms_on_company_id"
  add_index "address_norms", ["created_at"], :name => "index_address_norms_on_created_at"
  add_index "address_norms", ["created_by"], :name => "index_address_norms_on_created_by"
  add_index "address_norms", ["company_id", "name"], :name => "index_address_norms_on_name_and_company_id", :unique => true
  add_index "address_norms", ["updated_at"], :name => "index_address_norms_on_updated_at"
  add_index "address_norms", ["updated_by"], :name => "index_address_norms_on_updated_by"

  create_table "bank_account_statements", :force => true do |t|
    t.integer  "bank_account_id",                                                   :null => false
    t.date     "started_on",                                                        :null => false
    t.date     "stopped_on",                                                        :null => false
    t.date     "printed_on",                                                        :null => false
    t.boolean  "intermediate",                                   :default => false, :null => false
    t.string   "number",                                                            :null => false
    t.decimal  "debit",           :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "credit",          :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "company_id",                                                        :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                                   :default => 0,     :null => false
  end

  add_index "bank_account_statements", ["bank_account_id"], :name => "index_bank_account_statements_on_bank_account_id"
  add_index "bank_account_statements", ["company_id"], :name => "index_bank_account_statements_on_company_id"
  add_index "bank_account_statements", ["created_at"], :name => "index_bank_account_statements_on_created_at"
  add_index "bank_account_statements", ["created_by"], :name => "index_bank_account_statements_on_created_by"
  add_index "bank_account_statements", ["updated_at"], :name => "index_bank_account_statements_on_updated_at"
  add_index "bank_account_statements", ["updated_by"], :name => "index_bank_account_statements_on_updated_by"

  create_table "bank_accounts", :force => true do |t|
    t.string   "name",                                      :null => false
    t.string   "agency"
    t.string   "counter",      :limit => 16
    t.string   "number",       :limit => 32
    t.string   "key",          :limit => 4
    t.string   "iban",         :limit => 34,                :null => false
    t.string   "iban_text",    :limit => 48,                :null => false
    t.string   "bic",          :limit => 16
    t.integer  "bank_id",                                   :null => false
    t.integer  "journal_id",                                :null => false
    t.integer  "currency_id",                               :null => false
    t.integer  "account_id",                                :null => false
    t.integer  "company_id",                                :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",               :default => 0, :null => false
  end

  add_index "bank_accounts", ["account_id"], :name => "index_bank_accounts_on_account_id"
  add_index "bank_accounts", ["bank_id"], :name => "index_bank_accounts_on_bank_id"
  add_index "bank_accounts", ["account_id", "bank_id"], :name => "index_bank_accounts_on_bank_id_and_account_id", :unique => true
  add_index "bank_accounts", ["company_id"], :name => "index_bank_accounts_on_company_id"
  add_index "bank_accounts", ["created_at"], :name => "index_bank_accounts_on_created_at"
  add_index "bank_accounts", ["created_by"], :name => "index_bank_accounts_on_created_by"
  add_index "bank_accounts", ["currency_id"], :name => "index_bank_accounts_on_currency_id"
  add_index "bank_accounts", ["journal_id"], :name => "index_bank_accounts_on_journal_id"
  add_index "bank_accounts", ["account_id", "bank_id", "name"], :name => "index_bank_accounts_on_name_and_bank_id_and_account_id", :unique => true
  add_index "bank_accounts", ["updated_at"], :name => "index_bank_accounts_on_updated_at"
  add_index "bank_accounts", ["updated_by"], :name => "index_bank_accounts_on_updated_by"

  create_table "banks", :force => true do |t|
    t.string   "name",                                      :null => false
    t.string   "code",         :limit => 16,                :null => false
    t.integer  "company_id",                                :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",               :default => 0, :null => false
  end

  add_index "banks", ["code", "company_id"], :name => "index_banks_on_code_and_company_id", :unique => true
  add_index "banks", ["company_id"], :name => "index_banks_on_company_id"
  add_index "banks", ["created_at"], :name => "index_banks_on_created_at"
  add_index "banks", ["created_by"], :name => "index_banks_on_created_by"
  add_index "banks", ["company_id", "name"], :name => "index_banks_on_name_and_company_id", :unique => true
  add_index "banks", ["updated_at"], :name => "index_banks_on_updated_at"
  add_index "banks", ["updated_by"], :name => "index_banks_on_updated_by"

  create_table "companies", :force => true do |t|
    t.string   "name",                                         :null => false
    t.string   "code",         :limit => 8,                    :null => false
    t.string   "siren",        :limit => 9
    t.date     "born_on"
    t.boolean  "locked",                    :default => false, :null => false
    t.boolean  "deleted",                   :default => false, :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",              :default => 0,     :null => false
  end

  add_index "companies", ["code"], :name => "index_companies_on_code", :unique => true
  add_index "companies", ["created_at"], :name => "index_companies_on_created_at"
  add_index "companies", ["created_by"], :name => "index_companies_on_created_by"
  add_index "companies", ["name"], :name => "index_companies_on_name", :unique => true
  add_index "companies", ["updated_at"], :name => "index_companies_on_updated_at"
  add_index "companies", ["updated_by"], :name => "index_companies_on_updated_by"

  create_table "contacts", :force => true do |t|
    t.integer  "element_id",                                    :null => false
    t.string   "element_type"
    t.integer  "norm_id",                                       :null => false
    t.boolean  "active",                      :default => true, :null => false
    t.boolean  "default",                     :default => true, :null => false
    t.date     "closed_on"
    t.string   "line_2",        :limit => 38
    t.string   "line_3",        :limit => 38
    t.string   "line_4_number", :limit => 38
    t.string   "line_4_street", :limit => 38
    t.string   "line_5",        :limit => 38
    t.string   "line_6_code",   :limit => 38
    t.string   "line_6_city",   :limit => 38
    t.string   "phone",         :limit => 32
    t.string   "fax",           :limit => 32
    t.string   "mobile",        :limit => 32
    t.string   "email"
    t.string   "website"
    t.integer  "company_id",                                    :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                :default => 0,    :null => false
  end

  add_index "contacts", ["active"], :name => "index_contacts_on_active"
  add_index "contacts", ["company_id"], :name => "index_contacts_on_company_id"
  add_index "contacts", ["created_at"], :name => "index_contacts_on_created_at"
  add_index "contacts", ["created_by"], :name => "index_contacts_on_created_by"
  add_index "contacts", ["default"], :name => "index_contacts_on_default"
  add_index "contacts", ["element_id"], :name => "index_contacts_on_element_id"
  add_index "contacts", ["element_type"], :name => "index_contacts_on_element_type"
  add_index "contacts", ["updated_at"], :name => "index_contacts_on_updated_at"
  add_index "contacts", ["updated_by"], :name => "index_contacts_on_updated_by"

  create_table "currencies", :force => true do |t|
    t.string   "name",                                                                        :null => false
    t.string   "code",                                                                        :null => false
    t.string   "format",       :limit => 16,                                                  :null => false
    t.decimal  "rate",                       :precision => 16, :scale => 6, :default => 1.0,  :null => false
    t.boolean  "active",                                                    :default => true, :null => false
    t.text     "comment"
    t.integer  "company_id",                                                                  :null => false
    t.datetime "created_at",                                                                  :null => false
    t.datetime "updated_at",                                                                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                                              :default => 0,    :null => false
  end

  add_index "currencies", ["active"], :name => "index_currencies_on_active"
  add_index "currencies", ["code", "company_id"], :name => "index_currencies_on_code_and_company_id", :unique => true
  add_index "currencies", ["company_id"], :name => "index_currencies_on_company_id"
  add_index "currencies", ["created_at"], :name => "index_currencies_on_created_at"
  add_index "currencies", ["created_by"], :name => "index_currencies_on_created_by"
  add_index "currencies", ["name"], :name => "index_currencies_on_name"
  add_index "currencies", ["updated_at"], :name => "index_currencies_on_updated_at"
  add_index "currencies", ["updated_by"], :name => "index_currencies_on_updated_by"

  create_table "delays", :force => true do |t|
    t.string   "name",                            :null => false
    t.boolean  "active",       :default => false, :null => false
    t.string   "expression",   :default => "0",   :null => false
    t.integer  "company_id",                      :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version", :default => 0,     :null => false
  end

  add_index "delays", ["created_at"], :name => "index_delays_on_created_at"
  add_index "delays", ["created_by"], :name => "index_delays_on_created_by"
  add_index "delays", ["company_id", "name"], :name => "index_delays_on_name_and_company_id", :unique => true
  add_index "delays", ["updated_at"], :name => "index_delays_on_updated_at"
  add_index "delays", ["updated_by"], :name => "index_delays_on_updated_by"

  create_table "departments", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "desc"
    t.integer  "parent_id"
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "departments", ["created_at"], :name => "index_departments_on_created_at"
  add_index "departments", ["created_by"], :name => "index_departments_on_created_by"
  add_index "departments", ["company_id", "name"], :name => "index_departments_on_name_and_company_id", :unique => true
  add_index "departments", ["parent_id"], :name => "index_departments_on_parent_id"
  add_index "departments", ["updated_at"], :name => "index_departments_on_updated_at"
  add_index "departments", ["updated_by"], :name => "index_departments_on_updated_by"

  create_table "employees", :force => true do |t|
    t.integer  "department_id",                                 :null => false
    t.integer  "establishment_id",                              :null => false
    t.integer  "user_id"
    t.string   "title",            :limit => 32,                :null => false
    t.string   "last_name",                                     :null => false
    t.string   "first_name",                                    :null => false
    t.date     "arrived_on",                                    :null => false
    t.date     "departed_on",                                   :null => false
    t.string   "role"
    t.string   "office",           :limit => 32
    t.text     "note"
    t.integer  "company_id",                                    :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                   :default => 0, :null => false
  end

  add_index "employees", ["company_id", "user_id"], :name => "index_employees_on_company_id_and_user_id", :unique => true
  add_index "employees", ["created_at"], :name => "index_employees_on_created_at"
  add_index "employees", ["created_by"], :name => "index_employees_on_created_by"
  add_index "employees", ["updated_at"], :name => "index_employees_on_updated_at"
  add_index "employees", ["updated_by"], :name => "index_employees_on_updated_by"

  create_table "entities", :force => true do |t|
    t.integer  "nature_id",                                    :null => false
    t.integer  "language_id",                                  :null => false
    t.string   "code",                                         :null => false
    t.string   "name",                                         :null => false
    t.string   "first_name"
    t.string   "full_name",                                    :null => false
    t.boolean  "active",                     :default => true, :null => false
    t.date     "born_on"
    t.date     "dead_on"
    t.string   "ean13",        :limit => 13
    t.string   "soundex",      :limit => 4
    t.string   "website"
    t.integer  "company_id",                                   :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",               :default => 0,    :null => false
  end

  add_index "entities", ["code", "company_id"], :name => "index_entities_on_code_and_company_id", :unique => true
  add_index "entities", ["company_id"], :name => "index_entities_on_company_id"
  add_index "entities", ["created_at"], :name => "index_entities_on_created_at"
  add_index "entities", ["created_by"], :name => "index_entities_on_created_by"
  add_index "entities", ["company_id", "full_name"], :name => "index_entities_on_full_name_and_company_id"
  add_index "entities", ["company_id", "name"], :name => "index_entities_on_name_and_company_id"
  add_index "entities", ["company_id", "soundex"], :name => "index_entities_on_soundex_and_company_id"
  add_index "entities", ["updated_at"], :name => "index_entities_on_updated_at"
  add_index "entities", ["updated_by"], :name => "index_entities_on_updated_by"

  create_table "entity_natures", :force => true do |t|
    t.string   "name",                            :null => false
    t.string   "abbreviation",                    :null => false
    t.boolean  "active",       :default => true,  :null => false
    t.boolean  "physical",     :default => false, :null => false
    t.boolean  "in_name",      :default => true,  :null => false
    t.string   "title"
    t.text     "description"
    t.integer  "company_id",                      :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version", :default => 0,     :null => false
  end

  add_index "entity_natures", ["company_id"], :name => "index_entity_natures_on_company_id"
  add_index "entity_natures", ["created_at"], :name => "index_entity_natures_on_created_at"
  add_index "entity_natures", ["created_by"], :name => "index_entity_natures_on_created_by"
  add_index "entity_natures", ["company_id", "name"], :name => "index_entity_natures_on_name_and_company_id", :unique => true
  add_index "entity_natures", ["updated_at"], :name => "index_entity_natures_on_updated_at"
  add_index "entity_natures", ["updated_by"], :name => "index_entity_natures_on_updated_by"

  create_table "entries", :force => true do |t|
    t.integer  "record_id",                                                                    :null => false
    t.integer  "account_id",                                                                   :null => false
    t.string   "name",                                                                         :null => false
    t.integer  "currency_id",                                                                  :null => false
    t.decimal  "currency_rate",                :precision => 16, :scale => 6, :default => 1.0, :null => false
    t.decimal  "currency_debit",               :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "currency_credit",              :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "debit",                        :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "credit",                       :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "intermediate_id"
    t.integer  "statement_id"
    t.string   "letter",          :limit => 8
    t.date     "expired_on"
    t.integer  "position"
    t.text     "comment"
    t.integer  "company_id",                                                                   :null => false
    t.datetime "created_at",                                                                   :null => false
    t.datetime "updated_at",                                                                   :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                                                :default => 0,   :null => false
  end

  add_index "entries", ["account_id"], :name => "index_entries_on_account_id"
  add_index "entries", ["company_id"], :name => "index_entries_on_company_id"
  add_index "entries", ["created_at"], :name => "index_entries_on_created_at"
  add_index "entries", ["created_by"], :name => "index_entries_on_created_by"
  add_index "entries", ["intermediate_id"], :name => "index_entries_on_intermediate_id"
  add_index "entries", ["letter"], :name => "index_entries_on_letter"
  add_index "entries", ["name"], :name => "index_entries_on_name"
  add_index "entries", ["record_id"], :name => "index_entries_on_record_id"
  add_index "entries", ["statement_id"], :name => "index_entries_on_statement_id"
  add_index "entries", ["updated_at"], :name => "index_entries_on_updated_at"
  add_index "entries", ["updated_by"], :name => "index_entries_on_updated_by"

  create_table "establishments", :force => true do |t|
    t.string   "name",                                     :null => false
    t.string   "nic",          :limit => 5,                :null => false
    t.string   "siret",                                    :null => false
    t.text     "note"
    t.integer  "company_id",                               :null => false
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",              :default => 0, :null => false
  end

  add_index "establishments", ["created_at"], :name => "index_establishments_on_created_at"
  add_index "establishments", ["created_by"], :name => "index_establishments_on_created_by"
  add_index "establishments", ["company_id", "name"], :name => "index_establishments_on_name_and_company_id", :unique => true
  add_index "establishments", ["company_id", "siret"], :name => "index_establishments_on_siret_and_company_id", :unique => true
  add_index "establishments", ["updated_at"], :name => "index_establishments_on_updated_at"
  add_index "establishments", ["updated_by"], :name => "index_establishments_on_updated_by"

  create_table "financialyear_natures", :force => true do |t|
    t.string   "name",                                         :null => false
    t.string   "code",         :limit => 2,                    :null => false
    t.boolean  "fiscal",                    :default => false, :null => false
    t.integer  "month_number",              :default => 12,    :null => false
    t.integer  "company_id",                                   :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",              :default => 0,     :null => false
  end

  add_index "financialyear_natures", ["code", "company_id"], :name => "index_financialyear_natures_on_code_and_company_id", :unique => true
  add_index "financialyear_natures", ["company_id"], :name => "index_financialyear_natures_on_company_id"
  add_index "financialyear_natures", ["created_at"], :name => "index_financialyear_natures_on_created_at"
  add_index "financialyear_natures", ["created_by"], :name => "index_financialyear_natures_on_created_by"
  add_index "financialyear_natures", ["company_id", "fiscal"], :name => "index_financialyear_natures_on_fiscal_and_company_id"
  add_index "financialyear_natures", ["company_id", "name"], :name => "index_financialyear_natures_on_name_and_company_id", :unique => true
  add_index "financialyear_natures", ["updated_at"], :name => "index_financialyear_natures_on_updated_at"
  add_index "financialyear_natures", ["updated_by"], :name => "index_financialyear_natures_on_updated_by"

  create_table "financialyears", :force => true do |t|
    t.string   "code",         :limit => 12,                                                   :null => false
    t.integer  "nature_id",                                                                    :null => false
    t.boolean  "closed",                                                    :default => false, :null => false
    t.date     "started_on",                                                                   :null => false
    t.date     "stopped_on",                                                                   :null => false
    t.date     "written_on",                                                                   :null => false
    t.decimal  "debit",                      :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "credit",                     :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "position",                                                                     :null => false
    t.integer  "company_id",                                                                   :null => false
    t.datetime "created_at",                                                                   :null => false
    t.datetime "updated_at",                                                                   :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                                              :default => 0,     :null => false
  end

  add_index "financialyears", ["code", "company_id"], :name => "index_financialyears_on_code_and_company_id", :unique => true
  add_index "financialyears", ["company_id"], :name => "index_financialyears_on_company_id"
  add_index "financialyears", ["created_at"], :name => "index_financialyears_on_created_at"
  add_index "financialyears", ["created_by"], :name => "index_financialyears_on_created_by"
  add_index "financialyears", ["company_id", "nature_id"], :name => "index_financialyears_on_nature_id_and_company_id"
  add_index "financialyears", ["updated_at"], :name => "index_financialyears_on_updated_at"
  add_index "financialyears", ["updated_by"], :name => "index_financialyears_on_updated_by"

  create_table "journal_natures", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "comment"
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "journal_natures", ["company_id"], :name => "index_journal_natures_on_company_id"
  add_index "journal_natures", ["created_at"], :name => "index_journal_natures_on_created_at"
  add_index "journal_natures", ["created_by"], :name => "index_journal_natures_on_created_by"
  add_index "journal_natures", ["company_id", "name"], :name => "index_journal_natures_on_name_and_company_id", :unique => true
  add_index "journal_natures", ["updated_at"], :name => "index_journal_natures_on_updated_at"
  add_index "journal_natures", ["updated_by"], :name => "index_journal_natures_on_updated_by"

  create_table "journal_periods", :force => true do |t|
    t.integer  "journal_id",                                                         :null => false
    t.integer  "financialyear_id",                                                   :null => false
    t.date     "started_on",                                                         :null => false
    t.date     "stopped_on",                                                         :null => false
    t.boolean  "closed",                                          :default => false
    t.decimal  "debit",            :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "credit",           :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "balance",          :precision => 16, :scale => 2, :default => 0.0,   :null => false
    t.integer  "company_id",                                                         :null => false
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                                    :default => 0,     :null => false
  end

  add_index "journal_periods", ["company_id"], :name => "index_journal_periods_on_company_id"
  add_index "journal_periods", ["created_at"], :name => "index_journal_periods_on_created_at"
  add_index "journal_periods", ["created_by"], :name => "index_journal_periods_on_created_by"
  add_index "journal_periods", ["financialyear_id"], :name => "index_journal_periods_on_financialyear_id"
  add_index "journal_periods", ["journal_id"], :name => "index_journal_periods_on_journal_id"
  add_index "journal_periods", ["started_on"], :name => "index_journal_periods_on_started_on"
  add_index "journal_periods", ["journal_id", "started_on"], :name => "index_journal_periods_on_started_on_and_journal_id", :unique => true
  add_index "journal_periods", ["stopped_on"], :name => "index_journal_periods_on_stopped_on"
  add_index "journal_periods", ["journal_id", "stopped_on"], :name => "index_journal_periods_on_stopped_on_and_journal_id", :unique => true
  add_index "journal_periods", ["updated_at"], :name => "index_journal_periods_on_updated_at"
  add_index "journal_periods", ["updated_by"], :name => "index_journal_periods_on_updated_by"

  create_table "journal_records", :force => true do |t|
    t.integer  "resource_id",                                                                :null => false
    t.string   "resource_type"
    t.date     "created_on",                                                                 :null => false
    t.date     "printed_on",                                                                 :null => false
    t.string   "number",                                                                     :null => false
    t.string   "status",        :limit => 1,                                :default => "A", :null => false
    t.decimal  "debit",                      :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "credit",                     :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.decimal  "balance",                    :precision => 16, :scale => 2, :default => 0.0, :null => false
    t.integer  "position",                                                                   :null => false
    t.integer  "period_id",                                                                  :null => false
    t.integer  "journal_id",                                                                 :null => false
    t.integer  "company_id",                                                                 :null => false
    t.datetime "created_at",                                                                 :null => false
    t.datetime "updated_at",                                                                 :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                                              :default => 0,   :null => false
  end

  add_index "journal_records", ["company_id"], :name => "index_journal_records_on_company_id"
  add_index "journal_records", ["created_at"], :name => "index_journal_records_on_created_at"
  add_index "journal_records", ["created_by"], :name => "index_journal_records_on_created_by"
  add_index "journal_records", ["company_id", "created_on"], :name => "index_journal_records_on_created_on_and_company_id"
  add_index "journal_records", ["journal_id"], :name => "index_journal_records_on_journal_id"
  add_index "journal_records", ["period_id"], :name => "index_journal_records_on_period_id"
  add_index "journal_records", ["company_id", "printed_on"], :name => "index_journal_records_on_printed_on_and_company_id"
  add_index "journal_records", ["company_id", "status"], :name => "index_journal_records_on_status_and_company_id"
  add_index "journal_records", ["updated_at"], :name => "index_journal_records_on_updated_at"
  add_index "journal_records", ["updated_by"], :name => "index_journal_records_on_updated_by"

  create_table "journals", :force => true do |t|
    t.integer  "nature_id",                                             :null => false
    t.string   "name",                                                  :null => false
    t.string   "code",           :limit => 4,                           :null => false
    t.integer  "counterpart_id"
    t.date     "closed_on",                   :default => '1494-12-31', :null => false
    t.integer  "company_id",                                            :null => false
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                :default => 0,            :null => false
  end

  add_index "journals", ["code", "company_id"], :name => "index_journals_on_code_and_company_id", :unique => true
  add_index "journals", ["company_id"], :name => "index_journals_on_company_id"
  add_index "journals", ["created_at"], :name => "index_journals_on_created_at"
  add_index "journals", ["created_by"], :name => "index_journals_on_created_by"
  add_index "journals", ["company_id", "name"], :name => "index_journals_on_name_and_company_id", :unique => true
  add_index "journals", ["nature_id"], :name => "index_journals_on_nature_id"
  add_index "journals", ["updated_at"], :name => "index_journals_on_updated_at"
  add_index "journals", ["updated_by"], :name => "index_journals_on_updated_by"

  create_table "languages", :force => true do |t|
    t.string "name",                     :null => false
    t.string "native_name"
    t.string "iso2",        :limit => 2, :null => false
    t.string "iso3",        :limit => 3, :null => false
  end

  add_index "languages", ["iso2"], :name => "index_languages_on_iso2"
  add_index "languages", ["iso3"], :name => "index_languages_on_iso3"
  add_index "languages", ["name"], :name => "index_languages_on_name"

  create_table "parameters", :force => true do |t|
    t.string   "name",                                        :null => false
    t.string   "nature",        :limit => 1, :default => "u", :null => false
    t.text     "string_value"
    t.boolean  "boolean_value"
    t.integer  "integer_value"
    t.decimal  "decimal_value"
    t.string   "element_type"
    t.integer  "element_id"
    t.integer  "user_id"
    t.integer  "company_id",                                  :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",               :default => 0,   :null => false
  end

  add_index "parameters", ["company_id"], :name => "index_parameters_on_company_id"
  add_index "parameters", ["company_id", "name"], :name => "index_parameters_on_company_id_and_name", :unique => true
  add_index "parameters", ["created_at"], :name => "index_parameters_on_created_at"
  add_index "parameters", ["created_by"], :name => "index_parameters_on_created_by"
  add_index "parameters", ["updated_at"], :name => "index_parameters_on_updated_at"
  add_index "parameters", ["updated_by"], :name => "index_parameters_on_updated_by"

  create_table "roles", :force => true do |t|
    t.string   "name",                           :null => false
    t.integer  "company_id",                     :null => false
    t.text     "actions",      :default => "  ", :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version", :default => 0,    :null => false
  end

  add_index "roles", ["company_id"], :name => "index_roles_on_company_id"
  add_index "roles", ["company_id", "name"], :name => "index_roles_on_company_id_and_name", :unique => true
  add_index "roles", ["created_at"], :name => "index_roles_on_created_at"
  add_index "roles", ["created_by"], :name => "index_roles_on_created_by"
  add_index "roles", ["updated_at"], :name => "index_roles_on_updated_at"
  add_index "roles", ["updated_by"], :name => "index_roles_on_updated_by"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "templates", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "content",                     :null => false
    t.text     "cache"
    t.integer  "company_id",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "templates", ["company_id"], :name => "index_templates_on_company_id"
  add_index "templates", ["company_id", "name"], :name => "index_templates_on_company_id_and_name", :unique => true
  add_index "templates", ["created_at"], :name => "index_templates_on_created_at"
  add_index "templates", ["created_by"], :name => "index_templates_on_created_by"
  add_index "templates", ["updated_at"], :name => "index_templates_on_updated_at"
  add_index "templates", ["updated_by"], :name => "index_templates_on_updated_by"

  create_table "users", :force => true do |t|
    t.string   "name",            :limit => 32,                    :null => false
    t.string   "first_name",                                       :null => false
    t.string   "last_name",                                        :null => false
    t.string   "salt",            :limit => 64
    t.string   "hashed_password", :limit => 64
    t.boolean  "locked",                        :default => false, :null => false
    t.boolean  "deleted",                       :default => false, :null => false
    t.string   "email"
    t.integer  "company_id",                                       :null => false
    t.integer  "language_id",                                      :null => false
    t.integer  "role_id",                                          :null => false
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "lock_version",                  :default => 0,     :null => false
  end

  add_index "users", ["company_id"], :name => "index_users_on_company_id"
  add_index "users", ["created_at"], :name => "index_users_on_created_at"
  add_index "users", ["created_by"], :name => "index_users_on_created_by"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["name"], :name => "index_users_on_name", :unique => true
  add_index "users", ["updated_at"], :name => "index_users_on_updated_at"
  add_index "users", ["updated_by"], :name => "index_users_on_updated_by"

  add_foreign_key "account_balances", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "account_balances_updated_by_fkey"
  add_foreign_key "account_balances", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "account_balances_created_by_fkey"
  add_foreign_key "account_balances", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "account_balances_company_id_fkey"
  add_foreign_key "account_balances", ["financialyear_id"], "financialyears", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "account_balances_financialyear_id_fkey"
  add_foreign_key "account_balances", ["account_id"], "accounts", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "account_balances_account_id_fkey"

  add_foreign_key "accounts", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "accounts_updated_by_fkey"
  add_foreign_key "accounts", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "accounts_created_by_fkey"
  add_foreign_key "accounts", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "accounts_company_id_fkey"
  add_foreign_key "accounts", ["entity_id"], "entities", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "accounts_entity_id_fkey"
  add_foreign_key "accounts", ["delay_id"], "delays", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "accounts_delay_id_fkey"

  add_foreign_key "actions", ["parent_id"], "actions", ["id"], :name => "actions_parent_id_fkey"

  add_foreign_key "actions_roles", ["action_id"], "actions", ["id"], :name => "actions_roles_action_id_fkey"

  add_foreign_key "address_norm_items", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "address_norm_items_updated_by_fkey"
  add_foreign_key "address_norm_items", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "address_norm_items_created_by_fkey"
  add_foreign_key "address_norm_items", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "address_norm_items_company_id_fkey"
  add_foreign_key "address_norm_items", ["contact_norm_id"], "address_norms", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "address_norm_items_contact_norm_id_fkey"

  add_foreign_key "address_norms", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "address_norms_updated_by_fkey"
  add_foreign_key "address_norms", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "address_norms_created_by_fkey"
  add_foreign_key "address_norms", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "address_norms_company_id_fkey"

  add_foreign_key "bank_account_statements", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "bank_account_statements_updated_by_fkey"
  add_foreign_key "bank_account_statements", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "bank_account_statements_created_by_fkey"
  add_foreign_key "bank_account_statements", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "bank_account_statements_company_id_fkey"
  add_foreign_key "bank_account_statements", ["bank_account_id"], "bank_accounts", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "bank_account_statements_bank_account_id_fkey"

  add_foreign_key "bank_accounts", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "bank_accounts_updated_by_fkey"
  add_foreign_key "bank_accounts", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "bank_accounts_created_by_fkey"
  add_foreign_key "bank_accounts", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "bank_accounts_company_id_fkey"
  add_foreign_key "bank_accounts", ["account_id"], "accounts", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "bank_accounts_account_id_fkey"
  add_foreign_key "bank_accounts", ["currency_id"], "currencies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "bank_accounts_currency_id_fkey"
  add_foreign_key "bank_accounts", ["journal_id"], "journals", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "bank_accounts_journal_id_fkey"
  add_foreign_key "bank_accounts", ["bank_id"], "banks", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "bank_accounts_bank_id_fkey"

  add_foreign_key "banks", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "banks_updated_by_fkey"
  add_foreign_key "banks", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "banks_created_by_fkey"
  add_foreign_key "banks", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "banks_company_id_fkey"

  add_foreign_key "companies", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "companies_updated_by_fkey"
  add_foreign_key "companies", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "companies_created_by_fkey"

  add_foreign_key "contacts", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "contacts_updated_by_fkey"
  add_foreign_key "contacts", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "contacts_created_by_fkey"
  add_foreign_key "contacts", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "contacts_company_id_fkey"
  add_foreign_key "contacts", ["norm_id"], "address_norms", ["id"], :name => "contacts_norm_id_fkey"

  add_foreign_key "currencies", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "currencies_updated_by_fkey"
  add_foreign_key "currencies", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "currencies_created_by_fkey"
  add_foreign_key "currencies", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "currencies_company_id_fkey"

  add_foreign_key "delays", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "delays_updated_by_fkey"
  add_foreign_key "delays", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "delays_created_by_fkey"
  add_foreign_key "delays", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "delays_company_id_fkey"

  add_foreign_key "departments", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "departments_updated_by_fkey"
  add_foreign_key "departments", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "departments_created_by_fkey"
  add_foreign_key "departments", ["company_id"], "companies", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "departments_company_id_fkey"
  add_foreign_key "departments", ["parent_id"], "departments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "departments_parent_id_fkey"

  add_foreign_key "employees", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "employees_updated_by_fkey"
  add_foreign_key "employees", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "employees_created_by_fkey"
  add_foreign_key "employees", ["company_id"], "companies", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "employees_company_id_fkey"
  add_foreign_key "employees", ["user_id"], "users", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "employees_user_id_fkey"
  add_foreign_key "employees", ["establishment_id"], "establishments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "employees_establishment_id_fkey"
  add_foreign_key "employees", ["department_id"], "departments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "employees_department_id_fkey"

  add_foreign_key "entities", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entities_updated_by_fkey"
  add_foreign_key "entities", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entities_created_by_fkey"
  add_foreign_key "entities", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "entities_company_id_fkey"
  add_foreign_key "entities", ["language_id"], "languages", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entities_language_id_fkey"
  add_foreign_key "entities", ["nature_id"], "entity_natures", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entities_nature_id_fkey"

  add_foreign_key "entity_natures", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entity_natures_updated_by_fkey"
  add_foreign_key "entity_natures", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entity_natures_created_by_fkey"
  add_foreign_key "entity_natures", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "entity_natures_company_id_fkey"

  add_foreign_key "entries", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entries_updated_by_fkey"
  add_foreign_key "entries", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entries_created_by_fkey"
  add_foreign_key "entries", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "entries_company_id_fkey"
  add_foreign_key "entries", ["statement_id"], "bank_account_statements", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entries_statement_id_fkey"
  add_foreign_key "entries", ["intermediate_id"], "bank_account_statements", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entries_intermediate_id_fkey"
  add_foreign_key "entries", ["currency_id"], "currencies", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entries_currency_id_fkey"
  add_foreign_key "entries", ["account_id"], "accounts", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entries_account_id_fkey"
  add_foreign_key "entries", ["record_id"], "journal_records", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "entries_record_id_fkey"

  add_foreign_key "establishments", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "establishments_updated_by_fkey"
  add_foreign_key "establishments", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "establishments_created_by_fkey"
  add_foreign_key "establishments", ["company_id"], "companies", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "establishments_company_id_fkey"

  add_foreign_key "financialyear_natures", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "financialyear_natures_updated_by_fkey"
  add_foreign_key "financialyear_natures", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "financialyear_natures_created_by_fkey"
  add_foreign_key "financialyear_natures", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "financialyear_natures_company_id_fkey"

  add_foreign_key "financialyears", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "financialyears_updated_by_fkey"
  add_foreign_key "financialyears", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "financialyears_created_by_fkey"
  add_foreign_key "financialyears", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "financialyears_company_id_fkey"
  add_foreign_key "financialyears", ["nature_id"], "financialyear_natures", ["id"], :name => "financialyears_nature_id_fkey"

  add_foreign_key "journal_natures", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_natures_updated_by_fkey"
  add_foreign_key "journal_natures", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_natures_created_by_fkey"
  add_foreign_key "journal_natures", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "journal_natures_company_id_fkey"

  add_foreign_key "journal_periods", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_periods_updated_by_fkey"
  add_foreign_key "journal_periods", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_periods_created_by_fkey"
  add_foreign_key "journal_periods", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "journal_periods_company_id_fkey"
  add_foreign_key "journal_periods", ["financialyear_id"], "financialyears", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_periods_financialyear_id_fkey"
  add_foreign_key "journal_periods", ["journal_id"], "journals", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_periods_journal_id_fkey"

  add_foreign_key "journal_records", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_records_updated_by_fkey"
  add_foreign_key "journal_records", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_records_created_by_fkey"
  add_foreign_key "journal_records", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "journal_records_company_id_fkey"
  add_foreign_key "journal_records", ["journal_id"], "journals", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_records_journal_id_fkey"
  add_foreign_key "journal_records", ["period_id"], "journal_periods", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journal_records_period_id_fkey"

  add_foreign_key "journals", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journals_updated_by_fkey"
  add_foreign_key "journals", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journals_created_by_fkey"
  add_foreign_key "journals", ["company_id"], "companies", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "journals_company_id_fkey"
  add_foreign_key "journals", ["counterpart_id"], "accounts", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "journals_counterpart_id_fkey"
  add_foreign_key "journals", ["nature_id"], "journal_natures", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "journals_nature_id_fkey"

  add_foreign_key "parameters", ["user_id"], "users", ["id"], :on_update => :cascade, :on_delete => :cascade, :name => "parameters_user_id_fkey"
  add_foreign_key "parameters", ["company_id"], "companies", ["id"], :name => "parameters_company_id_fkey"
  add_foreign_key "parameters", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "parameters_created_by_fkey"
  add_foreign_key "parameters", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "parameters_updated_by_fkey"

  add_foreign_key "roles", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "roles_updated_by_fkey"
  add_foreign_key "roles", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "roles_created_by_fkey"
  add_foreign_key "roles", ["company_id"], "companies", ["id"], :name => "roles_company_id_fkey"

  add_foreign_key "templates", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "templates_updated_by_fkey"
  add_foreign_key "templates", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "templates_created_by_fkey"
  add_foreign_key "templates", ["company_id"], "companies", ["id"], :name => "templates_company_id_fkey"

  add_foreign_key "users", ["updated_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "users_updated_by_fkey"
  add_foreign_key "users", ["created_by"], "users", ["id"], :on_update => :cascade, :on_delete => :restrict, :name => "users_created_by_fkey"

end
