# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20130125154553) do

  create_table "account_balances", :force => true do |t|
    t.integer  "account_id",                                                        :null => false
    t.integer  "financial_year_id",                                                 :null => false
    t.decimal  "global_debit",      :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "global_credit",     :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "global_balance",    :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "global_count",                                     :default => 0,   :null => false
    t.decimal  "local_debit",       :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "local_credit",      :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "local_balance",     :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "local_count",                                      :default => 0,   :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,   :null => false
  end

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
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                :default => 0,     :null => false
    t.boolean  "reconcilable",                :default => false, :null => false
  end

  add_index "accounts", ["created_at"], :name => "index_accounts_on_created_at"
  add_index "accounts", ["creator_id"], :name => "index_accounts_on_creator_id"
  add_index "accounts", ["updated_at"], :name => "index_accounts_on_updated_at"
  add_index "accounts", ["updater_id"], :name => "index_accounts_on_updater_id"

  create_table "affairs", :force => true do |t|
    t.boolean  "closed",                                                       :default => false, :null => false
    t.datetime "closed_at"
    t.string   "currency",         :limit => 3,                                                   :null => false
    t.decimal  "debit",                         :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "credit",                        :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.datetime "created_at",                                                                      :null => false
    t.datetime "updated_at",                                                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                 :default => 0,     :null => false
  end

  add_index "affairs", ["created_at"], :name => "index_affairs_on_created_at"
  add_index "affairs", ["creator_id"], :name => "index_affairs_on_creator_id"
  add_index "affairs", ["updated_at"], :name => "index_affairs_on_updated_at"
  add_index "affairs", ["updater_id"], :name => "index_affairs_on_updater_id"

  create_table "areas", :force => true do |t|
    t.string   "postcode",                                    :null => false
    t.string   "name",                                        :null => false
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

  create_table "asset_depreciations", :force => true do |t|
    t.integer  "asset_id",                                                             :null => false
    t.integer  "journal_entry_id"
    t.boolean  "accountable",                                       :default => false, :null => false
    t.date     "created_on",                                                           :null => false
    t.datetime "accounted_at"
    t.date     "started_on",                                                           :null => false
    t.date     "stopped_on",                                                           :null => false
    t.text     "depreciation"
    t.decimal  "amount",             :precision => 19, :scale => 4,                    :null => false
    t.integer  "position"
    t.datetime "created_at",                                                           :null => false
    t.datetime "updated_at",                                                           :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                      :default => 0,     :null => false
    t.boolean  "protected",                                         :default => false, :null => false
    t.integer  "financial_year_id"
    t.decimal  "asset_amount",       :precision => 19, :scale => 4
    t.decimal  "depreciated_amount", :precision => 19, :scale => 4
  end

  add_index "asset_depreciations", ["asset_id"], :name => "index_asset_depreciations_on_asset_id"
  add_index "asset_depreciations", ["created_at"], :name => "index_asset_depreciations_on_created_at"
  add_index "asset_depreciations", ["creator_id"], :name => "index_asset_depreciations_on_creator_id"
  add_index "asset_depreciations", ["journal_entry_id"], :name => "index_asset_depreciations_on_journal_entry_id"
  add_index "asset_depreciations", ["updated_at"], :name => "index_asset_depreciations_on_updated_at"
  add_index "asset_depreciations", ["updater_id"], :name => "index_asset_depreciations_on_updater_id"

  create_table "assets", :force => true do |t|
    t.integer  "allocation_account_id",                                                              :null => false
    t.integer  "journal_id",                                                                         :null => false
    t.string   "name",                                                                               :null => false
    t.string   "number",                                                                             :null => false
    t.text     "description"
    t.text     "comment"
    t.date     "purchased_on"
    t.integer  "purchase_id"
    t.integer  "purchase_item_id"
    t.boolean  "ceded"
    t.date     "ceded_on"
    t.integer  "sale_id"
    t.integer  "sale_item_id"
    t.decimal  "purchase_amount",                      :precision => 19, :scale => 4
    t.date     "started_on",                                                                         :null => false
    t.date     "stopped_on",                                                                         :null => false
    t.decimal  "depreciable_amount",                   :precision => 19, :scale => 4,                :null => false
    t.decimal  "depreciated_amount",                   :precision => 19, :scale => 4,                :null => false
    t.string   "depreciation_method",                                                                :null => false
    t.datetime "created_at",                                                                         :null => false
    t.datetime "updated_at",                                                                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                        :default => 0, :null => false
    t.string   "currency",                :limit => 3
    t.decimal  "current_amount",                       :precision => 19, :scale => 4
    t.integer  "charges_account_id"
    t.decimal  "depreciation_percentage",              :precision => 19, :scale => 4
  end

  add_index "assets", ["allocation_account_id"], :name => "index_assets_on_account_id"
  add_index "assets", ["created_at"], :name => "index_assets_on_created_at"
  add_index "assets", ["creator_id"], :name => "index_assets_on_creator_id"
  add_index "assets", ["currency"], :name => "index_assets_on_currency"
  add_index "assets", ["journal_id"], :name => "index_assets_on_journal_id"
  add_index "assets", ["purchase_id"], :name => "index_assets_on_purchase_id"
  add_index "assets", ["purchase_item_id"], :name => "index_assets_on_purchase_line_id"
  add_index "assets", ["sale_id"], :name => "index_assets_on_sale_id"
  add_index "assets", ["sale_item_id"], :name => "index_assets_on_sale_line_id"
  add_index "assets", ["updated_at"], :name => "index_assets_on_updated_at"
  add_index "assets", ["updater_id"], :name => "index_assets_on_updater_id"

  create_table "bank_statements", :force => true do |t|
    t.integer  "cash_id",                                                      :null => false
    t.date     "started_on",                                                   :null => false
    t.date     "stopped_on",                                                   :null => false
    t.string   "number",                                                       :null => false
    t.decimal  "debit",        :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "credit",       :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0,   :null => false
  end

  add_index "bank_statements", ["cash_id"], :name => "index_bank_account_statements_on_bank_account_id"
  add_index "bank_statements", ["created_at"], :name => "index_bank_account_statements_on_created_at"
  add_index "bank_statements", ["creator_id"], :name => "index_bank_account_statements_on_creator_id"
  add_index "bank_statements", ["updated_at"], :name => "index_bank_account_statements_on_updated_at"
  add_index "bank_statements", ["updater_id"], :name => "index_bank_account_statements_on_updater_id"

  create_table "cash_transfers", :force => true do |t|
    t.integer  "emitter_cash_id",                                                            :null => false
    t.integer  "receiver_cash_id",                                                           :null => false
    t.integer  "emitter_journal_entry_id"
    t.datetime "accounted_at"
    t.string   "number",                                                                     :null => false
    t.text     "comment"
    t.decimal  "currency_rate",             :precision => 19, :scale => 10, :default => 1.0, :null => false
    t.decimal  "emitter_amount",            :precision => 19, :scale => 4,  :default => 0.0, :null => false
    t.decimal  "receiver_amount",           :precision => 19, :scale => 4,  :default => 0.0, :null => false
    t.datetime "created_at",                                                                 :null => false
    t.datetime "updated_at",                                                                 :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                              :default => 0,   :null => false
    t.integer  "receiver_journal_entry_id"
    t.date     "created_on"
  end

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
    t.integer  "account_id",                                             :null => false
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,              :null => false
    t.string   "bank_code"
    t.string   "agency_code"
    t.string   "number"
    t.string   "key"
    t.string   "mode",                       :default => "IBAN",         :null => false
    t.boolean  "by_default",                 :default => false,          :null => false
    t.text     "address"
    t.string   "bank_name",    :limit => 50
    t.string   "nature",       :limit => 16, :default => "bank_account", :null => false
    t.string   "currency",     :limit => 3
    t.string   "country",      :limit => 2
  end

  add_index "cashes", ["account_id"], :name => "index_bank_accounts_on_account_id"
  add_index "cashes", ["created_at"], :name => "index_bank_accounts_on_created_at"
  add_index "cashes", ["creator_id"], :name => "index_bank_accounts_on_creator_id"
  add_index "cashes", ["currency"], :name => "index_cashes_on_currency"
  add_index "cashes", ["journal_id"], :name => "index_bank_accounts_on_journal_id"
  add_index "cashes", ["updated_at"], :name => "index_bank_accounts_on_updated_at"
  add_index "cashes", ["updater_id"], :name => "index_bank_accounts_on_updater_id"

  create_table "cultivations", :force => true do |t|
    t.string   "name",                                            :null => false
    t.date     "started_on",                                      :null => false
    t.date     "stopped_on"
    t.string   "color",        :limit => 6, :default => "FFFFFF", :null => false
    t.text     "comment"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0,        :null => false
  end

  add_index "cultivations", ["created_at"], :name => "index_cultivations_on_created_at"
  add_index "cultivations", ["creator_id"], :name => "index_cultivations_on_creator_id"
  add_index "cultivations", ["updated_at"], :name => "index_cultivations_on_updated_at"
  add_index "cultivations", ["updater_id"], :name => "index_cultivations_on_updater_id"

  create_table "custom_field_choices", :force => true do |t|
    t.integer  "custom_field_id",                :null => false
    t.string   "name",                           :null => false
    t.string   "value",                          :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    :default => 0, :null => false
    t.integer  "position"
  end

  add_index "custom_field_choices", ["created_at"], :name => "index_complement_choices_on_created_at"
  add_index "custom_field_choices", ["creator_id"], :name => "index_complement_choices_on_creator_id"
  add_index "custom_field_choices", ["custom_field_id"], :name => "index_complement_choices_on_complement_id"
  add_index "custom_field_choices", ["updated_at"], :name => "index_complement_choices_on_updated_at"
  add_index "custom_field_choices", ["updater_id"], :name => "index_complement_choices_on_updater_id"

  create_table "custom_field_data", :force => true do |t|
    t.integer  "customized_id",                                                 :null => false
    t.integer  "custom_field_id",                                               :null => false
    t.decimal  "decimal_value",   :precision => 19, :scale => 4
    t.text     "string_value"
    t.boolean  "boolean_value"
    t.date     "date_value"
    t.datetime "datetime_value"
    t.integer  "choice_value_id"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                   :default => 0, :null => false
    t.string   "customized_type",                                               :null => false
  end

  add_index "custom_field_data", ["choice_value_id"], :name => "index_complement_data_on_choice_value_id"
  add_index "custom_field_data", ["created_at"], :name => "index_complement_data_on_created_at"
  add_index "custom_field_data", ["creator_id"], :name => "index_complement_data_on_creator_id"
  add_index "custom_field_data", ["custom_field_id"], :name => "index_custom_field_data_on_custom_field_id"
  add_index "custom_field_data", ["customized_type", "customized_id", "custom_field_id"], :name => "index_custom_field_data_unique", :unique => true
  add_index "custom_field_data", ["customized_type", "customized_id"], :name => "index_custom_field_data_on_customized"
  add_index "custom_field_data", ["updated_at"], :name => "index_complement_data_on_updated_at"
  add_index "custom_field_data", ["updater_id"], :name => "index_complement_data_on_updater_id"

  create_table "custom_fields", :force => true do |t|
    t.string   "name",                                                                          :null => false
    t.string   "nature",         :limit => 8,                                                   :null => false
    t.integer  "position"
    t.boolean  "active",                                                     :default => true,  :null => false
    t.boolean  "required",                                                   :default => false, :null => false
    t.integer  "maximal_length"
    t.decimal  "minimal_value",               :precision => 19, :scale => 4
    t.decimal  "maximal_value",               :precision => 19, :scale => 4
    t.datetime "created_at",                                                                    :null => false
    t.datetime "updated_at",                                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                               :default => 0,     :null => false
    t.string   "used_with",                                                                     :null => false
    t.integer  "minimal_length",                                             :default => 0,     :null => false
  end

  add_index "custom_fields", ["created_at"], :name => "index_complements_on_created_at"
  add_index "custom_fields", ["creator_id"], :name => "index_complements_on_creator_id"
  add_index "custom_fields", ["required"], :name => "index_complements_on_required"
  add_index "custom_fields", ["updated_at"], :name => "index_complements_on_updated_at"
  add_index "custom_fields", ["updater_id"], :name => "index_complements_on_updater_id"

  create_table "departments", :force => true do |t|
    t.string   "name",                            :null => false
    t.text     "comment"
    t.integer  "parent_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     :default => 0, :null => false
    t.text     "sales_conditions"
  end

  add_index "departments", ["created_at"], :name => "index_departments_on_created_at"
  add_index "departments", ["creator_id"], :name => "index_departments_on_creator_id"
  add_index "departments", ["parent_id"], :name => "index_departments_on_parent_id"
  add_index "departments", ["updated_at"], :name => "index_departments_on_updated_at"
  add_index "departments", ["updater_id"], :name => "index_departments_on_updater_id"

  create_table "deposit_items", :force => true do |t|
    t.integer  "deposit_id",                                                   :null => false
    t.decimal  "quantity",     :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",       :precision => 19, :scale => 4, :default => 1.0, :null => false
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0,   :null => false
  end

  add_index "deposit_items", ["created_at"], :name => "index_deposit_items_on_created_at"
  add_index "deposit_items", ["creator_id"], :name => "index_deposit_items_on_creator_id"
  add_index "deposit_items", ["updated_at"], :name => "index_deposit_items_on_updated_at"
  add_index "deposit_items", ["updater_id"], :name => "index_deposit_items_on_updater_id"

  create_table "deposits", :force => true do |t|
    t.decimal  "amount",           :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.integer  "payments_count",                                  :default => 0,     :null => false
    t.date     "created_on",                                                         :null => false
    t.text     "comment"
    t.integer  "cash_id",                                                            :null => false
    t.integer  "mode_id",                                                            :null => false
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

  add_index "documents", ["created_at"], :name => "index_documents_on_created_at"
  add_index "documents", ["creator_id"], :name => "index_documents_on_creator_id"
  add_index "documents", ["owner_id"], :name => "index_documents_on_owner_id"
  add_index "documents", ["owner_type"], :name => "index_documents_on_owner_type"
  add_index "documents", ["sha256"], :name => "index_documents_on_sha256"
  add_index "documents", ["updated_at"], :name => "index_documents_on_updated_at"
  add_index "documents", ["updater_id"], :name => "index_documents_on_updater_id"

  create_table "entities", :force => true do |t|
    t.integer  "nature_id",                                                                                              :null => false
    t.string   "last_name",                                                                                              :null => false
    t.string   "first_name"
    t.string   "full_name",                                                                                              :null => false
    t.string   "code",                                   :limit => 64
    t.boolean  "active",                                                                              :default => true,  :null => false
    t.date     "born_on"
    t.date     "dead_on"
    t.string   "ean13",                                  :limit => 13
    t.string   "soundex",                                :limit => 4
    t.boolean  "client",                                                                              :default => false, :null => false
    t.boolean  "supplier",                                                                            :default => false, :null => false
    t.datetime "created_at",                                                                                             :null => false
    t.datetime "updated_at",                                                                                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                        :default => 0,     :null => false
    t.integer  "client_account_id"
    t.integer  "supplier_account_id"
    t.boolean  "vat_submissive",                                                                      :default => true,  :null => false
    t.boolean  "reflation_submissive",                                                                :default => false, :null => false
    t.string   "deliveries_conditions",                  :limit => 60
    t.decimal  "reduction_percentage",                                 :precision => 19, :scale => 4
    t.text     "comment"
    t.string   "vat_number",                             :limit => 15
    t.string   "country",                                :limit => 2
    t.integer  "authorized_payments_count"
    t.integer  "responsible_id"
    t.integer  "proposer_id"
    t.integer  "payment_mode_id"
    t.integer  "invoices_count"
    t.date     "first_met_on"
    t.integer  "category_id"
    t.string   "siren",                                  :limit => 9
    t.string   "origin"
    t.string   "webpass"
    t.string   "activity_code",                          :limit => 32
    t.string   "photo"
    t.boolean  "transporter",                                                                         :default => false, :null => false
    t.string   "language",                               :limit => 3,                                 :default => "???", :null => false
    t.boolean  "prospect",                                                                            :default => false, :null => false
    t.boolean  "attorney",                                                                            :default => false, :null => false
    t.integer  "attorney_account_id"
    t.string   "user_name",                              :limit => 32
    t.string   "salt",                                   :limit => 64
    t.string   "hashed_password",                        :limit => 64
    t.boolean  "locked",                                                                              :default => false, :null => false
    t.string   "currency",                                                                                               :null => false
    t.boolean  "of_company",                                                                          :default => false, :null => false
    t.boolean  "admin",                                                                               :default => false, :null => false
    t.date     "recruited_on"
    t.datetime "connected_at"
    t.date     "left_on"
    t.integer  "department_id"
    t.boolean  "employed",                                                                            :default => false, :null => false
    t.string   "employment"
    t.integer  "establishment_id"
    t.string   "office"
    t.integer  "profession_id"
    t.decimal  "maximal_grantable_reduction_percentage",               :precision => 19, :scale => 4
    t.text     "rights"
    t.integer  "role_id"
    t.boolean  "loggable",                                                                            :default => false, :null => false
    t.string   "payment_delay"
  end

  add_index "entities", ["code"], :name => "entities_codes"
  add_index "entities", ["code"], :name => "index_entities_on_code"
  add_index "entities", ["created_at"], :name => "index_entities_on_created_at"
  add_index "entities", ["creator_id"], :name => "index_entities_on_creator_id"
  add_index "entities", ["of_company"], :name => "index_entities_on_of_company"
  add_index "entities", ["updated_at"], :name => "index_entities_on_updated_at"
  add_index "entities", ["updater_id"], :name => "index_entities_on_updater_id"

  create_table "entity_addresses", :force => true do |t|
    t.integer  "entity_id",                                                                 :null => false
    t.boolean  "by_default",                                             :default => false, :null => false
    t.string   "mail_line_2"
    t.string   "mail_line_3"
    t.string   "mail_line_5"
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                           :default => 0,     :null => false
    t.string   "mail_country",     :limit => 2
    t.string   "code",             :limit => 4
    t.datetime "deleted_at"
    t.integer  "mail_area_id"
    t.string   "mail_line_6"
    t.string   "mail_line_4"
    t.string   "canal",            :limit => 16,                                            :null => false
    t.string   "coordinate",       :limit => 511,                                           :null => false
    t.string   "name"
    t.string   "mail_line_1"
    t.spatial  "mail_geolocation", :limit => {:srid=>0, :type=>"point"}
    t.boolean  "mail_auto_update",                                       :default => false, :null => false
  end

  add_index "entity_addresses", ["by_default"], :name => "index_entity_addresses_on_by_default"
  add_index "entity_addresses", ["code"], :name => "index_entity_addresses_on_code"
  add_index "entity_addresses", ["created_at"], :name => "index_entity_addresses_on_created_at"
  add_index "entity_addresses", ["creator_id"], :name => "index_entity_addresses_on_creator_id"
  add_index "entity_addresses", ["deleted_at"], :name => "index_entity_addresses_on_deleted_at"
  add_index "entity_addresses", ["entity_id"], :name => "index_entity_addresses_on_entity_id"
  add_index "entity_addresses", ["updated_at"], :name => "index_entity_addresses_on_updated_at"
  add_index "entity_addresses", ["updater_id"], :name => "index_entity_addresses_on_updater_id"

  create_table "entity_categories", :force => true do |t|
    t.string   "name",                                         :null => false
    t.text     "description"
    t.boolean  "by_default",                :default => false, :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0,     :null => false
    t.string   "code",         :limit => 8
  end

  add_index "entity_categories", ["created_at"], :name => "index_entity_categories_on_created_at"
  add_index "entity_categories", ["creator_id"], :name => "index_entity_categories_on_creator_id"
  add_index "entity_categories", ["updated_at"], :name => "index_entity_categories_on_updated_at"
  add_index "entity_categories", ["updater_id"], :name => "index_entity_categories_on_updater_id"

  create_table "entity_link_natures", :force => true do |t|
    t.string   "name",                                  :null => false
    t.string   "name_1_to_2"
    t.string   "name_2_to_1"
    t.boolean  "symmetric",          :default => false, :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",       :default => 0,     :null => false
    t.boolean  "propagate_contacts", :default => false, :null => false
    t.text     "comment"
  end

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
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "entity_links", ["created_at"], :name => "index_entity_links_on_created_at"
  add_index "entity_links", ["creator_id"], :name => "index_entity_links_on_creator_id"
  add_index "entity_links", ["entity_1_id"], :name => "index_entity_links_on_entity1_id"
  add_index "entity_links", ["entity_2_id"], :name => "index_entity_links_on_entity2_id"
  add_index "entity_links", ["nature_id"], :name => "index_entity_links_on_nature_id"
  add_index "entity_links", ["updated_at"], :name => "index_entity_links_on_updated_at"
  add_index "entity_links", ["updater_id"], :name => "index_entity_links_on_updater_id"

  create_table "entity_natures", :force => true do |t|
    t.string   "name",                                :null => false
    t.string   "title"
    t.boolean  "active",           :default => true,  :null => false
    t.boolean  "physical",         :default => false, :null => false
    t.boolean  "in_name",          :default => true,  :null => false
    t.text     "description"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     :default => 0,     :null => false
    t.string   "full_name_format"
  end

  add_index "entity_natures", ["created_at"], :name => "index_entity_natures_on_created_at"
  add_index "entity_natures", ["creator_id"], :name => "index_entity_natures_on_creator_id"
  add_index "entity_natures", ["updated_at"], :name => "index_entity_natures_on_updated_at"
  add_index "entity_natures", ["updater_id"], :name => "index_entity_natures_on_updater_id"

  create_table "establishments", :force => true do |t|
    t.string   "name",                                     :null => false
    t.string   "nic",          :limit => 5,                :null => false
    t.string   "siret",                                    :null => false
    t.text     "comment"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0, :null => false
  end

  add_index "establishments", ["created_at"], :name => "index_establishments_on_created_at"
  add_index "establishments", ["creator_id"], :name => "index_establishments_on_creator_id"
  add_index "establishments", ["updated_at"], :name => "index_establishments_on_updated_at"
  add_index "establishments", ["updater_id"], :name => "index_establishments_on_updater_id"

  create_table "event_natures", :force => true do |t|
    t.string   "name",                                         :null => false
    t.integer  "duration"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,    :null => false
    t.string   "usage",        :limit => 64
    t.boolean  "active",                     :default => true, :null => false
  end

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
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   :default => 0, :null => false
  end

  add_index "events", ["created_at"], :name => "index_events_on_created_at"
  add_index "events", ["creator_id"], :name => "index_events_on_creator_id"
  add_index "events", ["entity_id"], :name => "index_events_on_entity_id"
  add_index "events", ["nature_id"], :name => "index_events_on_nature_id"
  add_index "events", ["responsible_id"], :name => "index_events_on_employee_id"
  add_index "events", ["updated_at"], :name => "index_events_on_updated_at"
  add_index "events", ["updater_id"], :name => "index_events_on_updater_id"

  create_table "financial_years", :force => true do |t|
    t.string   "code",                  :limit => 12,                    :null => false
    t.boolean  "closed",                              :default => false, :null => false
    t.date     "started_on",                                             :null => false
    t.date     "stopped_on",                                             :null => false
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                        :default => 0,     :null => false
    t.string   "currency",              :limit => 3
    t.integer  "currency_precision"
    t.integer  "last_journal_entry_id"
  end

  add_index "financial_years", ["created_at"], :name => "index_financialyears_on_created_at"
  add_index "financial_years", ["creator_id"], :name => "index_financialyears_on_creator_id"
  add_index "financial_years", ["currency"], :name => "index_financial_years_on_currency"
  add_index "financial_years", ["updated_at"], :name => "index_financialyears_on_updated_at"
  add_index "financial_years", ["updater_id"], :name => "index_financialyears_on_updater_id"

  create_table "incident_natures", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "nature"
    t.text     "description"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "incident_natures", ["created_at"], :name => "index_incident_natures_on_created_at"
  add_index "incident_natures", ["creator_id"], :name => "index_incident_natures_on_creator_id"
  add_index "incident_natures", ["updated_at"], :name => "index_incident_natures_on_updated_at"
  add_index "incident_natures", ["updater_id"], :name => "index_incident_natures_on_updater_id"

  create_table "incidents", :force => true do |t|
    t.integer  "target_id",                   :null => false
    t.string   "target_type",                 :null => false
    t.integer  "nature_id",                   :null => false
    t.integer  "watcher_id",                  :null => false
    t.datetime "observed_at",                 :null => false
    t.integer  "priority"
    t.integer  "gravity"
    t.string   "status"
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "incidents", ["created_at"], :name => "index_incidents_on_created_at"
  add_index "incidents", ["creator_id"], :name => "index_incidents_on_creator_id"
  add_index "incidents", ["nature_id"], :name => "index_incidents_on_nature_id"
  add_index "incidents", ["target_id", "target_type"], :name => "index_incidents_on_target_id_and_target_type"
  add_index "incidents", ["updated_at"], :name => "index_incidents_on_updated_at"
  add_index "incidents", ["updater_id"], :name => "index_incidents_on_updater_id"
  add_index "incidents", ["watcher_id"], :name => "index_incidents_on_watcher_id"

  create_table "incoming_deliveries", :force => true do |t|
    t.integer  "purchase_id"
    t.decimal  "pretax_amount",                 :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",                        :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.text     "comment"
    t.integer  "address_id"
    t.date     "planned_on"
    t.date     "moved_on"
    t.decimal  "weight",                        :precision => 19, :scale => 4
    t.datetime "created_at",                                                                    :null => false
    t.datetime "updated_at",                                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                 :default => 0,   :null => false
    t.integer  "mode_id"
    t.string   "number"
    t.string   "reference_number"
    t.string   "currency",         :limit => 3
  end

  add_index "incoming_deliveries", ["created_at"], :name => "index_purchase_deliveries_on_created_at"
  add_index "incoming_deliveries", ["creator_id"], :name => "index_purchase_deliveries_on_creator_id"
  add_index "incoming_deliveries", ["currency"], :name => "index_incoming_deliveries_on_currency"
  add_index "incoming_deliveries", ["updated_at"], :name => "index_purchase_deliveries_on_updated_at"
  add_index "incoming_deliveries", ["updater_id"], :name => "index_purchase_deliveries_on_updater_id"

  create_table "incoming_delivery_items", :force => true do |t|
    t.integer  "delivery_id",                                                      :null => false
    t.integer  "purchase_item_id",                                                 :null => false
    t.integer  "product_id",                                                       :null => false
    t.integer  "price_id",                                                         :null => false
    t.decimal  "quantity",         :precision => 19, :scale => 4, :default => 1.0, :null => false
    t.integer  "unit_id",                                                          :null => false
    t.decimal  "pretax_amount",    :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",           :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "tracking_id"
    t.integer  "warehouse_id"
    t.decimal  "weight",           :precision => 19, :scale => 4
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,   :null => false
    t.integer  "move_id"
  end

  add_index "incoming_delivery_items", ["created_at"], :name => "index_incoming_delivery_items_on_created_at"
  add_index "incoming_delivery_items", ["creator_id"], :name => "index_incoming_delivery_items_on_creator_id"
  add_index "incoming_delivery_items", ["updated_at"], :name => "index_incoming_delivery_items_on_updated_at"
  add_index "incoming_delivery_items", ["updater_id"], :name => "index_incoming_delivery_items_on_updater_id"

  create_table "incoming_delivery_modes", :force => true do |t|
    t.string   "name",                                     :null => false
    t.string   "code",         :limit => 8,                :null => false
    t.text     "comment"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0, :null => false
  end

  add_index "incoming_delivery_modes", ["created_at"], :name => "index_purchase_delivery_modes_on_created_at"
  add_index "incoming_delivery_modes", ["creator_id"], :name => "index_purchase_delivery_modes_on_creator_id"
  add_index "incoming_delivery_modes", ["updated_at"], :name => "index_purchase_delivery_modes_on_updated_at"
  add_index "incoming_delivery_modes", ["updater_id"], :name => "index_purchase_delivery_modes_on_updater_id"

  create_table "incoming_payment_modes", :force => true do |t|
    t.string   "name",                    :limit => 50,                                                   :null => false
    t.integer  "depositables_account_id"
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
    t.decimal  "commission_percentage",                 :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "commission_base_amount",                :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.integer  "commission_account_id"
    t.integer  "position"
    t.integer  "depositables_journal_id"
    t.boolean  "detail_payments",                                                      :default => false, :null => false
    t.integer  "attorney_journal_id"
  end

  add_index "incoming_payment_modes", ["created_at"], :name => "index_payment_modes_on_created_at"
  add_index "incoming_payment_modes", ["creator_id"], :name => "index_payment_modes_on_creator_id"
  add_index "incoming_payment_modes", ["updated_at"], :name => "index_payment_modes_on_updated_at"
  add_index "incoming_payment_modes", ["updater_id"], :name => "index_payment_modes_on_updater_id"

  create_table "incoming_payments", :force => true do |t|
    t.date     "paid_on"
    t.decimal  "amount",                             :precision => 19, :scale => 4,                           :null => false
    t.integer  "mode_id",                                                                                     :null => false
    t.datetime "created_at",                                                                                  :null => false
    t.datetime "updated_at",                                                                                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                      :default => 0,            :null => false
    t.string   "bank"
    t.string   "check_number"
    t.string   "account_number"
    t.integer  "payer_id"
    t.date     "to_bank_on",                                                        :default => '0001-01-01', :null => false
    t.integer  "deposit_id"
    t.integer  "responsible_id"
    t.boolean  "scheduled",                                                         :default => false,        :null => false
    t.boolean  "received",                                                          :default => true,         :null => false
    t.string   "number"
    t.date     "created_on"
    t.datetime "accounted_at"
    t.text     "receipt"
    t.integer  "journal_entry_id"
    t.integer  "commission_account_id"
    t.decimal  "commission_amount",                  :precision => 19, :scale => 4, :default => 0.0,          :null => false
    t.string   "currency",              :limit => 3,                                                          :null => false
    t.boolean  "downpayment",                                                       :default => true,         :null => false
    t.integer  "affair_id"
  end

  add_index "incoming_payments", ["accounted_at"], :name => "index_payments_on_accounted_at"
  add_index "incoming_payments", ["affair_id"], :name => "index_incoming_payments_on_affair_id"
  add_index "incoming_payments", ["created_at"], :name => "index_payments_on_created_at"
  add_index "incoming_payments", ["creator_id"], :name => "index_payments_on_creator_id"
  add_index "incoming_payments", ["updated_at"], :name => "index_payments_on_updated_at"
  add_index "incoming_payments", ["updater_id"], :name => "index_payments_on_updater_id"

  create_table "inventories", :force => true do |t|
    t.date     "created_on",                                     :null => false
    t.text     "comment"
    t.boolean  "changes_reflected"
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

  create_table "inventory_items", :force => true do |t|
    t.integer  "product_id",                                                     :null => false
    t.integer  "warehouse_id",                                                   :null => false
    t.decimal  "theoric_quantity", :precision => 19, :scale => 4,                :null => false
    t.decimal  "quantity",         :precision => 19, :scale => 4,                :null => false
    t.integer  "inventory_id",                                                   :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0, :null => false
    t.integer  "tracking_id"
    t.integer  "unit_id"
    t.integer  "move_id"
  end

  add_index "inventory_items", ["created_at"], :name => "index_inventory_items_on_created_at"
  add_index "inventory_items", ["creator_id"], :name => "index_inventory_items_on_creator_id"
  add_index "inventory_items", ["updated_at"], :name => "index_inventory_items_on_updated_at"
  add_index "inventory_items", ["updater_id"], :name => "index_inventory_items_on_updater_id"

  create_table "journal_entries", :force => true do |t|
    t.integer  "resource_id"
    t.string   "resource_type"
    t.date     "created_on",                                                                                :null => false
    t.date     "printed_on",                                                                                :null => false
    t.string   "number",                                                                                    :null => false
    t.decimal  "debit",                                :precision => 19, :scale => 4,  :default => 0.0,     :null => false
    t.decimal  "credit",                               :precision => 19, :scale => 4,  :default => 0.0,     :null => false
    t.integer  "journal_id",                                                                                :null => false
    t.datetime "created_at",                                                                                :null => false
    t.datetime "updated_at",                                                                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                         :default => 0,       :null => false
    t.decimal  "original_debit",                       :precision => 19, :scale => 4,  :default => 0.0,     :null => false
    t.decimal  "original_credit",                      :precision => 19, :scale => 4,  :default => 0.0,     :null => false
    t.decimal  "original_currency_rate",               :precision => 19, :scale => 10, :default => 0.0,     :null => false
    t.string   "state",                  :limit => 32,                                 :default => "draft", :null => false
    t.decimal  "balance",                              :precision => 19, :scale => 4,  :default => 0.0,     :null => false
    t.string   "original_currency",      :limit => 3
    t.integer  "financial_year_id"
  end

  add_index "journal_entries", ["created_at"], :name => "index_journal_records_on_created_at"
  add_index "journal_entries", ["creator_id"], :name => "index_journal_records_on_creator_id"
  add_index "journal_entries", ["journal_id"], :name => "index_journal_records_on_journal_id"
  add_index "journal_entries", ["original_currency"], :name => "index_journal_entries_on_currency"
  add_index "journal_entries", ["updated_at"], :name => "index_journal_records_on_updated_at"
  add_index "journal_entries", ["updater_id"], :name => "index_journal_records_on_updater_id"

  create_table "journal_entry_items", :force => true do |t|
    t.integer  "entry_id",                                                                            :null => false
    t.integer  "account_id",                                                                          :null => false
    t.string   "name",                                                                                :null => false
    t.decimal  "original_debit",                  :precision => 19, :scale => 4, :default => 0.0,     :null => false
    t.decimal  "original_credit",                 :precision => 19, :scale => 4, :default => 0.0,     :null => false
    t.decimal  "debit",                           :precision => 19, :scale => 4, :default => 0.0,     :null => false
    t.decimal  "credit",                          :precision => 19, :scale => 4, :default => 0.0,     :null => false
    t.integer  "bank_statement_id"
    t.string   "letter",            :limit => 8
    t.integer  "position"
    t.text     "comment"
    t.datetime "created_at",                                                                          :null => false
    t.datetime "updated_at",                                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                   :default => 0,       :null => false
    t.integer  "journal_id"
    t.string   "state",             :limit => 32,                                :default => "draft", :null => false
    t.decimal  "balance",                         :precision => 19, :scale => 4, :default => 0.0,     :null => false
  end

  add_index "journal_entry_items", ["account_id"], :name => "index_journal_entry_items_on_account_id"
  add_index "journal_entry_items", ["bank_statement_id"], :name => "index_journal_entry_items_on_bank_statement_id"
  add_index "journal_entry_items", ["created_at"], :name => "index_journal_entry_items_on_created_at"
  add_index "journal_entry_items", ["creator_id"], :name => "index_journal_entry_items_on_creator_id"
  add_index "journal_entry_items", ["entry_id"], :name => "index_journal_entry_items_on_entry_id"
  add_index "journal_entry_items", ["letter"], :name => "index_journal_entry_items_on_letter"
  add_index "journal_entry_items", ["name"], :name => "index_journal_entry_items_on_name"
  add_index "journal_entry_items", ["updated_at"], :name => "index_journal_entry_items_on_updated_at"
  add_index "journal_entry_items", ["updater_id"], :name => "index_journal_entry_items_on_updater_id"

  create_table "journals", :force => true do |t|
    t.string   "nature",       :limit => 16,                :null => false
    t.string   "name",                                      :null => false
    t.string   "code",         :limit => 4,                 :null => false
    t.date     "closed_on",                                 :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0, :null => false
    t.string   "currency",     :limit => 3
  end

  add_index "journals", ["created_at"], :name => "index_journals_on_created_at"
  add_index "journals", ["creator_id"], :name => "index_journals_on_creator_id"
  add_index "journals", ["currency"], :name => "index_journals_on_currency"
  add_index "journals", ["updated_at"], :name => "index_journals_on_updated_at"
  add_index "journals", ["updater_id"], :name => "index_journals_on_updater_id"

  create_table "listing_node_items", :force => true do |t|
    t.integer  "node_id",                                  :null => false
    t.string   "nature",       :limit => 8,                :null => false
    t.text     "value"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              :default => 0, :null => false
  end

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
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
    t.text     "conditions"
    t.text     "mail"
    t.text     "source"
  end

  add_index "listings", ["created_at"], :name => "index_listings_on_created_at"
  add_index "listings", ["creator_id"], :name => "index_listings_on_creator_id"
  add_index "listings", ["name"], :name => "index_listings_on_name"
  add_index "listings", ["root_model"], :name => "index_listings_on_root_model"
  add_index "listings", ["updated_at"], :name => "index_listings_on_updated_at"
  add_index "listings", ["updater_id"], :name => "index_listings_on_updater_id"

  create_table "logs", :force => true do |t|
    t.string   "event",                        :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.text     "owner_object"
    t.datetime "observed_at",                  :null => false
    t.integer  "origin_id"
    t.string   "origin_type"
    t.text     "origin_object"
    t.text     "description"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",  :default => 0, :null => false
  end

  add_index "logs", ["created_at"], :name => "index_logs_on_created_at"
  add_index "logs", ["creator_id"], :name => "index_logs_on_creator_id"
  add_index "logs", ["description"], :name => "index_logs_on_description"
  add_index "logs", ["observed_at"], :name => "index_logs_on_observed_at"
  add_index "logs", ["origin_type", "origin_id"], :name => "index_logs_on_origin_type_and_origin_id"
  add_index "logs", ["owner_type", "owner_id"], :name => "index_logs_on_owner_type_and_owner_id"
  add_index "logs", ["updated_at"], :name => "index_logs_on_updated_at"
  add_index "logs", ["updater_id"], :name => "index_logs_on_updater_id"

  create_table "mandates", :force => true do |t|
    t.date     "started_on"
    t.date     "stopped_on"
    t.string   "family",                      :null => false
    t.string   "organization",                :null => false
    t.string   "title",                       :null => false
    t.integer  "entity_id",                   :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "mandates", ["created_at"], :name => "index_mandates_on_created_at"
  add_index "mandates", ["creator_id"], :name => "index_mandates_on_creator_id"
  add_index "mandates", ["updated_at"], :name => "index_mandates_on_updated_at"
  add_index "mandates", ["updater_id"], :name => "index_mandates_on_updater_id"

  create_table "observations", :force => true do |t|
    t.string   "importance",   :limit => 10,                :null => false
    t.text     "description",                               :null => false
    t.integer  "entity_id",                                 :null => false
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

  create_table "operation_works", :force => true do |t|
    t.integer  "operation_id",                :null => false
    t.integer  "worker_id",                   :null => false
    t.string   "nature",                      :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "operation_works", ["created_at"], :name => "index_operation_works_on_created_at"
  add_index "operation_works", ["creator_id"], :name => "index_operation_works_on_creator_id"
  add_index "operation_works", ["operation_id"], :name => "index_operation_works_on_operation_id"
  add_index "operation_works", ["updated_at"], :name => "index_operation_works_on_updated_at"
  add_index "operation_works", ["updater_id"], :name => "index_operation_works_on_updater_id"
  add_index "operation_works", ["worker_id"], :name => "index_operation_works_on_worker_id"

  create_table "operations", :force => true do |t|
    t.integer  "target_id",                                                          :null => false
    t.string   "nature",                                                             :null => false
    t.integer  "operand_id"
    t.integer  "operand_unit_id"
    t.decimal  "operand_quantity", :precision => 19, :scale => 4
    t.datetime "started_at",                                                         :null => false
    t.datetime "stopped_at",                                                         :null => false
    t.boolean  "confirmed",                                       :default => false, :null => false
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,     :null => false
  end

  add_index "operations", ["created_at"], :name => "index_operations_on_created_at"
  add_index "operations", ["creator_id"], :name => "index_operations_on_creator_id"
  add_index "operations", ["nature"], :name => "index_operations_on_nature"
  add_index "operations", ["operand_id"], :name => "index_operations_on_operand_id"
  add_index "operations", ["target_id"], :name => "index_operations_on_target_id"
  add_index "operations", ["updated_at"], :name => "index_operations_on_updated_at"
  add_index "operations", ["updater_id"], :name => "index_operations_on_updater_id"

  create_table "outgoing_deliveries", :force => true do |t|
    t.integer  "sale_id",                                                                       :null => false
    t.decimal  "pretax_amount",                 :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",                        :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.text     "comment"
    t.datetime "created_at",                                                                    :null => false
    t.datetime "updated_at",                                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                 :default => 0,   :null => false
    t.integer  "address_id"
    t.date     "planned_on"
    t.date     "moved_on"
    t.integer  "mode_id"
    t.decimal  "weight",                        :precision => 19, :scale => 4
    t.integer  "transport_id"
    t.integer  "transporter_id"
    t.string   "number"
    t.string   "reference_number"
    t.string   "currency",         :limit => 3
  end

  add_index "outgoing_deliveries", ["created_at"], :name => "index_deliveries_on_created_at"
  add_index "outgoing_deliveries", ["creator_id"], :name => "index_deliveries_on_creator_id"
  add_index "outgoing_deliveries", ["currency"], :name => "index_outgoing_deliveries_on_currency"
  add_index "outgoing_deliveries", ["sale_id"], :name => "index_outgoing_deliveries_on_sales_order_id"
  add_index "outgoing_deliveries", ["updated_at"], :name => "index_deliveries_on_updated_at"
  add_index "outgoing_deliveries", ["updater_id"], :name => "index_deliveries_on_updater_id"

  create_table "outgoing_delivery_items", :force => true do |t|
    t.integer  "delivery_id",                                                   :null => false
    t.integer  "sale_item_id",                                                  :null => false
    t.integer  "product_id",                                                    :null => false
    t.integer  "price_id",                                                      :null => false
    t.decimal  "quantity",      :precision => 19, :scale => 4, :default => 1.0, :null => false
    t.integer  "unit_id",                                                       :null => false
    t.decimal  "pretax_amount", :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",        :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                 :default => 0,   :null => false
    t.integer  "tracking_id"
    t.integer  "warehouse_id"
    t.integer  "move_id"
  end

  add_index "outgoing_delivery_items", ["created_at"], :name => "index_outgoing_delivery_items_on_created_at"
  add_index "outgoing_delivery_items", ["creator_id"], :name => "index_outgoing_delivery_items_on_creator_id"
  add_index "outgoing_delivery_items", ["updated_at"], :name => "index_outgoing_delivery_items_on_updated_at"
  add_index "outgoing_delivery_items", ["updater_id"], :name => "index_outgoing_delivery_items_on_updater_id"

  create_table "outgoing_delivery_modes", :force => true do |t|
    t.string   "name",                                           :null => false
    t.string   "code",           :limit => 8,                    :null => false
    t.text     "comment"
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
    t.string   "name",                :limit => 50,                    :null => false
    t.boolean  "with_accounting",                   :default => false, :null => false
    t.integer  "cash_id"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                      :default => 0,     :null => false
    t.integer  "position"
    t.integer  "attorney_journal_id"
  end

  add_index "outgoing_payment_modes", ["created_at"], :name => "index_purchase_payment_modes_on_created_at"
  add_index "outgoing_payment_modes", ["creator_id"], :name => "index_purchase_payment_modes_on_creator_id"
  add_index "outgoing_payment_modes", ["updated_at"], :name => "index_purchase_payment_modes_on_updated_at"
  add_index "outgoing_payment_modes", ["updater_id"], :name => "index_purchase_payment_modes_on_updater_id"

  create_table "outgoing_payments", :force => true do |t|
    t.datetime "accounted_at"
    t.decimal  "amount",                        :precision => 19, :scale => 4, :default => 0.0,  :null => false
    t.string   "check_number"
    t.boolean  "delivered",                                                    :default => true, :null => false
    t.date     "created_on"
    t.integer  "journal_entry_id"
    t.integer  "responsible_id",                                                                 :null => false
    t.integer  "payee_id",                                                                       :null => false
    t.integer  "mode_id",                                                                        :null => false
    t.string   "number"
    t.date     "paid_on"
    t.date     "to_bank_on",                                                                     :null => false
    t.datetime "created_at",                                                                     :null => false
    t.datetime "updated_at",                                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                 :default => 0,    :null => false
    t.string   "currency",         :limit => 3,                                                  :null => false
    t.boolean  "downpayment",                                                  :default => true, :null => false
    t.integer  "affair_id"
  end

  add_index "outgoing_payments", ["affair_id"], :name => "index_outgoing_payments_on_affair_id"
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
    t.decimal  "decimal_value",                  :precision => 19, :scale => 4
    t.integer  "user_id"
    t.datetime "created_at",                                                                     :null => false
    t.datetime "updated_at",                                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                  :default => 0,   :null => false
    t.integer  "record_value_id"
    t.string   "record_value_type"
  end

  add_index "preferences", ["created_at"], :name => "index_parameters_on_created_at"
  add_index "preferences", ["creator_id"], :name => "index_parameters_on_creator_id"
  add_index "preferences", ["name"], :name => "index_parameters_on_name"
  add_index "preferences", ["nature"], :name => "index_parameters_on_nature"
  add_index "preferences", ["updated_at"], :name => "index_parameters_on_updated_at"
  add_index "preferences", ["updater_id"], :name => "index_parameters_on_updater_id"
  add_index "preferences", ["user_id"], :name => "index_parameters_on_user_id"

  create_table "prices", :force => true do |t|
    t.decimal  "pretax_amount",                  :precision => 19, :scale => 4,                   :null => false
    t.decimal  "amount",                         :precision => 19, :scale => 4,                   :null => false
    t.integer  "product_nature_id",                                                               :null => false
    t.integer  "tax_id",                                                                          :null => false
    t.datetime "created_at",                                                                      :null => false
    t.datetime "updated_at",                                                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                  :default => 0,    :null => false
    t.integer  "entity_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.boolean  "active",                                                        :default => true, :null => false
    t.boolean  "by_default",                                                    :default => true
    t.integer  "category_id"
    t.string   "currency",          :limit => 3
  end

  add_index "prices", ["created_at"], :name => "index_prices_on_created_at"
  add_index "prices", ["creator_id"], :name => "index_prices_on_creator_id"
  add_index "prices", ["currency"], :name => "index_prices_on_currency"
  add_index "prices", ["product_nature_id"], :name => "index_prices_on_product_id"
  add_index "prices", ["updated_at"], :name => "index_prices_on_updated_at"
  add_index "prices", ["updater_id"], :name => "index_prices_on_updater_id"

  create_table "product_groups", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "description"
    t.text     "comment"
    t.string   "color"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth",        :default => 0, :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "product_groups", ["created_at"], :name => "index_product_groups_on_created_at"
  add_index "product_groups", ["creator_id"], :name => "index_product_groups_on_creator_id"
  add_index "product_groups", ["lft"], :name => "index_product_groups_on_lft"
  add_index "product_groups", ["parent_id"], :name => "index_product_groups_on_parent_id"
  add_index "product_groups", ["rgt"], :name => "index_product_groups_on_rgt"
  add_index "product_groups", ["updated_at"], :name => "index_product_groups_on_updated_at"
  add_index "product_groups", ["updater_id"], :name => "index_product_groups_on_updater_id"

  create_table "product_indicator_nature_choices", :force => true do |t|
    t.integer  "nature_id",                   :null => false
    t.string   "name",                        :null => false
    t.string   "value"
    t.integer  "position"
    t.string   "comment"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "product_indicator_nature_choices", ["created_at"], :name => "index_product_indicator_nature_choices_on_created_at"
  add_index "product_indicator_nature_choices", ["creator_id"], :name => "index_product_indicator_nature_choices_on_creator_id"
  add_index "product_indicator_nature_choices", ["nature_id"], :name => "index_product_indicator_nature_choices_on_nature_id"
  add_index "product_indicator_nature_choices", ["updated_at"], :name => "index_product_indicator_nature_choices_on_updated_at"
  add_index "product_indicator_nature_choices", ["updater_id"], :name => "index_product_indicator_nature_choices_on_updater_id"

  create_table "product_indicator_natures", :force => true do |t|
    t.integer  "process_id",                                                       :null => false
    t.integer  "unit_id"
    t.string   "name",                                                             :null => false
    t.string   "nature"
    t.string   "usage"
    t.integer  "minimal_length"
    t.integer  "maximal_length"
    t.decimal  "minimal_value",  :precision => 19, :scale => 4
    t.decimal  "maximal_value",  :precision => 19, :scale => 4
    t.boolean  "active",                                        :default => false, :null => false
    t.string   "comment"
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                  :default => 0,     :null => false
  end

  add_index "product_indicator_natures", ["created_at"], :name => "index_product_indicator_natures_on_created_at"
  add_index "product_indicator_natures", ["creator_id"], :name => "index_product_indicator_natures_on_creator_id"
  add_index "product_indicator_natures", ["process_id"], :name => "index_product_indicator_natures_on_process_id"
  add_index "product_indicator_natures", ["unit_id"], :name => "index_product_indicator_natures_on_unit_id"
  add_index "product_indicator_natures", ["updated_at"], :name => "index_product_indicator_natures_on_updated_at"
  add_index "product_indicator_natures", ["updater_id"], :name => "index_product_indicator_natures_on_updater_id"

  create_table "product_indicators", :force => true do |t|
    t.integer  "product_id",                                                        :null => false
    t.integer  "nature_id",                                                         :null => false
    t.datetime "measured_at",                                                       :null => false
    t.string   "comment"
    t.decimal  "decimal_value",   :precision => 19, :scale => 4
    t.decimal  "measure_value",   :precision => 19, :scale => 4
    t.integer  "measure_unit_id"
    t.text     "string_value"
    t.boolean  "boolean_value",                                  :default => false, :null => false
    t.integer  "choice_value_id"
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                   :default => 0,     :null => false
  end

  add_index "product_indicators", ["choice_value_id"], :name => "index_product_indicators_on_choice_value_id"
  add_index "product_indicators", ["created_at"], :name => "index_product_indicators_on_created_at"
  add_index "product_indicators", ["creator_id"], :name => "index_product_indicators_on_creator_id"
  add_index "product_indicators", ["measure_unit_id"], :name => "index_product_indicators_on_measure_unit_id"
  add_index "product_indicators", ["nature_id"], :name => "index_product_indicators_on_nature_id"
  add_index "product_indicators", ["product_id"], :name => "index_product_indicators_on_product_id"
  add_index "product_indicators", ["updated_at"], :name => "index_product_indicators_on_updated_at"
  add_index "product_indicators", ["updater_id"], :name => "index_product_indicators_on_updater_id"

  create_table "product_localizations", :force => true do |t|
    t.integer  "transfer_id",                 :null => false
    t.integer  "product_id",                  :null => false
    t.integer  "container_id"
    t.string   "nature",                      :null => false
    t.datetime "started_at",                  :null => false
    t.datetime "stopped_at",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "product_localizations", ["container_id"], :name => "index_product_localizations_on_container_id"
  add_index "product_localizations", ["created_at"], :name => "index_product_localizations_on_created_at"
  add_index "product_localizations", ["creator_id"], :name => "index_product_localizations_on_creator_id"
  add_index "product_localizations", ["product_id"], :name => "index_product_localizations_on_product_id"
  add_index "product_localizations", ["started_at"], :name => "index_product_localizations_on_started_at"
  add_index "product_localizations", ["stopped_at"], :name => "index_product_localizations_on_stopped_at"
  add_index "product_localizations", ["updated_at"], :name => "index_product_localizations_on_updated_at"
  add_index "product_localizations", ["updater_id"], :name => "index_product_localizations_on_updater_id"

  create_table "product_memberships", :force => true do |t|
    t.integer  "product_id",                  :null => false
    t.integer  "group_id",                    :null => false
    t.datetime "started_at",                  :null => false
    t.datetime "stopped_at",                  :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "product_memberships", ["created_at"], :name => "index_product_memberships_on_created_at"
  add_index "product_memberships", ["creator_id"], :name => "index_product_memberships_on_creator_id"
  add_index "product_memberships", ["group_id"], :name => "index_product_memberships_on_group_id"
  add_index "product_memberships", ["product_id"], :name => "index_product_memberships_on_product_id"
  add_index "product_memberships", ["started_at"], :name => "index_product_memberships_on_started_at"
  add_index "product_memberships", ["stopped_at"], :name => "index_product_memberships_on_stopped_at"
  add_index "product_memberships", ["updated_at"], :name => "index_product_memberships_on_updated_at"
  add_index "product_memberships", ["updater_id"], :name => "index_product_memberships_on_updater_id"

  create_table "product_moves", :force => true do |t|
    t.integer  "product_id",                                                     :null => false
    t.decimal  "quantity",     :precision => 19, :scale => 4,                    :null => false
    t.integer  "unit_id",                                                        :null => false
    t.datetime "started_at",                                                     :null => false
    t.datetime "stopped_at",                                                     :null => false
    t.string   "mode",                                                           :null => false
    t.integer  "origin_id"
    t.string   "origin_type"
    t.boolean  "last_done",                                   :default => false, :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                :default => 0,     :null => false
  end

  add_index "product_moves", ["created_at"], :name => "index_product_moves_on_created_at"
  add_index "product_moves", ["creator_id"], :name => "index_product_moves_on_creator_id"
  add_index "product_moves", ["mode"], :name => "index_product_moves_on_mode"
  add_index "product_moves", ["origin_id", "origin_type", "last_done"], :name => "index_product_moves_on_origin_id_and_origin_type_and_last_done"
  add_index "product_moves", ["origin_id", "origin_type"], :name => "index_product_moves_on_origin_id_and_origin_type"
  add_index "product_moves", ["product_id"], :name => "index_product_moves_on_product_id"
  add_index "product_moves", ["started_at"], :name => "index_product_moves_on_started_at"
  add_index "product_moves", ["stopped_at"], :name => "index_product_moves_on_stopped_at"
  add_index "product_moves", ["updated_at"], :name => "index_product_moves_on_updated_at"
  add_index "product_moves", ["updater_id"], :name => "index_product_moves_on_updater_id"

  create_table "product_nature_categories", :force => true do |t|
    t.string   "name",                                   :null => false
    t.string   "catalog_name",                           :null => false
    t.text     "catalog_description"
    t.text     "comment"
    t.integer  "parent_id"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",        :default => 0,     :null => false
    t.boolean  "published",           :default => false, :null => false
  end

  add_index "product_nature_categories", ["created_at"], :name => "index_product_nature_categories_on_created_at"
  add_index "product_nature_categories", ["creator_id"], :name => "index_product_nature_categories_on_creator_id"
  add_index "product_nature_categories", ["parent_id"], :name => "index_product_nature_categories_on_parent_id"
  add_index "product_nature_categories", ["updated_at"], :name => "index_product_nature_categories_on_updated_at"
  add_index "product_nature_categories", ["updater_id"], :name => "index_product_nature_categories_on_updater_id"

  create_table "product_nature_components", :force => true do |t|
    t.string   "name",                                                            :null => false
    t.integer  "product_nature_id",                                               :null => false
    t.integer  "component_id",                                                    :null => false
    t.decimal  "quantity",          :precision => 19, :scale => 4,                :null => false
    t.text     "comment"
    t.boolean  "active",                                                          :null => false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0, :null => false
  end

  add_index "product_nature_components", ["created_at"], :name => "index_product_nature_components_on_created_at"
  add_index "product_nature_components", ["creator_id"], :name => "index_product_nature_components_on_creator_id"
  add_index "product_nature_components", ["updated_at"], :name => "index_product_nature_components_on_updated_at"
  add_index "product_nature_components", ["updater_id"], :name => "index_product_nature_components_on_updater_id"

  create_table "product_natures", :force => true do |t|
    t.string   "name",                                                    :null => false
    t.string   "number",                 :limit => 32,                    :null => false
    t.integer  "unit_id",                                                 :null => false
    t.text     "description"
    t.text     "comment"
    t.string   "commercial_name",                                         :null => false
    t.text     "commercial_description"
    t.integer  "variety_id",                                              :null => false
    t.integer  "category_id",                                             :null => false
    t.boolean  "active",                               :default => false, :null => false
    t.boolean  "alive",                                :default => false, :null => false
    t.boolean  "depreciable",                          :default => false, :null => false
    t.boolean  "saleable",                             :default => false, :null => false
    t.boolean  "purchasable",                          :default => false, :null => false
    t.boolean  "producible",                           :default => false, :null => false
    t.boolean  "deliverable",                          :default => false, :null => false
    t.boolean  "storable",                             :default => false, :null => false
    t.boolean  "storage",                              :default => false, :null => false
    t.boolean  "towable",                              :default => false, :null => false
    t.boolean  "tractive",                             :default => false, :null => false
    t.boolean  "traceable",                            :default => false, :null => false
    t.boolean  "transferable",                         :default => false, :null => false
    t.boolean  "reductible",                           :default => false, :null => false
    t.boolean  "indivisible",                          :default => false, :null => false
    t.boolean  "subscribing",                          :default => false, :null => false
    t.integer  "subscription_nature_id"
    t.string   "subscription_duration"
    t.integer  "charge_account_id"
    t.integer  "product_account_id"
    t.integer  "asset_account_id"
    t.integer  "stock_account_id"
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                         :default => 0,     :null => false
  end

  add_index "product_natures", ["asset_account_id"], :name => "index_product_natures_on_asset_account_id"
  add_index "product_natures", ["category_id"], :name => "index_product_natures_on_category_id"
  add_index "product_natures", ["charge_account_id"], :name => "index_product_natures_on_charge_account_id"
  add_index "product_natures", ["created_at"], :name => "index_product_natures_on_created_at"
  add_index "product_natures", ["creator_id"], :name => "index_product_natures_on_creator_id"
  add_index "product_natures", ["number"], :name => "index_product_natures_on_number", :unique => true
  add_index "product_natures", ["product_account_id"], :name => "index_product_natures_on_product_account_id"
  add_index "product_natures", ["stock_account_id"], :name => "index_product_natures_on_stock_account_id"
  add_index "product_natures", ["subscription_nature_id"], :name => "index_product_natures_on_subscription_nature_id"
  add_index "product_natures", ["updated_at"], :name => "index_product_natures_on_updated_at"
  add_index "product_natures", ["updater_id"], :name => "index_product_natures_on_updater_id"
  add_index "product_natures", ["variety_id"], :name => "index_product_natures_on_variety_id"

  create_table "product_process_phases", :force => true do |t|
    t.integer  "process_id"
    t.string   "name"
    t.integer  "position"
    t.string   "phase_delay"
    t.string   "nature"
    t.string   "comment"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "product_process_phases", ["created_at"], :name => "index_product_process_phases_on_created_at"
  add_index "product_process_phases", ["creator_id"], :name => "index_product_process_phases_on_creator_id"
  add_index "product_process_phases", ["process_id"], :name => "index_product_process_phases_on_process_id"
  add_index "product_process_phases", ["updated_at"], :name => "index_product_process_phases_on_updated_at"
  add_index "product_process_phases", ["updater_id"], :name => "index_product_process_phases_on_updater_id"

  create_table "product_processes", :force => true do |t|
    t.integer  "variety_id",                      :null => false
    t.string   "name",                            :null => false
    t.string   "nature"
    t.string   "comment"
    t.boolean  "repeatable",   :default => false, :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0,     :null => false
  end

  add_index "product_processes", ["created_at"], :name => "index_product_processes_on_created_at"
  add_index "product_processes", ["creator_id"], :name => "index_product_processes_on_creator_id"
  add_index "product_processes", ["updated_at"], :name => "index_product_processes_on_updated_at"
  add_index "product_processes", ["updater_id"], :name => "index_product_processes_on_updater_id"
  add_index "product_processes", ["variety_id"], :name => "index_product_processes_on_variety_id"

  create_table "product_transfers", :force => true do |t|
    t.integer  "product_id",                    :null => false
    t.integer  "origin_id"
    t.integer  "destination_id"
    t.datetime "started_at",                    :null => false
    t.datetime "stopped_at",                    :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   :default => 0, :null => false
  end

  add_index "product_transfers", ["created_at"], :name => "index_product_transfers_on_created_at"
  add_index "product_transfers", ["creator_id"], :name => "index_product_transfers_on_creator_id"
  add_index "product_transfers", ["destination_id"], :name => "index_product_transfers_on_destination_id"
  add_index "product_transfers", ["origin_id"], :name => "index_product_transfers_on_origin_id"
  add_index "product_transfers", ["product_id"], :name => "index_product_transfers_on_product_id"
  add_index "product_transfers", ["updated_at"], :name => "index_product_transfers_on_updated_at"
  add_index "product_transfers", ["updater_id"], :name => "index_product_transfers_on_updater_id"

  create_table "product_varieties", :force => true do |t|
    t.string   "name",                            :null => false
    t.text     "description"
    t.text     "comment"
    t.string   "product_type",                    :null => false
    t.string   "code"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth",        :default => 0,     :null => false
    t.boolean  "automatic",    :default => false, :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0,     :null => false
  end

  add_index "product_varieties", ["code"], :name => "index_product_varieties_on_code", :unique => true
  add_index "product_varieties", ["created_at"], :name => "index_product_varieties_on_created_at"
  add_index "product_varieties", ["creator_id"], :name => "index_product_varieties_on_creator_id"
  add_index "product_varieties", ["lft"], :name => "index_product_varieties_on_lft"
  add_index "product_varieties", ["parent_id"], :name => "index_product_varieties_on_parent_id"
  add_index "product_varieties", ["rgt"], :name => "index_product_varieties_on_rgt"
  add_index "product_varieties", ["updated_at"], :name => "index_product_varieties_on_updated_at"
  add_index "product_varieties", ["updater_id"], :name => "index_product_varieties_on_updater_id"

  create_table "production_chain_conveyors", :force => true do |t|
    t.integer  "production_chain_id",                                                   :null => false
    t.integer  "product_nature_id",                                                     :null => false
    t.integer  "unit_id",                                                               :null => false
    t.decimal  "flow",                :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.boolean  "check_state",                                        :default => false, :null => false
    t.integer  "source_id"
    t.decimal  "source_quantity",     :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.boolean  "unique_tracking",                                    :default => false, :null => false
    t.integer  "target_id"
    t.decimal  "target_quantity",     :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.text     "comment"
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                       :default => 0,     :null => false
  end

  add_index "production_chain_conveyors", ["created_at"], :name => "index_production_chain_conveyors_on_created_at"
  add_index "production_chain_conveyors", ["creator_id"], :name => "index_production_chain_conveyors_on_creator_id"
  add_index "production_chain_conveyors", ["updated_at"], :name => "index_production_chain_conveyors_on_updated_at"
  add_index "production_chain_conveyors", ["updater_id"], :name => "index_production_chain_conveyors_on_updater_id"

  create_table "production_chain_work_center_uses", :force => true do |t|
    t.integer  "work_center_id",                :null => false
    t.integer  "tool_id",                       :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   :default => 0, :null => false
  end

  add_index "production_chain_work_center_uses", ["created_at"], :name => "index_production_chain_work_center_uses_on_created_at"
  add_index "production_chain_work_center_uses", ["creator_id"], :name => "index_production_chain_work_center_uses_on_creator_id"
  add_index "production_chain_work_center_uses", ["updated_at"], :name => "index_production_chain_work_center_uses_on_updated_at"
  add_index "production_chain_work_center_uses", ["updater_id"], :name => "index_production_chain_work_center_uses_on_updater_id"

  create_table "production_chain_work_centers", :force => true do |t|
    t.integer  "production_chain_id",                :null => false
    t.integer  "operation_nature_id",                :null => false
    t.string   "name",                               :null => false
    t.string   "nature",                             :null => false
    t.integer  "building_id",                        :null => false
    t.text     "comment"
    t.integer  "position"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",        :default => 0, :null => false
  end

  add_index "production_chain_work_centers", ["created_at"], :name => "index_production_chain_work_centers_on_created_at"
  add_index "production_chain_work_centers", ["creator_id"], :name => "index_production_chain_work_centers_on_creator_id"
  add_index "production_chain_work_centers", ["updated_at"], :name => "index_production_chain_work_centers_on_updated_at"
  add_index "production_chain_work_centers", ["updater_id"], :name => "index_production_chain_work_centers_on_updater_id"

  create_table "production_chains", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "comment"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "production_chains", ["created_at"], :name => "index_production_chains_on_created_at"
  add_index "production_chains", ["creator_id"], :name => "index_production_chains_on_creator_id"
  add_index "production_chains", ["updated_at"], :name => "index_production_chains_on_updated_at"
  add_index "production_chains", ["updater_id"], :name => "index_production_chains_on_updater_id"

  create_table "products", :force => true do |t|
    t.string   "type",                                                                                                                :null => false
    t.string   "name",                                                                                                                :null => false
    t.string   "number",                                                                                                              :null => false
    t.boolean  "active",                                                                                           :default => false, :null => false
    t.integer  "variety_id",                                                                                                          :null => false
    t.integer  "nature_id",                                                                                                           :null => false
    t.integer  "unit_id",                                                                                                             :null => false
    t.integer  "tracking_id"
    t.integer  "tractor_id"
    t.integer  "asset_id"
    t.integer  "current_place_id"
    t.datetime "born_at"
    t.datetime "dead_at"
    t.text     "description"
    t.text     "comment"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.decimal  "minimal_quantity",                                                  :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "maximal_quantity",                                                  :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "real_quantity",                                                     :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "virtual_quantity",                                                  :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.boolean  "external",                                                                                         :default => false, :null => false
    t.integer  "owner_id",                                                                                                            :null => false
    t.string   "sex"
    t.string   "identification_number"
    t.string   "work_number"
    t.boolean  "reproductor",                                                                                      :default => false, :null => false
    t.integer  "father_id"
    t.integer  "mother_id"
    t.integer  "address_id"
    t.decimal  "area_measure",                                                      :precision => 19, :scale => 4
    t.integer  "area_unit_id"
    t.boolean  "reservoir",                                                                                        :default => false, :null => false
    t.integer  "content_nature_id"
    t.integer  "content_unit_id"
    t.decimal  "content_maximal_quantity",                                          :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.integer  "parent_place_id"
    t.datetime "created_at",                                                                                                          :null => false
    t.datetime "updated_at",                                                                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                                     :default => 0,     :null => false
    t.spatial  "shape",                    :limit => {:srid=>0, :type=>"geometry"}
  end

  add_index "products", ["address_id"], :name => "index_products_on_address_id"
  add_index "products", ["area_unit_id"], :name => "index_products_on_area_unit_id"
  add_index "products", ["asset_id"], :name => "index_products_on_asset_id"
  add_index "products", ["content_nature_id"], :name => "index_products_on_content_nature_id"
  add_index "products", ["content_unit_id"], :name => "index_products_on_content_unit_id"
  add_index "products", ["created_at"], :name => "index_products_on_created_at"
  add_index "products", ["creator_id"], :name => "index_products_on_creator_id"
  add_index "products", ["father_id"], :name => "index_products_on_father_id"
  add_index "products", ["mother_id"], :name => "index_products_on_mother_id"
  add_index "products", ["nature_id"], :name => "index_products_on_nature_id"
  add_index "products", ["number"], :name => "index_products_on_number", :unique => true
  add_index "products", ["owner_id"], :name => "index_products_on_owner_id"
  add_index "products", ["parent_place_id"], :name => "index_products_on_parent_place_id"
  add_index "products", ["tracking_id"], :name => "index_products_on_tracking_id"
  add_index "products", ["tractor_id"], :name => "index_products_on_tractor_id"
  add_index "products", ["type"], :name => "index_products_on_type"
  add_index "products", ["unit_id"], :name => "index_products_on_unit_id"
  add_index "products", ["updated_at"], :name => "index_products_on_updated_at"
  add_index "products", ["updater_id"], :name => "index_products_on_updater_id"
  add_index "products", ["variety_id"], :name => "index_products_on_variety_id"

  create_table "professions", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "code"
    t.string   "rome"
    t.boolean  "commercial"
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

  create_table "purchase_items", :force => true do |t|
    t.integer  "purchase_id",                                                     :null => false
    t.integer  "product_id",                                                      :null => false
    t.integer  "unit_id",                                                         :null => false
    t.integer  "price_id",                                                        :null => false
    t.decimal  "quantity",        :precision => 19, :scale => 4, :default => 1.0, :null => false
    t.decimal  "pretax_amount",   :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",          :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "position"
    t.integer  "account_id",                                                      :null => false
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

  add_index "purchase_items", ["created_at"], :name => "index_purchase_items_on_created_at"
  add_index "purchase_items", ["creator_id"], :name => "index_purchase_items_on_creator_id"
  add_index "purchase_items", ["updated_at"], :name => "index_purchase_items_on_updated_at"
  add_index "purchase_items", ["updater_id"], :name => "index_purchase_items_on_updater_id"

  create_table "purchase_natures", :force => true do |t|
    t.boolean  "active",                       :default => false, :null => false
    t.string   "name"
    t.text     "comment"
    t.string   "currency",        :limit => 3
    t.boolean  "with_accounting",              :default => false, :null => false
    t.integer  "journal_id"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                 :default => 0,     :null => false
  end

  add_index "purchase_natures", ["created_at"], :name => "index_purchase_natures_on_created_at"
  add_index "purchase_natures", ["creator_id"], :name => "index_purchase_natures_on_creator_id"
  add_index "purchase_natures", ["currency"], :name => "index_purchase_natures_on_currency"
  add_index "purchase_natures", ["journal_id"], :name => "index_purchase_natures_on_journal_id"
  add_index "purchase_natures", ["updated_at"], :name => "index_purchase_natures_on_updated_at"
  add_index "purchase_natures", ["updater_id"], :name => "index_purchase_natures_on_updater_id"

  create_table "purchases", :force => true do |t|
    t.integer  "supplier_id",                                                                       :null => false
    t.string   "number",              :limit => 64,                                                 :null => false
    t.decimal  "pretax_amount",                     :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",                            :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "delivery_address_id"
    t.text     "comment"
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                     :default => 0,   :null => false
    t.date     "planned_on"
    t.date     "invoiced_on"
    t.date     "created_on"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.string   "reference_number"
    t.string   "state",               :limit => 64
    t.date     "confirmed_on"
    t.integer  "responsible_id"
    t.string   "currency",            :limit => 3
    t.integer  "nature_id"
    t.integer  "affair_id"
  end

  add_index "purchases", ["accounted_at"], :name => "index_purchase_orders_on_accounted_at"
  add_index "purchases", ["affair_id"], :name => "index_purchases_on_affair_id"
  add_index "purchases", ["created_at"], :name => "index_purchase_orders_on_created_at"
  add_index "purchases", ["creator_id"], :name => "index_purchase_orders_on_creator_id"
  add_index "purchases", ["currency"], :name => "index_purchases_on_currency"
  add_index "purchases", ["updated_at"], :name => "index_purchase_orders_on_updated_at"
  add_index "purchases", ["updater_id"], :name => "index_purchase_orders_on_updater_id"

  create_table "roles", :force => true do |t|
    t.string   "name",                        :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
    t.text     "rights"
  end

  add_index "roles", ["created_at"], :name => "index_roles_on_created_at"
  add_index "roles", ["creator_id"], :name => "index_roles_on_creator_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"
  add_index "roles", ["updated_at"], :name => "index_roles_on_updated_at"
  add_index "roles", ["updater_id"], :name => "index_roles_on_updater_id"

  create_table "sale_items", :force => true do |t|
    t.integer  "sale_id",                                                              :null => false
    t.integer  "product_id",                                                           :null => false
    t.integer  "price_id",                                                             :null => false
    t.decimal  "quantity",             :precision => 19, :scale => 4, :default => 1.0, :null => false
    t.integer  "unit_id"
    t.decimal  "pretax_amount",        :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",               :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "position"
    t.integer  "account_id"
    t.datetime "created_at",                                                           :null => false
    t.datetime "updated_at",                                                           :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                        :default => 0,   :null => false
    t.integer  "warehouse_id"
    t.decimal  "price_amount",         :precision => 19, :scale => 4
    t.integer  "tax_id"
    t.text     "annotation"
    t.integer  "entity_id"
    t.integer  "reduction_origin_id"
    t.text     "label"
    t.integer  "tracking_id"
    t.decimal  "reduction_percentage", :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "origin_id"
  end

  add_index "sale_items", ["created_at"], :name => "index_sale_items_on_created_at"
  add_index "sale_items", ["creator_id"], :name => "index_sale_items_on_creator_id"
  add_index "sale_items", ["reduction_origin_id"], :name => "index_sale_items_on_reduction_origin_id"
  add_index "sale_items", ["updated_at"], :name => "index_sale_items_on_updated_at"
  add_index "sale_items", ["updater_id"], :name => "index_sale_items_on_updater_id"

  create_table "sale_natures", :force => true do |t|
    t.string   "name",                                                                                   :null => false
    t.boolean  "active",                                                              :default => true,  :null => false
    t.boolean  "downpayment",                                                         :default => false, :null => false
    t.decimal  "downpayment_minimum",                  :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "downpayment_percentage",               :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.text     "comment"
    t.datetime "created_at",                                                                             :null => false
    t.datetime "updated_at",                                                                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                        :default => 0,     :null => false
    t.integer  "payment_mode_id"
    t.text     "payment_mode_complement"
    t.boolean  "with_accounting",                                                     :default => false, :null => false
    t.string   "currency",                :limit => 3
    t.integer  "journal_id"
    t.text     "sales_conditions"
    t.string   "expiration_delay",                                                                       :null => false
    t.string   "payment_delay",                                                                          :null => false
  end

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
    t.decimal  "pretax_amount",                     :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "amount",                            :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.string   "state",               :limit => 64,                                :default => "O",   :null => false
    t.date     "expired_on"
    t.boolean  "has_downpayment",                                                  :default => false, :null => false
    t.decimal  "downpayment_amount",                :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.integer  "address_id"
    t.integer  "invoice_address_id"
    t.integer  "delivery_address_id"
    t.string   "subject"
    t.string   "function_title"
    t.text     "introduction"
    t.text     "conclusion"
    t.text     "comment"
    t.datetime "created_at",                                                                          :null => false
    t.datetime "updated_at",                                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                     :default => 0,     :null => false
    t.date     "confirmed_on"
    t.integer  "responsible_id"
    t.boolean  "letter_format",                                                    :default => true,  :null => false
    t.text     "annotation"
    t.integer  "transporter_id"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.string   "reference_number"
    t.date     "invoiced_on"
    t.boolean  "credit",                                                           :default => false, :null => false
    t.date     "payment_on"
    t.integer  "origin_id"
    t.string   "initial_number",      :limit => 64
    t.string   "currency",            :limit => 3
    t.integer  "affair_id"
    t.string   "expiration_delay"
    t.string   "payment_delay",                                                                       :null => false
  end

  add_index "sales", ["accounted_at"], :name => "index_sale_orders_on_accounted_at"
  add_index "sales", ["affair_id"], :name => "index_sales_on_affair_id"
  add_index "sales", ["created_at"], :name => "index_sale_orders_on_created_at"
  add_index "sales", ["creator_id"], :name => "index_sale_orders_on_creator_id"
  add_index "sales", ["currency"], :name => "index_sales_on_currency"
  add_index "sales", ["updated_at"], :name => "index_sale_orders_on_updated_at"
  add_index "sales", ["updater_id"], :name => "index_sale_orders_on_updater_id"

  create_table "sequences", :force => true do |t|
    t.string   "name",                                   :null => false
    t.string   "number_format",                          :null => false
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
    t.string   "usage"
  end

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

  create_table "subscription_natures", :force => true do |t|
    t.string   "name",                                                                             :null => false
    t.integer  "actual_number"
    t.string   "nature",                :limit => 8,                                               :null => false
    t.text     "comment"
    t.datetime "created_at",                                                                       :null => false
    t.datetime "updated_at",                                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                      :default => 0, :null => false
    t.decimal  "reduction_percentage",               :precision => 19, :scale => 4
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
    t.integer  "product_nature_id"
    t.integer  "address_id"
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,     :null => false
    t.decimal  "quantity",          :precision => 19, :scale => 4
    t.boolean  "suspended",                                        :default => false, :null => false
    t.integer  "nature_id"
    t.integer  "entity_id"
    t.text     "comment"
    t.string   "number"
    t.integer  "sale_item_id"
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
    t.decimal  "collected_amount",         :precision => 19, :scale => 4
    t.decimal  "paid_amount",              :precision => 19, :scale => 4
    t.decimal  "balance_amount",           :precision => 19, :scale => 4
    t.boolean  "deferred_payment",                                        :default => false
    t.decimal  "assimilated_taxes_amount", :precision => 19, :scale => 4
    t.decimal  "acquisition_amount",       :precision => 19, :scale => 4
    t.decimal  "amount",                   :precision => 19, :scale => 4
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

  add_index "tax_declarations", ["created_at"], :name => "index_tax_declarations_on_created_at"
  add_index "tax_declarations", ["creator_id"], :name => "index_tax_declarations_on_creator_id"
  add_index "tax_declarations", ["updated_at"], :name => "index_tax_declarations_on_updated_at"
  add_index "tax_declarations", ["updater_id"], :name => "index_tax_declarations_on_updater_id"

  create_table "taxes", :force => true do |t|
    t.string   "name",                                                                                 :null => false
    t.boolean  "included",                                                          :default => false, :null => false
    t.boolean  "reductible",                                                        :default => true,  :null => false
    t.string   "nature",               :limit => 16,                                                   :null => false
    t.decimal  "amount",                             :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.text     "description"
    t.integer  "collected_account_id"
    t.integer  "paid_account_id"
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                      :default => 0,     :null => false
  end

  add_index "taxes", ["collected_account_id"], :name => "index_taxes_on_account_collected_id"
  add_index "taxes", ["created_at"], :name => "index_taxes_on_created_at"
  add_index "taxes", ["creator_id"], :name => "index_taxes_on_creator_id"
  add_index "taxes", ["paid_account_id"], :name => "index_taxes_on_account_paid_id"
  add_index "taxes", ["updated_at"], :name => "index_taxes_on_updated_at"
  add_index "taxes", ["updater_id"], :name => "index_taxes_on_updater_id"

  create_table "trackings", :force => true do |t|
    t.string   "name",                           :null => false
    t.string   "serial"
    t.boolean  "active",       :default => true, :null => false
    t.text     "comment"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0,    :null => false
    t.integer  "product_id"
    t.integer  "producer_id"
  end

  add_index "trackings", ["created_at"], :name => "index_stock_trackings_on_created_at"
  add_index "trackings", ["creator_id"], :name => "index_stock_trackings_on_creator_id"
  add_index "trackings", ["updated_at"], :name => "index_stock_trackings_on_updated_at"
  add_index "trackings", ["updater_id"], :name => "index_stock_trackings_on_updater_id"

  create_table "transfers", :force => true do |t|
    t.decimal  "amount",                        :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "supplier_id"
    t.string   "label"
    t.string   "comment"
    t.date     "started_on"
    t.date     "stopped_on"
    t.datetime "created_at",                                                                    :null => false
    t.datetime "updated_at",                                                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                 :default => 0,   :null => false
    t.date     "created_on"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.string   "currency",         :limit => 3,                                                 :null => false
    t.integer  "affair_id"
  end

  add_index "transfers", ["accounted_at"], :name => "index_transfers_on_accounted_at"
  add_index "transfers", ["affair_id"], :name => "index_transfers_on_affair_id"
  add_index "transfers", ["created_at"], :name => "index_transfers_on_created_at"
  add_index "transfers", ["creator_id"], :name => "index_transfers_on_creator_id"
  add_index "transfers", ["updated_at"], :name => "index_transfers_on_updated_at"
  add_index "transfers", ["updater_id"], :name => "index_transfers_on_updater_id"

  create_table "transports", :force => true do |t|
    t.integer  "transporter_id",                                                   :null => false
    t.integer  "responsible_id"
    t.decimal  "weight",           :precision => 19, :scale => 4
    t.date     "created_on"
    t.date     "transport_on"
    t.text     "comment"
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    :default => 0,   :null => false
    t.string   "number"
    t.string   "reference_number"
    t.integer  "purchase_id"
    t.decimal  "pretax_amount",    :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",           :precision => 19, :scale => 4, :default => 0.0, :null => false
  end

  add_index "transports", ["created_at"], :name => "index_transports_on_created_at"
  add_index "transports", ["creator_id"], :name => "index_transports_on_creator_id"
  add_index "transports", ["updated_at"], :name => "index_transports_on_updated_at"
  add_index "transports", ["updater_id"], :name => "index_transports_on_updater_id"

  create_table "units", :force => true do |t|
    t.string   "name",         :limit => 8,                                                  :null => false
    t.string   "label",                                                                      :null => false
    t.string   "base"
    t.decimal  "coefficient",               :precision => 19, :scale => 10, :default => 1.0, :null => false
    t.datetime "created_at",                                                                 :null => false
    t.datetime "updated_at",                                                                 :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                              :default => 0,   :null => false
    t.decimal  "start",                     :precision => 19, :scale => 4,  :default => 0.0, :null => false
  end

  add_index "units", ["created_at"], :name => "index_units_on_created_at"
  add_index "units", ["creator_id"], :name => "index_units_on_creator_id"
  add_index "units", ["updated_at"], :name => "index_units_on_updated_at"
  add_index "units", ["updater_id"], :name => "index_units_on_updater_id"

end
