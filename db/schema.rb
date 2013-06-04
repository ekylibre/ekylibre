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

ActiveRecord::Schema.define(:version => 20130513165730) do

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

  add_index "account_balances", ["account_id"], :name => "index_account_balances_on_account_id"
  add_index "account_balances", ["created_at"], :name => "index_account_balances_on_created_at"
  add_index "account_balances", ["creator_id"], :name => "index_account_balances_on_creator_id"
  add_index "account_balances", ["financial_year_id"], :name => "index_account_balances_on_financialyear_id"
  add_index "account_balances", ["updated_at"], :name => "index_account_balances_on_updated_at"
  add_index "account_balances", ["updater_id"], :name => "index_account_balances_on_updater_id"

  create_table "accounts", :force => true do |t|
    t.string   "number",       :limit => 16,                     :null => false
    t.string   "name",         :limit => 208,                    :null => false
    t.string   "label",                                          :null => false
    t.boolean  "debtor",                      :default => false, :null => false
    t.string   "last_letter",  :limit => 8
    t.text     "description"
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

  create_table "activities", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "description"
    t.string   "nomen"
    t.string   "family",                      :null => false
    t.string   "nature",                      :null => false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "activities", ["created_at"], :name => "index_activities_on_created_at"
  add_index "activities", ["creator_id"], :name => "index_activities_on_creator_id"
  add_index "activities", ["name"], :name => "index_activities_on_name"
  add_index "activities", ["parent_id"], :name => "index_activities_on_parent_id"
  add_index "activities", ["updated_at"], :name => "index_activities_on_updated_at"
  add_index "activities", ["updater_id"], :name => "index_activities_on_updater_id"

  create_table "activity_repartitions", :force => true do |t|
    t.integer  "activity_id",                                                         :null => false
    t.integer  "journal_entry_item_id",                                               :null => false
    t.string   "state",                                                               :null => false
    t.date     "affected_on",                                                         :null => false
    t.integer  "product_nature_id"
    t.integer  "campaign_id"
    t.decimal  "percentage",            :precision => 19, :scale => 4,                :null => false
    t.text     "description"
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                         :default => 0, :null => false
  end

  add_index "activity_repartitions", ["activity_id"], :name => "index_activity_repartitions_on_activity_id"
  add_index "activity_repartitions", ["campaign_id"], :name => "index_activity_repartitions_on_campaign_id"
  add_index "activity_repartitions", ["created_at"], :name => "index_activity_repartitions_on_created_at"
  add_index "activity_repartitions", ["creator_id"], :name => "index_activity_repartitions_on_creator_id"
  add_index "activity_repartitions", ["journal_entry_item_id"], :name => "index_activity_repartitions_on_journal_entry_item_id"
  add_index "activity_repartitions", ["product_nature_id"], :name => "index_activity_repartitions_on_product_nature_id"
  add_index "activity_repartitions", ["updated_at"], :name => "index_activity_repartitions_on_updated_at"
  add_index "activity_repartitions", ["updater_id"], :name => "index_activity_repartitions_on_updater_id"

  create_table "activity_watchings", :force => true do |t|
    t.integer  "activity_id",                      :null => false
    t.integer  "product_nature_id",                :null => false
    t.integer  "work_unit_id"
    t.integer  "area_unit_id"
    t.integer  "position"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",      :default => 0, :null => false
  end

  add_index "activity_watchings", ["activity_id"], :name => "index_activity_watchings_on_activity_id"
  add_index "activity_watchings", ["area_unit_id"], :name => "index_activity_watchings_on_area_unit_id"
  add_index "activity_watchings", ["created_at"], :name => "index_activity_watchings_on_created_at"
  add_index "activity_watchings", ["creator_id"], :name => "index_activity_watchings_on_creator_id"
  add_index "activity_watchings", ["product_nature_id"], :name => "index_activity_watchings_on_product_nature_id"
  add_index "activity_watchings", ["updated_at"], :name => "index_activity_watchings_on_updated_at"
  add_index "activity_watchings", ["updater_id"], :name => "index_activity_watchings_on_updater_id"
  add_index "activity_watchings", ["work_unit_id"], :name => "index_activity_watchings_on_work_unit_id"

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
  add_index "affairs", ["journal_entry_id"], :name => "index_affairs_on_journal_entry_id"
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
  add_index "asset_depreciations", ["financial_year_id"], :name => "index_asset_depreciations_on_financial_year_id"
  add_index "asset_depreciations", ["journal_entry_id"], :name => "index_asset_depreciations_on_journal_entry_id"
  add_index "asset_depreciations", ["updated_at"], :name => "index_asset_depreciations_on_updated_at"
  add_index "asset_depreciations", ["updater_id"], :name => "index_asset_depreciations_on_updater_id"

  create_table "assets", :force => true do |t|
    t.integer  "allocation_account_id",                                                              :null => false
    t.integer  "journal_id",                                                                         :null => false
    t.string   "name",                                                                               :null => false
    t.string   "number",                                                                             :null => false
    t.text     "description"
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
  add_index "assets", ["charges_account_id"], :name => "index_assets_on_charges_account_id"
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

  create_table "campaigns", :force => true do |t|
    t.string   "name",                            :null => false
    t.string   "description"
    t.string   "nomen"
    t.boolean  "closed",       :default => false, :null => false
    t.datetime "closed_at"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0,     :null => false
  end

  add_index "campaigns", ["created_at"], :name => "index_campaigns_on_created_at"
  add_index "campaigns", ["creator_id"], :name => "index_campaigns_on_creator_id"
  add_index "campaigns", ["name"], :name => "index_campaigns_on_name"
  add_index "campaigns", ["updated_at"], :name => "index_campaigns_on_updated_at"
  add_index "campaigns", ["updater_id"], :name => "index_campaigns_on_updater_id"

  create_table "cash_transfers", :force => true do |t|
    t.integer  "emitter_cash_id",                                                            :null => false
    t.integer  "receiver_cash_id",                                                           :null => false
    t.integer  "emitter_journal_entry_id"
    t.datetime "accounted_at"
    t.string   "number",                                                                     :null => false
    t.text     "description"
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
  add_index "cash_transfers", ["emitter_cash_id"], :name => "index_cash_transfers_on_emitter_cash_id"
  add_index "cash_transfers", ["emitter_journal_entry_id"], :name => "index_cash_transfers_on_emitter_journal_entry_id"
  add_index "cash_transfers", ["receiver_cash_id"], :name => "index_cash_transfers_on_receiver_cash_id"
  add_index "cash_transfers", ["receiver_journal_entry_id"], :name => "index_cash_transfers_on_receiver_journal_entry_id"
  add_index "cash_transfers", ["updated_at"], :name => "index_cash_transfers_on_updated_at"
  add_index "cash_transfers", ["updater_id"], :name => "index_cash_transfers_on_updater_id"

  create_table "cashes", :force => true do |t|
    t.string   "name",                                                           :null => false
    t.string   "iban",                 :limit => 34
    t.string   "spaced_iban",          :limit => 48
    t.string   "bank_identifier_code", :limit => 16
    t.integer  "journal_id",                                                     :null => false
    t.integer  "account_id",                                                     :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                       :default => 0,              :null => false
    t.string   "bank_code"
    t.string   "bank_agency_code"
    t.string   "bank_account_number"
    t.string   "bank_account_key"
    t.string   "mode",                               :default => "iban",         :null => false
    t.boolean  "by_default",                         :default => false,          :null => false
    t.text     "bank_agency_address"
    t.string   "bank_name",            :limit => 50
    t.string   "nature",               :limit => 16, :default => "bank_account", :null => false
    t.string   "currency",             :limit => 3
    t.string   "country",              :limit => 2
  end

  add_index "cashes", ["account_id"], :name => "index_bank_accounts_on_account_id"
  add_index "cashes", ["created_at"], :name => "index_bank_accounts_on_created_at"
  add_index "cashes", ["creator_id"], :name => "index_bank_accounts_on_creator_id"
  add_index "cashes", ["currency"], :name => "index_cashes_on_currency"
  add_index "cashes", ["journal_id"], :name => "index_bank_accounts_on_journal_id"
  add_index "cashes", ["updated_at"], :name => "index_bank_accounts_on_updated_at"
  add_index "cashes", ["updater_id"], :name => "index_bank_accounts_on_updater_id"

  create_table "custom_field_choices", :force => true do |t|
    t.integer  "custom_field_id",                :null => false
    t.string   "name",                           :null => false
    t.string   "value"
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

  create_table "custom_fields", :force => true do |t|
    t.string   "name",                                                                           :null => false
    t.string   "nature",          :limit => 8,                                                   :null => false
    t.integer  "position"
    t.boolean  "active",                                                      :default => true,  :null => false
    t.boolean  "required",                                                    :default => false, :null => false
    t.integer  "maximal_length"
    t.decimal  "minimal_value",                :precision => 19, :scale => 4
    t.decimal  "maximal_value",                :precision => 19, :scale => 4
    t.datetime "created_at",                                                                     :null => false
    t.datetime "updated_at",                                                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                :default => 0,     :null => false
    t.string   "customized_type",                                                                :null => false
    t.integer  "minimal_length"
    t.string   "column_name"
  end

  add_index "custom_fields", ["created_at"], :name => "index_complements_on_created_at"
  add_index "custom_fields", ["creator_id"], :name => "index_complements_on_creator_id"
  add_index "custom_fields", ["required"], :name => "index_complements_on_required"
  add_index "custom_fields", ["updated_at"], :name => "index_complements_on_updated_at"
  add_index "custom_fields", ["updater_id"], :name => "index_complements_on_updater_id"

  create_table "departments", :force => true do |t|
    t.string   "name",                            :null => false
    t.text     "description"
    t.integer  "parent_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     :default => 0, :null => false
    t.text     "sales_conditions"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth",            :default => 0, :null => false
  end

  add_index "departments", ["created_at"], :name => "index_departments_on_created_at"
  add_index "departments", ["creator_id"], :name => "index_departments_on_creator_id"
  add_index "departments", ["parent_id"], :name => "index_departments_on_parent_id"
  add_index "departments", ["updated_at"], :name => "index_departments_on_updated_at"
  add_index "departments", ["updater_id"], :name => "index_departments_on_updater_id"

  create_table "deposit_items", :force => true do |t|
    t.integer  "deposit_id",                                                                :null => false
    t.decimal  "quantity",                  :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",                    :precision => 19, :scale => 4, :default => 1.0, :null => false
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                             :default => 0,   :null => false
    t.string   "currency",     :limit => 3,                                                 :null => false
  end

  add_index "deposit_items", ["created_at"], :name => "index_deposit_items_on_created_at"
  add_index "deposit_items", ["creator_id"], :name => "index_deposit_items_on_creator_id"
  add_index "deposit_items", ["deposit_id"], :name => "index_deposit_items_on_deposit_id"
  add_index "deposit_items", ["updated_at"], :name => "index_deposit_items_on_updated_at"
  add_index "deposit_items", ["updater_id"], :name => "index_deposit_items_on_updater_id"

  create_table "deposits", :force => true do |t|
    t.decimal  "amount",           :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.integer  "payments_count",                                  :default => 0,     :null => false
    t.date     "created_on",                                                         :null => false
    t.text     "description"
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

  add_index "deposits", ["cash_id"], :name => "index_deposits_on_cash_id"
  add_index "deposits", ["created_at"], :name => "index_embankments_on_created_at"
  add_index "deposits", ["creator_id"], :name => "index_embankments_on_creator_id"
  add_index "deposits", ["journal_entry_id"], :name => "index_deposits_on_journal_entry_id"
  add_index "deposits", ["mode_id"], :name => "index_deposits_on_mode_id"
  add_index "deposits", ["responsible_id"], :name => "index_deposits_on_responsible_id"
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

  create_table "document_archives", :force => true do |t|
    t.string   "file_file_name"
    t.integer  "file_file_size"
    t.datetime "archived_at"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",      :default => 0, :null => false
    t.integer  "template_id"
    t.integer  "position"
    t.string   "file_content_type"
    t.datetime "file_updated_at"
    t.string   "file_fingerprint"
    t.integer  "document_id",                      :null => false
  end

  add_index "document_archives", ["created_at"], :name => "index_document_archives_on_created_at"
  add_index "document_archives", ["creator_id"], :name => "index_document_archives_on_creator_id"
  add_index "document_archives", ["document_id"], :name => "index_document_archives_on_document_id"
  add_index "document_archives", ["template_id"], :name => "index_document_archives_on_template_id"
  add_index "document_archives", ["updated_at"], :name => "index_document_archives_on_updated_at"
  add_index "document_archives", ["updater_id"], :name => "index_document_archives_on_updater_id"

  create_table "document_templates", :force => true do |t|
    t.string   "name",                                          :null => false
    t.boolean  "active",                     :default => false, :null => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0,     :null => false
    t.boolean  "by_default",                 :default => false, :null => false
    t.string   "nature",       :limit => 63,                    :null => false
    t.string   "language",     :limit => 3,                     :null => false
    t.string   "archiving",    :limit => 63,                    :null => false
    t.boolean  "managed",                    :default => false, :null => false
    t.string   "formats"
  end

  add_index "document_templates", ["created_at"], :name => "index_document_templates_on_created_at"
  add_index "document_templates", ["creator_id"], :name => "index_document_templates_on_creator_id"
  add_index "document_templates", ["updated_at"], :name => "index_document_templates_on_updated_at"
  add_index "document_templates", ["updater_id"], :name => "index_document_templates_on_updater_id"

  create_table "documents", :force => true do |t|
    t.string   "number",                :limit => 63,                :null => false
    t.string   "name",                                               :null => false
    t.string   "nature",                :limit => 63,                :null => false
    t.integer  "archives_count",                      :default => 0, :null => false
    t.integer  "template_id"
    t.string   "template_type"
    t.string   "datasource",            :limit => 63
    t.text     "datasource_parameters"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                        :default => 0, :null => false
  end

  add_index "documents", ["created_at"], :name => "index_documents_on_created_at"
  add_index "documents", ["creator_id"], :name => "index_documents_on_creator_id"
  add_index "documents", ["datasource"], :name => "index_documents_on_datasource"
  add_index "documents", ["name"], :name => "index_documents_on_name"
  add_index "documents", ["nature"], :name => "index_documents_on_nature"
  add_index "documents", ["number"], :name => "index_documents_on_number"
  add_index "documents", ["updated_at"], :name => "index_documents_on_updated_at"
  add_index "documents", ["updater_id"], :name => "index_documents_on_updater_id"

  create_table "entities", :force => true do |t|
    t.integer  "nature_id",                                                                                 :null => false
    t.string   "last_name",                                                                                 :null => false
    t.string   "first_name"
    t.string   "full_name",                                                                                 :null => false
    t.string   "code",                      :limit => 64
    t.boolean  "active",                                                                 :default => true,  :null => false
    t.date     "born_on"
    t.date     "dead_on"
    t.string   "soundex",                   :limit => 4
    t.boolean  "client",                                                                 :default => false, :null => false
    t.boolean  "supplier",                                                               :default => false, :null => false
    t.datetime "created_at",                                                                                :null => false
    t.datetime "updated_at",                                                                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                           :default => 0,     :null => false
    t.integer  "client_account_id"
    t.integer  "supplier_account_id"
    t.boolean  "vat_submissive",                                                         :default => true,  :null => false
    t.boolean  "reminder_submissive",                                                    :default => false, :null => false
    t.string   "deliveries_conditions",     :limit => 60
    t.decimal  "discount_percentage",                     :precision => 19, :scale => 4
    t.decimal  "reduction_percentage",                    :precision => 19, :scale => 4
    t.text     "description"
    t.string   "vat_number",                :limit => 15
    t.string   "country",                   :limit => 2
    t.integer  "authorized_payments_count"
    t.integer  "responsible_id"
    t.integer  "proposer_id"
    t.integer  "payment_mode_id"
    t.integer  "invoices_count"
    t.date     "first_met_on"
    t.integer  "sale_price_listing_id"
    t.string   "siren",                     :limit => 9
    t.string   "origin"
    t.string   "webpass"
    t.string   "activity_code",             :limit => 32
    t.boolean  "transporter",                                                            :default => false, :null => false
    t.string   "language",                  :limit => 3,                                 :default => "???", :null => false
    t.boolean  "prospect",                                                               :default => false, :null => false
    t.boolean  "attorney",                                                               :default => false, :null => false
    t.integer  "attorney_account_id"
    t.boolean  "locked",                                                                 :default => false, :null => false
    t.string   "currency",                                                                                  :null => false
    t.boolean  "of_company",                                                             :default => false, :null => false
    t.string   "picture_file_name"
    t.integer  "picture_file_size"
    t.string   "picture_content_type"
    t.datetime "picture_updated_at"
    t.string   "payment_delay"
  end

  add_index "entities", ["attorney_account_id"], :name => "index_entities_on_attorney_account_id"
  add_index "entities", ["client_account_id"], :name => "index_entities_on_client_account_id"
  add_index "entities", ["code"], :name => "entities_codes"
  add_index "entities", ["code"], :name => "index_entities_on_code"
  add_index "entities", ["created_at"], :name => "index_entities_on_created_at"
  add_index "entities", ["creator_id"], :name => "index_entities_on_creator_id"
  add_index "entities", ["nature_id"], :name => "index_entities_on_nature_id"
  add_index "entities", ["of_company"], :name => "index_entities_on_of_company"
  add_index "entities", ["payment_mode_id"], :name => "index_entities_on_payment_mode_id"
  add_index "entities", ["proposer_id"], :name => "index_entities_on_proposer_id"
  add_index "entities", ["responsible_id"], :name => "index_entities_on_responsible_id"
  add_index "entities", ["sale_price_listing_id"], :name => "index_entities_on_sale_price_listing_id"
  add_index "entities", ["supplier_account_id"], :name => "index_entities_on_supplier_account_id"
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
  add_index "entity_addresses", ["mail_area_id"], :name => "index_entity_addresses_on_mail_area_id"
  add_index "entity_addresses", ["updated_at"], :name => "index_entity_addresses_on_updated_at"
  add_index "entity_addresses", ["updater_id"], :name => "index_entity_addresses_on_updater_id"

  create_table "entity_link_natures", :force => true do |t|
    t.string   "name",                                   :null => false
    t.string   "name_1_to_2"
    t.string   "name_2_to_1"
    t.boolean  "symmetric",           :default => false, :null => false
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",        :default => 0,     :null => false
    t.boolean  "propagate_addresses", :default => false, :null => false
    t.text     "description"
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
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.text     "description"
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
    t.string   "name",                               :null => false
    t.string   "title"
    t.boolean  "active",           :default => true, :null => false
    t.boolean  "in_name",          :default => true, :null => false
    t.text     "description"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     :default => 0,    :null => false
    t.string   "full_name_format"
    t.string   "gender",                             :null => false
  end

  add_index "entity_natures", ["created_at"], :name => "index_entity_natures_on_created_at"
  add_index "entity_natures", ["creator_id"], :name => "index_entity_natures_on_creator_id"
  add_index "entity_natures", ["updated_at"], :name => "index_entity_natures_on_updated_at"
  add_index "entity_natures", ["updater_id"], :name => "index_entity_natures_on_updater_id"

  create_table "establishments", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "code"
    t.text     "description"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
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
    t.text     "reason"
    t.integer  "entity_id",                     :null => false
    t.integer  "nature_id",                     :null => false
    t.integer  "responsible_id",                :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   :default => 0, :null => false
    t.datetime "stopped_at"
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
  add_index "financial_years", ["last_journal_entry_id"], :name => "index_financial_years_on_last_journal_entry_id"
  add_index "financial_years", ["updated_at"], :name => "index_financialyears_on_updated_at"
  add_index "financial_years", ["updater_id"], :name => "index_financialyears_on_updater_id"

  create_table "incident_natures", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "nature",                      :null => false
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
    t.text     "description"
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

  add_index "incoming_deliveries", ["address_id"], :name => "index_incoming_deliveries_on_address_id"
  add_index "incoming_deliveries", ["created_at"], :name => "index_purchase_deliveries_on_created_at"
  add_index "incoming_deliveries", ["creator_id"], :name => "index_purchase_deliveries_on_creator_id"
  add_index "incoming_deliveries", ["currency"], :name => "index_incoming_deliveries_on_currency"
  add_index "incoming_deliveries", ["mode_id"], :name => "index_incoming_deliveries_on_mode_id"
  add_index "incoming_deliveries", ["purchase_id"], :name => "index_incoming_deliveries_on_purchase_id"
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
  add_index "incoming_delivery_items", ["delivery_id"], :name => "index_incoming_delivery_items_on_delivery_id"
  add_index "incoming_delivery_items", ["move_id"], :name => "index_incoming_delivery_items_on_move_id"
  add_index "incoming_delivery_items", ["price_id"], :name => "index_incoming_delivery_items_on_price_id"
  add_index "incoming_delivery_items", ["product_id"], :name => "index_incoming_delivery_items_on_product_id"
  add_index "incoming_delivery_items", ["purchase_item_id"], :name => "index_incoming_delivery_items_on_purchase_item_id"
  add_index "incoming_delivery_items", ["tracking_id"], :name => "index_incoming_delivery_items_on_tracking_id"
  add_index "incoming_delivery_items", ["unit_id"], :name => "index_incoming_delivery_items_on_unit_id"
  add_index "incoming_delivery_items", ["updated_at"], :name => "index_incoming_delivery_items_on_updated_at"
  add_index "incoming_delivery_items", ["updater_id"], :name => "index_incoming_delivery_items_on_updater_id"

  create_table "incoming_delivery_modes", :force => true do |t|
    t.string   "name",                                     :null => false
    t.string   "code",         :limit => 8,                :null => false
    t.text     "description"
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
    t.boolean  "active",                                                               :default => false
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

  add_index "incoming_payment_modes", ["attorney_journal_id"], :name => "index_incoming_payment_modes_on_attorney_journal_id"
  add_index "incoming_payment_modes", ["cash_id"], :name => "index_incoming_payment_modes_on_cash_id"
  add_index "incoming_payment_modes", ["commission_account_id"], :name => "index_incoming_payment_modes_on_commission_account_id"
  add_index "incoming_payment_modes", ["created_at"], :name => "index_payment_modes_on_created_at"
  add_index "incoming_payment_modes", ["creator_id"], :name => "index_payment_modes_on_creator_id"
  add_index "incoming_payment_modes", ["depositables_account_id"], :name => "index_incoming_payment_modes_on_depositables_account_id"
  add_index "incoming_payment_modes", ["depositables_journal_id"], :name => "index_incoming_payment_modes_on_depositables_journal_id"
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
    t.string   "bank_name"
    t.string   "bank_check_number"
    t.string   "bank_account_number"
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
  add_index "incoming_payments", ["commission_account_id"], :name => "index_incoming_payments_on_commission_account_id"
  add_index "incoming_payments", ["created_at"], :name => "index_payments_on_created_at"
  add_index "incoming_payments", ["creator_id"], :name => "index_payments_on_creator_id"
  add_index "incoming_payments", ["deposit_id"], :name => "index_incoming_payments_on_deposit_id"
  add_index "incoming_payments", ["journal_entry_id"], :name => "index_incoming_payments_on_journal_entry_id"
  add_index "incoming_payments", ["mode_id"], :name => "index_incoming_payments_on_mode_id"
  add_index "incoming_payments", ["payer_id"], :name => "index_incoming_payments_on_payer_id"
  add_index "incoming_payments", ["responsible_id"], :name => "index_incoming_payments_on_responsible_id"
  add_index "incoming_payments", ["updated_at"], :name => "index_payments_on_updated_at"
  add_index "incoming_payments", ["updater_id"], :name => "index_payments_on_updater_id"

  create_table "inventories", :force => true do |t|
    t.date     "created_on",                                     :null => false
    t.text     "description"
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
  add_index "inventories", ["journal_entry_id"], :name => "index_inventories_on_journal_entry_id"
  add_index "inventories", ["responsible_id"], :name => "index_inventories_on_responsible_id"
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
  add_index "inventory_items", ["inventory_id"], :name => "index_inventory_items_on_inventory_id"
  add_index "inventory_items", ["move_id"], :name => "index_inventory_items_on_move_id"
  add_index "inventory_items", ["product_id"], :name => "index_inventory_items_on_product_id"
  add_index "inventory_items", ["tracking_id"], :name => "index_inventory_items_on_tracking_id"
  add_index "inventory_items", ["unit_id"], :name => "index_inventory_items_on_unit_id"
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
  add_index "journal_entries", ["financial_year_id"], :name => "index_journal_entries_on_financial_year_id"
  add_index "journal_entries", ["journal_id"], :name => "index_journal_records_on_journal_id"
  add_index "journal_entries", ["original_currency"], :name => "index_journal_entries_on_currency"
  add_index "journal_entries", ["resource_id", "resource_type"], :name => "index_journal_entries_on_resource_id_and_resource_type"
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
    t.text     "description"
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
  add_index "journal_entry_items", ["journal_id"], :name => "index_journal_entry_items_on_journal_id"
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
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth",                             :default => 0,    :null => false
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
    t.text     "description"
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
  add_index "mandates", ["entity_id"], :name => "index_mandates_on_entity_id"
  add_index "mandates", ["updated_at"], :name => "index_mandates_on_updated_at"
  add_index "mandates", ["updater_id"], :name => "index_mandates_on_updater_id"

  create_table "observations", :force => true do |t|
    t.string   "importance",   :limit => 10,                :null => false
    t.text     "content",                                   :null => false
    t.integer  "subject_id",                                :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               :default => 0, :null => false
    t.string   "subject_type",                              :null => false
    t.datetime "observed_at",                               :null => false
    t.integer  "author_id",                                 :null => false
  end

  add_index "observations", ["author_id"], :name => "index_observations_on_author_id"
  add_index "observations", ["created_at"], :name => "index_observations_on_created_at"
  add_index "observations", ["creator_id"], :name => "index_observations_on_creator_id"
  add_index "observations", ["subject_id", "subject_type"], :name => "index_observations_on_subject_id_and_subject_type"
  add_index "observations", ["updated_at"], :name => "index_observations_on_updated_at"
  add_index "observations", ["updater_id"], :name => "index_observations_on_updater_id"

  create_table "operation_natures", :force => true do |t|
    t.string   "name",                          :null => false
    t.text     "description"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   :default => 0, :null => false
    t.string   "nomen"
    t.integer  "working_set_id"
  end

  add_index "operation_natures", ["created_at"], :name => "index_operation_natures_on_created_at"
  add_index "operation_natures", ["creator_id"], :name => "index_operation_natures_on_creator_id"
  add_index "operation_natures", ["nomen"], :name => "index_operation_natures_on_nomen"
  add_index "operation_natures", ["updated_at"], :name => "index_operation_natures_on_updated_at"
  add_index "operation_natures", ["updater_id"], :name => "index_operation_natures_on_updater_id"
  add_index "operation_natures", ["working_set_id"], :name => "index_operation_natures_on_working_set_id"

  create_table "operation_tasks", :force => true do |t|
    t.integer  "operation_id",                                                         :null => false
    t.integer  "parent_id"
    t.boolean  "detailled",                                         :default => false, :null => false
    t.integer  "subject_id",                                                           :null => false
    t.string   "verb",                                                                 :null => false
    t.string   "string",                                                               :null => false
    t.integer  "operand_id"
    t.integer  "operand_unit_id"
    t.decimal  "operand_quantity",   :precision => 19, :scale => 4
    t.integer  "indicator_datum_id"
    t.datetime "created_at",                                                           :null => false
    t.datetime "updated_at",                                                           :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                      :default => 0,     :null => false
  end

  add_index "operation_tasks", ["created_at"], :name => "index_operation_tasks_on_created_at"
  add_index "operation_tasks", ["creator_id"], :name => "index_operation_tasks_on_creator_id"
  add_index "operation_tasks", ["indicator_datum_id"], :name => "index_operation_tasks_on_indicator_datum_id"
  add_index "operation_tasks", ["operand_id"], :name => "index_operation_tasks_on_operand_id"
  add_index "operation_tasks", ["operand_unit_id"], :name => "index_operation_tasks_on_operand_unit_id"
  add_index "operation_tasks", ["operation_id"], :name => "index_operation_tasks_on_operation_id"
  add_index "operation_tasks", ["parent_id"], :name => "index_operation_tasks_on_parent_id"
  add_index "operation_tasks", ["subject_id"], :name => "index_operation_tasks_on_subject_id"
  add_index "operation_tasks", ["updated_at"], :name => "index_operation_tasks_on_updated_at"
  add_index "operation_tasks", ["updater_id"], :name => "index_operation_tasks_on_updater_id"

  create_table "operations", :force => true do |t|
    t.integer  "nature_id"
    t.datetime "started_at",                                     :null => false
    t.datetime "stopped_at"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                    :default => 0, :null => false
    t.integer  "production_chain_work_center_id"
    t.integer  "procedure_id"
  end

  add_index "operations", ["created_at"], :name => "index_operations_on_created_at"
  add_index "operations", ["creator_id"], :name => "index_operations_on_creator_id"
  add_index "operations", ["procedure_id"], :name => "index_operations_on_procedure_id"
  add_index "operations", ["updated_at"], :name => "index_operations_on_updated_at"
  add_index "operations", ["updater_id"], :name => "index_operations_on_updater_id"

  create_table "outgoing_deliveries", :force => true do |t|
    t.integer  "sale_id",                                                                       :null => false
    t.decimal  "pretax_amount",                 :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.decimal  "amount",                        :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.text     "description"
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

  add_index "outgoing_deliveries", ["address_id"], :name => "index_outgoing_deliveries_on_address_id"
  add_index "outgoing_deliveries", ["created_at"], :name => "index_deliveries_on_created_at"
  add_index "outgoing_deliveries", ["creator_id"], :name => "index_deliveries_on_creator_id"
  add_index "outgoing_deliveries", ["currency"], :name => "index_outgoing_deliveries_on_currency"
  add_index "outgoing_deliveries", ["mode_id"], :name => "index_outgoing_deliveries_on_mode_id"
  add_index "outgoing_deliveries", ["sale_id"], :name => "index_outgoing_deliveries_on_sales_order_id"
  add_index "outgoing_deliveries", ["transport_id"], :name => "index_outgoing_deliveries_on_transport_id"
  add_index "outgoing_deliveries", ["transporter_id"], :name => "index_outgoing_deliveries_on_transporter_id"
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
  add_index "outgoing_delivery_items", ["delivery_id"], :name => "index_outgoing_delivery_items_on_delivery_id"
  add_index "outgoing_delivery_items", ["move_id"], :name => "index_outgoing_delivery_items_on_move_id"
  add_index "outgoing_delivery_items", ["price_id"], :name => "index_outgoing_delivery_items_on_price_id"
  add_index "outgoing_delivery_items", ["product_id"], :name => "index_outgoing_delivery_items_on_product_id"
  add_index "outgoing_delivery_items", ["sale_item_id"], :name => "index_outgoing_delivery_items_on_sale_item_id"
  add_index "outgoing_delivery_items", ["tracking_id"], :name => "index_outgoing_delivery_items_on_tracking_id"
  add_index "outgoing_delivery_items", ["unit_id"], :name => "index_outgoing_delivery_items_on_unit_id"
  add_index "outgoing_delivery_items", ["updated_at"], :name => "index_outgoing_delivery_items_on_updated_at"
  add_index "outgoing_delivery_items", ["updater_id"], :name => "index_outgoing_delivery_items_on_updater_id"

  create_table "outgoing_delivery_modes", :force => true do |t|
    t.string   "name",                                           :null => false
    t.string   "code",           :limit => 8,                    :null => false
    t.text     "description"
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
    t.boolean  "active",                            :default => false, :null => false
  end

  add_index "outgoing_payment_modes", ["attorney_journal_id"], :name => "index_outgoing_payment_modes_on_attorney_journal_id"
  add_index "outgoing_payment_modes", ["cash_id"], :name => "index_outgoing_payment_modes_on_cash_id"
  add_index "outgoing_payment_modes", ["created_at"], :name => "index_purchase_payment_modes_on_created_at"
  add_index "outgoing_payment_modes", ["creator_id"], :name => "index_purchase_payment_modes_on_creator_id"
  add_index "outgoing_payment_modes", ["updated_at"], :name => "index_purchase_payment_modes_on_updated_at"
  add_index "outgoing_payment_modes", ["updater_id"], :name => "index_purchase_payment_modes_on_updater_id"

  create_table "outgoing_payments", :force => true do |t|
    t.datetime "accounted_at"
    t.decimal  "amount",                         :precision => 19, :scale => 4, :default => 0.0,  :null => false
    t.string   "bank_check_number"
    t.boolean  "delivered",                                                     :default => true, :null => false
    t.date     "created_on"
    t.integer  "journal_entry_id"
    t.integer  "responsible_id",                                                                  :null => false
    t.integer  "payee_id",                                                                        :null => false
    t.integer  "mode_id",                                                                         :null => false
    t.string   "number"
    t.date     "paid_on"
    t.date     "to_bank_on",                                                                      :null => false
    t.datetime "created_at",                                                                      :null => false
    t.datetime "updated_at",                                                                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                  :default => 0,    :null => false
    t.integer  "cash_id",                                                                         :null => false
    t.string   "currency",          :limit => 3,                                                  :null => false
    t.boolean  "downpayment",                                                   :default => true, :null => false
    t.integer  "affair_id"
  end

  add_index "outgoing_payments", ["affair_id"], :name => "index_outgoing_payments_on_affair_id"
  add_index "outgoing_payments", ["cash_id"], :name => "index_outgoing_payments_on_cash_id"
  add_index "outgoing_payments", ["created_at"], :name => "index_purchase_payments_on_created_at"
  add_index "outgoing_payments", ["creator_id"], :name => "index_purchase_payments_on_creator_id"
  add_index "outgoing_payments", ["journal_entry_id"], :name => "index_outgoing_payments_on_journal_entry_id"
  add_index "outgoing_payments", ["mode_id"], :name => "index_outgoing_payments_on_mode_id"
  add_index "outgoing_payments", ["payee_id"], :name => "index_outgoing_payments_on_payee_id"
  add_index "outgoing_payments", ["responsible_id"], :name => "index_outgoing_payments_on_responsible_id"
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
  add_index "preferences", ["record_value_id", "record_value_type"], :name => "index_preferences_on_record_value_id_and_record_value_type"
  add_index "preferences", ["updated_at"], :name => "index_parameters_on_updated_at"
  add_index "preferences", ["updater_id"], :name => "index_parameters_on_updater_id"
  add_index "preferences", ["user_id"], :name => "index_parameters_on_user_id"

  create_table "procedure_natures", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "nomen"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "procedure_natures", ["created_at"], :name => "index_procedure_natures_on_created_at"
  add_index "procedure_natures", ["creator_id"], :name => "index_procedure_natures_on_creator_id"
  add_index "procedure_natures", ["nomen"], :name => "index_procedure_natures_on_nomen"
  add_index "procedure_natures", ["parent_id"], :name => "index_procedure_natures_on_parent_id"
  add_index "procedure_natures", ["updated_at"], :name => "index_procedure_natures_on_updated_at"
  add_index "procedure_natures", ["updater_id"], :name => "index_procedure_natures_on_updater_id"

  create_table "procedures", :force => true do |t|
    t.integer  "nature_id",                   :null => false
    t.integer  "parent_id"
    t.string   "name",                        :null => false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "procedures", ["created_at"], :name => "index_procedures_on_created_at"
  add_index "procedures", ["creator_id"], :name => "index_procedures_on_creator_id"
  add_index "procedures", ["nature_id"], :name => "index_procedures_on_nature_id"
  add_index "procedures", ["parent_id"], :name => "index_procedures_on_parent_id"
  add_index "procedures", ["updated_at"], :name => "index_procedures_on_updated_at"
  add_index "procedures", ["updater_id"], :name => "index_procedures_on_updater_id"

  create_table "product_abilities", :force => true do |t|
    t.integer  "product_id",                  :null => false
    t.string   "name",                        :null => false
    t.string   "nomen"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "product_abilities", ["created_at"], :name => "index_product_abilities_on_created_at"
  add_index "product_abilities", ["creator_id"], :name => "index_product_abilities_on_creator_id"
  add_index "product_abilities", ["nomen"], :name => "index_product_abilities_on_nomen"
  add_index "product_abilities", ["updated_at"], :name => "index_product_abilities_on_updated_at"
  add_index "product_abilities", ["updater_id"], :name => "index_product_abilities_on_updater_id"

  create_table "product_indicator_choices", :force => true do |t|
    t.integer  "indicator_id",                :null => false
    t.string   "name",                        :null => false
    t.string   "value"
    t.integer  "position"
    t.text     "description"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "product_indicator_choices", ["created_at"], :name => "index_product_indicator_choices_on_created_at"
  add_index "product_indicator_choices", ["creator_id"], :name => "index_product_indicator_choices_on_creator_id"
  add_index "product_indicator_choices", ["indicator_id"], :name => "index_product_indicator_choices_on_indicator_id"
  add_index "product_indicator_choices", ["updated_at"], :name => "index_product_indicator_choices_on_updated_at"
  add_index "product_indicator_choices", ["updater_id"], :name => "index_product_indicator_choices_on_updater_id"

  create_table "product_indicator_data", :force => true do |t|
    t.integer  "product_id",                                                        :null => false
    t.integer  "indicator_id",                                                      :null => false
    t.datetime "measured_at",                                                       :null => false
    t.text     "description"
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

  add_index "product_indicator_data", ["choice_value_id"], :name => "index_product_indicator_data_on_choice_value_id"
  add_index "product_indicator_data", ["created_at"], :name => "index_product_indicator_data_on_created_at"
  add_index "product_indicator_data", ["creator_id"], :name => "index_product_indicator_data_on_creator_id"
  add_index "product_indicator_data", ["indicator_id"], :name => "index_product_indicator_data_on_indicator_id"
  add_index "product_indicator_data", ["measure_unit_id"], :name => "index_product_indicator_data_on_measure_unit_id"
  add_index "product_indicator_data", ["product_id"], :name => "index_product_indicator_data_on_product_id"
  add_index "product_indicator_data", ["updated_at"], :name => "index_product_indicator_data_on_updated_at"
  add_index "product_indicator_data", ["updater_id"], :name => "index_product_indicator_data_on_updater_id"

  create_table "product_indicators", :force => true do |t|
    t.integer  "process_id"
    t.string   "name",                                                                :null => false
    t.string   "nature",                                                              :null => false
    t.string   "usage"
    t.integer  "unit_id"
    t.integer  "minimal_length"
    t.integer  "maximal_length"
    t.decimal  "minimal_value",     :precision => 19, :scale => 4
    t.decimal  "maximal_value",     :precision => 19, :scale => 4
    t.boolean  "active",                                           :default => false, :null => false
    t.text     "description"
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     :default => 0,     :null => false
    t.integer  "product_nature_id"
  end

  add_index "product_indicators", ["created_at"], :name => "index_product_indicators_on_created_at"
  add_index "product_indicators", ["creator_id"], :name => "index_product_indicators_on_creator_id"
  add_index "product_indicators", ["process_id"], :name => "index_product_indicators_on_process_id"
  add_index "product_indicators", ["product_nature_id"], :name => "index_product_indicators_on_product_nature_id"
  add_index "product_indicators", ["unit_id"], :name => "index_product_indicators_on_unit_id"
  add_index "product_indicators", ["updated_at"], :name => "index_product_indicators_on_updated_at"
  add_index "product_indicators", ["updater_id"], :name => "index_product_indicators_on_updater_id"

  create_table "product_links", :force => true do |t|
    t.integer  "carrier_id",                       :null => false
    t.integer  "carried_id",                       :null => false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",      :default => 0, :null => false
    t.integer  "operation_task_id"
  end

  add_index "product_links", ["carried_id"], :name => "index_product_links_on_carried_id"
  add_index "product_links", ["carrier_id"], :name => "index_product_links_on_carrier_id"
  add_index "product_links", ["created_at"], :name => "index_product_links_on_created_at"
  add_index "product_links", ["creator_id"], :name => "index_product_links_on_creator_id"
  add_index "product_links", ["operation_task_id"], :name => "index_product_links_on_operation_task_id"
  add_index "product_links", ["started_at"], :name => "index_product_links_on_started_at"
  add_index "product_links", ["stopped_at"], :name => "index_product_links_on_stopped_at"
  add_index "product_links", ["updated_at"], :name => "index_product_links_on_updated_at"
  add_index "product_links", ["updater_id"], :name => "index_product_links_on_updater_id"

  create_table "product_localizations", :force => true do |t|
    t.integer  "product_id",                       :null => false
    t.integer  "container_id"
    t.string   "arrival_cause"
    t.string   "departure_cause"
    t.string   "nature",                           :null => false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",      :default => 0, :null => false
    t.integer  "operation_task_id"
  end

  add_index "product_localizations", ["container_id"], :name => "index_product_localizations_on_container_id"
  add_index "product_localizations", ["created_at"], :name => "index_product_localizations_on_created_at"
  add_index "product_localizations", ["creator_id"], :name => "index_product_localizations_on_creator_id"
  add_index "product_localizations", ["operation_task_id"], :name => "index_product_localizations_on_operation_task_id"
  add_index "product_localizations", ["product_id"], :name => "index_product_localizations_on_product_id"
  add_index "product_localizations", ["started_at"], :name => "index_product_localizations_on_started_at"
  add_index "product_localizations", ["stopped_at"], :name => "index_product_localizations_on_stopped_at"
  add_index "product_localizations", ["updated_at"], :name => "index_product_localizations_on_updated_at"
  add_index "product_localizations", ["updater_id"], :name => "index_product_localizations_on_updater_id"

  create_table "product_memberships", :force => true do |t|
    t.integer  "member_id",                        :null => false
    t.integer  "group_id",                         :null => false
    t.datetime "started_at",                       :null => false
    t.datetime "stopped_at"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",      :default => 0, :null => false
    t.integer  "operation_task_id"
  end

  add_index "product_memberships", ["created_at"], :name => "index_product_memberships_on_created_at"
  add_index "product_memberships", ["creator_id"], :name => "index_product_memberships_on_creator_id"
  add_index "product_memberships", ["group_id"], :name => "index_product_memberships_on_group_id"
  add_index "product_memberships", ["member_id"], :name => "index_product_memberships_on_member_id"
  add_index "product_memberships", ["operation_task_id"], :name => "index_product_memberships_on_operation_task_id"
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
  add_index "product_moves", ["unit_id"], :name => "index_product_moves_on_unit_id"
  add_index "product_moves", ["updated_at"], :name => "index_product_moves_on_updated_at"
  add_index "product_moves", ["updater_id"], :name => "index_product_moves_on_updater_id"

  create_table "product_nature_categories", :force => true do |t|
    t.string   "name",                                   :null => false
    t.string   "catalog_name",                           :null => false
    t.text     "catalog_description"
    t.text     "description"
    t.integer  "parent_id"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",        :default => 0,     :null => false
    t.boolean  "published",           :default => false, :null => false
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth",               :default => 0,     :null => false
  end

  add_index "product_nature_categories", ["created_at"], :name => "index_product_nature_categories_on_created_at"
  add_index "product_nature_categories", ["creator_id"], :name => "index_product_nature_categories_on_creator_id"
  add_index "product_nature_categories", ["parent_id"], :name => "index_product_nature_categories_on_parent_id"
  add_index "product_nature_categories", ["updated_at"], :name => "index_product_nature_categories_on_updated_at"
  add_index "product_nature_categories", ["updater_id"], :name => "index_product_nature_categories_on_updater_id"

  create_table "product_natures", :force => true do |t|
    t.string   "name",                                                     :null => false
    t.string   "number",                 :limit => 31,                     :null => false
    t.integer  "unit_id",                                                  :null => false
    t.text     "description"
    t.string   "commercial_name",                                          :null => false
    t.text     "commercial_description"
    t.string   "variety",                :limit => 127,                    :null => false
    t.integer  "category_id",                                              :null => false
    t.boolean  "active",                                :default => false, :null => false
    t.boolean  "alive",                                 :default => false, :null => false
    t.boolean  "depreciable",                           :default => false, :null => false
    t.boolean  "saleable",                              :default => false, :null => false
    t.boolean  "purchasable",                           :default => false, :null => false
    t.boolean  "producible",                            :default => false, :null => false
    t.boolean  "deliverable",                           :default => false, :null => false
    t.boolean  "storable",                              :default => false, :null => false
    t.boolean  "storage",                               :default => false, :null => false
    t.boolean  "towable",                               :default => false, :null => false
    t.boolean  "tractive",                              :default => false, :null => false
    t.boolean  "traceable",                             :default => false, :null => false
    t.boolean  "transferable",                          :default => false, :null => false
    t.boolean  "reductible",                            :default => false, :null => false
    t.boolean  "indivisible",                           :default => false, :null => false
    t.boolean  "subscribing",                           :default => false, :null => false
    t.integer  "subscription_nature_id"
    t.string   "subscription_duration"
    t.integer  "charge_account_id"
    t.integer  "product_account_id"
    t.integer  "asset_account_id"
    t.integer  "stock_account_id"
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at",                                               :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                          :default => 0,     :null => false
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
  add_index "product_natures", ["unit_id"], :name => "index_product_natures_on_unit_id"
  add_index "product_natures", ["updated_at"], :name => "index_product_natures_on_updated_at"
  add_index "product_natures", ["updater_id"], :name => "index_product_natures_on_updater_id"
  add_index "product_natures", ["variety"], :name => "index_product_natures_on_variety"

  create_table "product_price_listings", :force => true do |t|
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

  add_index "product_price_listings", ["created_at"], :name => "index_product_price_listings_on_created_at"
  add_index "product_price_listings", ["creator_id"], :name => "index_product_price_listings_on_creator_id"
  add_index "product_price_listings", ["updated_at"], :name => "index_product_price_listings_on_updated_at"
  add_index "product_price_listings", ["updater_id"], :name => "index_product_price_listings_on_updater_id"

  create_table "product_price_templates", :force => true do |t|
    t.decimal  "assignment_pretax_amount",                        :precision => 19, :scale => 4
    t.decimal  "assignment_amount",                               :precision => 19, :scale => 4
    t.integer  "product_nature_id",                                                                                :null => false
    t.integer  "tax_id",                                                                                           :null => false
    t.datetime "created_at",                                                                                       :null => false
    t.datetime "updated_at",                                                                                       :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                   :default => 0,    :null => false
    t.integer  "supplier_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.boolean  "active",                                                                         :default => true, :null => false
    t.boolean  "by_default",                                                                     :default => true
    t.integer  "listing_id"
    t.string   "currency",                          :limit => 3
    t.string   "pretax_amount_generation",          :limit => 32
    t.text     "pretax_amount_calculation_formula"
    t.integer  "amounts_scale",                                                                  :default => 2,    :null => false
  end

  add_index "product_price_templates", ["created_at"], :name => "index_product_price_templates_on_created_at"
  add_index "product_price_templates", ["creator_id"], :name => "index_product_price_templates_on_creator_id"
  add_index "product_price_templates", ["currency"], :name => "index_product_price_templates_on_currency"
  add_index "product_price_templates", ["listing_id"], :name => "index_product_price_templates_on_listing_id"
  add_index "product_price_templates", ["product_nature_id"], :name => "index_product_price_templates_on_old_product_id"
  add_index "product_price_templates", ["supplier_id"], :name => "index_product_price_templates_on_supplier_id"
  add_index "product_price_templates", ["tax_id"], :name => "index_product_price_templates_on_tax_id"
  add_index "product_price_templates", ["updated_at"], :name => "index_product_price_templates_on_updated_at"
  add_index "product_price_templates", ["updater_id"], :name => "index_product_price_templates_on_updater_id"

  create_table "product_prices", :force => true do |t|
    t.integer  "product_id",                                                  :null => false
    t.integer  "supplier_id",                                                 :null => false
    t.integer  "template_id",                                                 :null => false
    t.decimal  "pretax_amount", :precision => 19, :scale => 4,                :null => false
    t.decimal  "amount",        :precision => 19, :scale => 4,                :null => false
    t.integer  "tax_id",                                                      :null => false
    t.string   "currency",                                                    :null => false
    t.datetime "computed_at",                                                 :null => false
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                 :default => 0, :null => false
  end

  add_index "product_prices", ["created_at"], :name => "index_product_prices_on_created_at"
  add_index "product_prices", ["creator_id"], :name => "index_product_prices_on_creator_id"
  add_index "product_prices", ["product_id"], :name => "index_product_prices_on_product_id"
  add_index "product_prices", ["supplier_id"], :name => "index_product_prices_on_supplier_id"
  add_index "product_prices", ["tax_id"], :name => "index_product_prices_on_tax_id"
  add_index "product_prices", ["template_id"], :name => "index_product_prices_on_template_id"
  add_index "product_prices", ["updated_at"], :name => "index_product_prices_on_updated_at"
  add_index "product_prices", ["updater_id"], :name => "index_product_prices_on_updater_id"

  create_table "product_process_phases", :force => true do |t|
    t.integer  "process_id",                  :null => false
    t.string   "name",                        :null => false
    t.string   "nature",                      :null => false
    t.integer  "position"
    t.string   "phase_delay"
    t.string   "description"
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
    t.string   "variety",      :limit => 127,                    :null => false
    t.string   "name",                                           :null => false
    t.string   "nature",                                         :null => false
    t.string   "description"
    t.boolean  "repeatable",                  :default => false, :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                :default => 0,     :null => false
  end

  add_index "product_processes", ["created_at"], :name => "index_product_processes_on_created_at"
  add_index "product_processes", ["creator_id"], :name => "index_product_processes_on_creator_id"
  add_index "product_processes", ["updated_at"], :name => "index_product_processes_on_updated_at"
  add_index "product_processes", ["updater_id"], :name => "index_product_processes_on_updater_id"
  add_index "product_processes", ["variety"], :name => "index_product_processes_on_variety"

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
    t.text     "description"
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                       :default => 0,     :null => false
  end

  add_index "production_chain_conveyors", ["created_at"], :name => "index_production_chain_conveyors_on_created_at"
  add_index "production_chain_conveyors", ["creator_id"], :name => "index_production_chain_conveyors_on_creator_id"
  add_index "production_chain_conveyors", ["product_nature_id"], :name => "index_production_chain_conveyors_on_product_nature_id"
  add_index "production_chain_conveyors", ["production_chain_id"], :name => "index_production_chain_conveyors_on_production_chain_id"
  add_index "production_chain_conveyors", ["source_id"], :name => "index_production_chain_conveyors_on_source_id"
  add_index "production_chain_conveyors", ["target_id"], :name => "index_production_chain_conveyors_on_target_id"
  add_index "production_chain_conveyors", ["unit_id"], :name => "index_production_chain_conveyors_on_unit_id"
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
  add_index "production_chain_work_center_uses", ["work_center_id"], :name => "index_production_chain_work_center_uses_on_work_center_id"

  create_table "production_chain_work_centers", :force => true do |t|
    t.integer  "production_chain_id",                :null => false
    t.integer  "operation_nature_id",                :null => false
    t.string   "name",                               :null => false
    t.string   "nature",                             :null => false
    t.integer  "building_id",                        :null => false
    t.text     "description"
    t.integer  "position"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",        :default => 0, :null => false
  end

  add_index "production_chain_work_centers", ["created_at"], :name => "index_production_chain_work_centers_on_created_at"
  add_index "production_chain_work_centers", ["creator_id"], :name => "index_production_chain_work_centers_on_creator_id"
  add_index "production_chain_work_centers", ["production_chain_id"], :name => "index_production_chain_work_centers_on_production_chain_id"
  add_index "production_chain_work_centers", ["updated_at"], :name => "index_production_chain_work_centers_on_updated_at"
  add_index "production_chain_work_centers", ["updater_id"], :name => "index_production_chain_work_centers_on_updater_id"

  create_table "production_chains", :force => true do |t|
    t.string   "name",                        :null => false
    t.text     "description"
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
    t.string   "variety",                  :limit => 127,                                                                             :null => false
    t.integer  "nature_id",                                                                                                           :null => false
    t.integer  "unit_id",                                                                                                             :null => false
    t.integer  "tracking_id"
    t.integer  "asset_id"
    t.integer  "current_place_id"
    t.datetime "born_at"
    t.datetime "dead_at"
    t.text     "description"
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
    t.integer  "parent_id"
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
  add_index "products", ["parent_id"], :name => "index_products_on_parent_id"
  add_index "products", ["tracking_id"], :name => "index_products_on_tracking_id"
  add_index "products", ["type"], :name => "index_products_on_type"
  add_index "products", ["unit_id"], :name => "index_products_on_unit_id"
  add_index "products", ["updated_at"], :name => "index_products_on_updated_at"
  add_index "products", ["updater_id"], :name => "index_products_on_updater_id"
  add_index "products", ["variety"], :name => "index_products_on_variety"

  create_table "products_working_sets", :id => false, :force => true do |t|
    t.integer "product_id"
    t.integer "working_set_id"
  end

  add_index "products_working_sets", ["product_id"], :name => "index_products_working_sets_on_product_id"
  add_index "products_working_sets", ["working_set_id"], :name => "index_products_working_sets_on_working_set_id"

  create_table "professions", :force => true do |t|
    t.string   "name",                            :null => false
    t.string   "code"
    t.boolean  "commercial",   :default => false, :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0,     :null => false
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

  add_index "purchase_items", ["account_id"], :name => "index_purchase_items_on_account_id"
  add_index "purchase_items", ["created_at"], :name => "index_purchase_items_on_created_at"
  add_index "purchase_items", ["creator_id"], :name => "index_purchase_items_on_creator_id"
  add_index "purchase_items", ["price_id"], :name => "index_purchase_items_on_price_id"
  add_index "purchase_items", ["product_id"], :name => "index_purchase_items_on_product_id"
  add_index "purchase_items", ["purchase_id"], :name => "index_purchase_items_on_purchase_id"
  add_index "purchase_items", ["tracking_id"], :name => "index_purchase_items_on_tracking_id"
  add_index "purchase_items", ["unit_id"], :name => "index_purchase_items_on_unit_id"
  add_index "purchase_items", ["updated_at"], :name => "index_purchase_items_on_updated_at"
  add_index "purchase_items", ["updater_id"], :name => "index_purchase_items_on_updater_id"

  create_table "purchase_natures", :force => true do |t|
    t.boolean  "active",                       :default => false, :null => false
    t.string   "name"
    t.text     "description"
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
    t.text     "description"
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
  add_index "purchases", ["delivery_address_id"], :name => "index_purchases_on_delivery_address_id"
  add_index "purchases", ["journal_entry_id"], :name => "index_purchases_on_journal_entry_id"
  add_index "purchases", ["nature_id"], :name => "index_purchases_on_nature_id"
  add_index "purchases", ["responsible_id"], :name => "index_purchases_on_responsible_id"
  add_index "purchases", ["supplier_id"], :name => "index_purchases_on_supplier_id"
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

  add_index "sale_items", ["account_id"], :name => "index_sale_items_on_account_id"
  add_index "sale_items", ["created_at"], :name => "index_sale_items_on_created_at"
  add_index "sale_items", ["creator_id"], :name => "index_sale_items_on_creator_id"
  add_index "sale_items", ["entity_id"], :name => "index_sale_items_on_entity_id"
  add_index "sale_items", ["origin_id"], :name => "index_sale_items_on_origin_id"
  add_index "sale_items", ["price_id"], :name => "index_sale_items_on_price_id"
  add_index "sale_items", ["product_id"], :name => "index_sale_items_on_product_id"
  add_index "sale_items", ["reduction_origin_id"], :name => "index_sale_items_on_reduction_origin_id"
  add_index "sale_items", ["sale_id"], :name => "index_sale_items_on_sale_id"
  add_index "sale_items", ["tax_id"], :name => "index_sale_items_on_tax_id"
  add_index "sale_items", ["tracking_id"], :name => "index_sale_items_on_tracking_id"
  add_index "sale_items", ["unit_id"], :name => "index_sale_items_on_unit_id"
  add_index "sale_items", ["updated_at"], :name => "index_sale_items_on_updated_at"
  add_index "sale_items", ["updater_id"], :name => "index_sale_items_on_updater_id"

  create_table "sale_natures", :force => true do |t|
    t.string   "name",                                                                                   :null => false
    t.boolean  "active",                                                              :default => true,  :null => false
    t.boolean  "downpayment",                                                         :default => false, :null => false
    t.decimal  "downpayment_minimum",                  :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "downpayment_percentage",               :precision => 19, :scale => 4, :default => 0.0,   :null => false
    t.text     "description"
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
  add_index "sale_natures", ["journal_id"], :name => "index_sale_natures_on_journal_id"
  add_index "sale_natures", ["payment_mode_id"], :name => "index_sale_natures_on_payment_mode_id"
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
    t.string   "state",               :limit => 64,                                                   :null => false
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
    t.text     "description"
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
  add_index "sales", ["address_id"], :name => "index_sales_on_address_id"
  add_index "sales", ["affair_id"], :name => "index_sales_on_affair_id"
  add_index "sales", ["client_id"], :name => "index_sales_on_client_id"
  add_index "sales", ["created_at"], :name => "index_sale_orders_on_created_at"
  add_index "sales", ["creator_id"], :name => "index_sale_orders_on_creator_id"
  add_index "sales", ["currency"], :name => "index_sales_on_currency"
  add_index "sales", ["delivery_address_id"], :name => "index_sales_on_delivery_address_id"
  add_index "sales", ["invoice_address_id"], :name => "index_sales_on_invoice_address_id"
  add_index "sales", ["journal_entry_id"], :name => "index_sales_on_journal_entry_id"
  add_index "sales", ["nature_id"], :name => "index_sales_on_nature_id"
  add_index "sales", ["origin_id"], :name => "index_sales_on_origin_id"
  add_index "sales", ["responsible_id"], :name => "index_sales_on_responsible_id"
  add_index "sales", ["transporter_id"], :name => "index_sales_on_transporter_id"
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
    t.string   "name",                                                                :null => false
    t.integer  "actual_number"
    t.string   "nature",                                                              :null => false
    t.text     "description"
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                         :default => 0, :null => false
    t.decimal  "reduction_percentage",  :precision => 19, :scale => 4
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
    t.text     "description"
    t.string   "number"
    t.integer  "sale_item_id"
  end

  add_index "subscriptions", ["address_id"], :name => "index_subscriptions_on_address_id"
  add_index "subscriptions", ["created_at"], :name => "index_subscriptions_on_created_at"
  add_index "subscriptions", ["creator_id"], :name => "index_subscriptions_on_creator_id"
  add_index "subscriptions", ["entity_id"], :name => "index_subscriptions_on_entity_id"
  add_index "subscriptions", ["nature_id"], :name => "index_subscriptions_on_nature_id"
  add_index "subscriptions", ["product_nature_id"], :name => "index_subscriptions_on_product_nature_id"
  add_index "subscriptions", ["sale_id"], :name => "index_subscriptions_on_sales_order_id"
  add_index "subscriptions", ["sale_item_id"], :name => "index_subscriptions_on_sale_item_id"
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
  add_index "tax_declarations", ["financial_year_id"], :name => "index_tax_declarations_on_financial_year_id"
  add_index "tax_declarations", ["journal_entry_id"], :name => "index_tax_declarations_on_journal_entry_id"
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
    t.text     "description"
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
  add_index "trackings", ["product_id"], :name => "index_trackings_on_product_id"
  add_index "trackings", ["updated_at"], :name => "index_stock_trackings_on_updated_at"
  add_index "trackings", ["updater_id"], :name => "index_stock_trackings_on_updater_id"

  create_table "transfers", :force => true do |t|
    t.decimal  "amount",                        :precision => 19, :scale => 4, :default => 0.0, :null => false
    t.integer  "client_id",                                                                     :null => false
    t.string   "label"
    t.string   "description"
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
  add_index "transfers", ["client_id"], :name => "index_transfers_on_client_id"
  add_index "transfers", ["created_at"], :name => "index_transfers_on_created_at"
  add_index "transfers", ["creator_id"], :name => "index_transfers_on_creator_id"
  add_index "transfers", ["journal_entry_id"], :name => "index_transfers_on_journal_entry_id"
  add_index "transfers", ["updated_at"], :name => "index_transfers_on_updated_at"
  add_index "transfers", ["updater_id"], :name => "index_transfers_on_updater_id"

  create_table "transports", :force => true do |t|
    t.integer  "transporter_id",                                                   :null => false
    t.integer  "responsible_id"
    t.decimal  "weight",           :precision => 19, :scale => 4
    t.date     "created_on"
    t.date     "transport_on"
    t.text     "description"
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
  add_index "transports", ["purchase_id"], :name => "index_transports_on_purchase_id"
  add_index "transports", ["responsible_id"], :name => "index_transports_on_responsible_id"
  add_index "transports", ["transporter_id"], :name => "index_transports_on_transporter_id"
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

  create_table "users", :force => true do |t|
    t.string   "first_name",                                                                                            :null => false
    t.string   "last_name",                                                                                             :null => false
    t.boolean  "locked",                                                                             :default => false, :null => false
    t.string   "email",                                                                                                 :null => false
    t.integer  "role_id",                                                                                               :null => false
    t.datetime "created_at",                                                                                            :null => false
    t.datetime "updated_at",                                                                                            :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                       :default => 0,     :null => false
    t.decimal  "maximal_grantable_reduction_percentage",              :precision => 19, :scale => 4, :default => 5.0,   :null => false
    t.boolean  "administrator",                                                                      :default => true,  :null => false
    t.text     "rights"
    t.date     "arrived_on"
    t.text     "description"
    t.boolean  "commercial"
    t.date     "departed_on"
    t.integer  "department_id"
    t.integer  "establishment_id"
    t.string   "office"
    t.integer  "profession_id"
    t.boolean  "employed",                                                                           :default => false, :null => false
    t.string   "employment"
    t.string   "language",                               :limit => 3,                                :default => "???", :null => false
    t.datetime "last_sign_in_at"
    t.string   "encrypted_password",                                                                 :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                                                      :default => 0
    t.datetime "current_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",                                                                    :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.integer  "entity_id"
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["created_at"], :name => "index_users_on_created_at"
  add_index "users", ["creator_id"], :name => "index_users_on_creator_id"
  add_index "users", ["department_id"], :name => "index_users_on_department_id"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["entity_id"], :name => "index_users_on_entity_id", :unique => true
  add_index "users", ["establishment_id"], :name => "index_users_on_establishment_id"
  add_index "users", ["profession_id"], :name => "index_users_on_profession_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["role_id"], :name => "index_users_on_role_id"
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true
  add_index "users", ["updated_at"], :name => "index_users_on_updated_at"
  add_index "users", ["updater_id"], :name => "index_users_on_updater_id"

  create_table "working_sets", :force => true do |t|
    t.string   "name",                        :null => false
    t.string   "nomen"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", :default => 0, :null => false
  end

  add_index "working_sets", ["created_at"], :name => "index_working_sets_on_created_at"
  add_index "working_sets", ["creator_id"], :name => "index_working_sets_on_creator_id"
  add_index "working_sets", ["nomen"], :name => "index_working_sets_on_nomen"
  add_index "working_sets", ["updated_at"], :name => "index_working_sets_on_updated_at"
  add_index "working_sets", ["updater_id"], :name => "index_working_sets_on_updater_id"

end
