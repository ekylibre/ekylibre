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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150203212723) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "account_balances", force: true do |t|
    t.integer  "account_id",                                               null: false
    t.integer  "financial_year_id",                                        null: false
    t.decimal  "global_debit",      precision: 19, scale: 4, default: 0.0, null: false
    t.decimal  "global_credit",     precision: 19, scale: 4, default: 0.0, null: false
    t.decimal  "global_balance",    precision: 19, scale: 4, default: 0.0, null: false
    t.integer  "global_count",                               default: 0,   null: false
    t.decimal  "local_debit",       precision: 19, scale: 4, default: 0.0, null: false
    t.decimal  "local_credit",      precision: 19, scale: 4, default: 0.0, null: false
    t.decimal  "local_balance",     precision: 19, scale: 4, default: 0.0, null: false
    t.integer  "local_count",                                default: 0,   null: false
    t.string   "currency",                                                 null: false
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                               default: 0,   null: false
  end

  add_index "account_balances", ["account_id"], :name => "index_account_balances_on_account_id"
  add_index "account_balances", ["created_at"], :name => "index_account_balances_on_created_at"
  add_index "account_balances", ["creator_id"], :name => "index_account_balances_on_creator_id"
  add_index "account_balances", ["financial_year_id"], :name => "index_account_balances_on_financial_year_id"
  add_index "account_balances", ["updated_at"], :name => "index_account_balances_on_updated_at"
  add_index "account_balances", ["updater_id"], :name => "index_account_balances_on_updater_id"

  create_table "accounts", force: true do |t|
    t.string   "number",       limit: 20,                  null: false
    t.string   "name",         limit: 200,                 null: false
    t.string   "label",                                    null: false
    t.boolean  "debtor",                   default: false, null: false
    t.string   "last_letter",  limit: 10
    t.text     "description"
    t.boolean  "reconcilable",             default: false, null: false
    t.text     "usages"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",             default: 0,     null: false
  end

  add_index "accounts", ["created_at"], :name => "index_accounts_on_created_at"
  add_index "accounts", ["creator_id"], :name => "index_accounts_on_creator_id"
  add_index "accounts", ["updated_at"], :name => "index_accounts_on_updated_at"
  add_index "accounts", ["updater_id"], :name => "index_accounts_on_updater_id"

  create_table "activities", force: true do |t|
    t.string   "name",                     null: false
    t.string   "description"
    t.string   "family"
    t.string   "nature",                   null: false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", default: 0, null: false
  end

  add_index "activities", ["created_at"], :name => "index_activities_on_created_at"
  add_index "activities", ["creator_id"], :name => "index_activities_on_creator_id"
  add_index "activities", ["lft", "rgt"], :name => "index_activities_on_lft_and_rgt"
  add_index "activities", ["name"], :name => "index_activities_on_name"
  add_index "activities", ["parent_id"], :name => "index_activities_on_parent_id"
  add_index "activities", ["updated_at"], :name => "index_activities_on_updated_at"
  add_index "activities", ["updater_id"], :name => "index_activities_on_updater_id"

  create_table "affairs", force: true do |t|
    t.string   "number",                                                              null: false
    t.boolean  "closed",                                              default: false, null: false
    t.datetime "closed_at"
    t.integer  "third_id",                                                            null: false
    t.integer  "originator_id",                                                       null: false
    t.string   "originator_type",                                                     null: false
    t.string   "currency",         limit: 3,                                          null: false
    t.decimal  "debit",                      precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "credit",                     precision: 19, scale: 4, default: 0.0,   null: false
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.integer  "deals_count",                                         default: 0,     null: false
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                        default: 0,     null: false
    t.integer  "cash_session_id"
    t.boolean  "ticket",                                              default: false, null: false
  end

  add_index "affairs", ["cash_session_id"], :name => "index_affairs_on_cash_session_id"
  add_index "affairs", ["created_at"], :name => "index_affairs_on_created_at"
  add_index "affairs", ["creator_id"], :name => "index_affairs_on_creator_id"
  add_index "affairs", ["journal_entry_id"], :name => "index_affairs_on_journal_entry_id"
  add_index "affairs", ["number"], :name => "index_affairs_on_number", :unique => true
  add_index "affairs", ["originator_id", "originator_type"], :name => "index_affairs_on_originator_id_and_originator_type"
  add_index "affairs", ["third_id"], :name => "index_affairs_on_third_id"
  add_index "affairs", ["updated_at"], :name => "index_affairs_on_updated_at"
  add_index "affairs", ["updater_id"], :name => "index_affairs_on_updater_id"

  create_table "analyses", force: true do |t|
    t.string   "number",                                                             null: false
    t.string   "nature",                                                             null: false
    t.string   "reference_number"
    t.integer  "product_id"
    t.integer  "sampler_id"
    t.integer  "analyser_id"
    t.text     "description"
    t.datetime "sampled_at",                                                         null: false
    t.datetime "analysed_at"
    t.datetime "created_at",                                                         null: false
    t.datetime "updated_at",                                                         null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                           default: 0, null: false
    t.spatial  "geolocation",      limit: {:srid=>4326, :type=>"point"}
  end

  add_index "analyses", ["analyser_id"], :name => "index_analyses_on_analyser_id"
  add_index "analyses", ["created_at"], :name => "index_analyses_on_created_at"
  add_index "analyses", ["creator_id"], :name => "index_analyses_on_creator_id"
  add_index "analyses", ["nature"], :name => "index_analyses_on_nature"
  add_index "analyses", ["number"], :name => "index_analyses_on_number"
  add_index "analyses", ["product_id"], :name => "index_analyses_on_product_id"
  add_index "analyses", ["reference_number"], :name => "index_analyses_on_reference_number"
  add_index "analyses", ["sampler_id"], :name => "index_analyses_on_sampler_id"
  add_index "analyses", ["updated_at"], :name => "index_analyses_on_updated_at"
  add_index "analyses", ["updater_id"], :name => "index_analyses_on_updater_id"

  create_table "analysis_items", force: true do |t|
    t.integer  "analysis_id",                                                                                                    null: false
    t.string   "indicator_name",                                                                                                 null: false
    t.string   "indicator_datatype",                                                                                             null: false
    t.decimal  "absolute_measure_value_value",                                          precision: 19, scale: 4
    t.string   "absolute_measure_value_unit"
    t.boolean  "boolean_value",                                                                                  default: false, null: false
    t.string   "choice_value"
    t.decimal  "decimal_value",                                                         precision: 19, scale: 4
    t.integer  "integer_value"
    t.decimal  "measure_value_value",                                                   precision: 19, scale: 4
    t.string   "measure_value_unit"
    t.text     "string_value"
    t.text     "annotation"
    t.datetime "created_at",                                                                                                     null: false
    t.datetime "updated_at",                                                                                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                                   default: 0,     null: false
    t.spatial  "geometry_value",               limit: {:srid=>4326, :type=>"geometry"}
    t.spatial  "point_value",                  limit: {:srid=>4326, :type=>"point"}
    t.integer  "product_reading_id"
  end

  add_index "analysis_items", ["analysis_id"], :name => "index_analysis_items_on_analysis_id"
  add_index "analysis_items", ["created_at"], :name => "index_analysis_items_on_created_at"
  add_index "analysis_items", ["creator_id"], :name => "index_analysis_items_on_creator_id"
  add_index "analysis_items", ["indicator_name"], :name => "index_analysis_items_on_indicator_name"
  add_index "analysis_items", ["product_reading_id"], :name => "index_analysis_items_on_product_reading_id"
  add_index "analysis_items", ["updated_at"], :name => "index_analysis_items_on_updated_at"
  add_index "analysis_items", ["updater_id"], :name => "index_analysis_items_on_updater_id"

  create_table "analytic_distributions", force: true do |t|
    t.integer  "production_id",                                               null: false
    t.integer  "journal_entry_item_id",                                       null: false
    t.string   "state",                                                       null: false
    t.datetime "affected_at",                                                 null: false
    t.decimal  "affectation_percentage", precision: 19, scale: 4,             null: false
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    default: 0, null: false
  end

  add_index "analytic_distributions", ["created_at"], :name => "index_analytic_distributions_on_created_at"
  add_index "analytic_distributions", ["creator_id"], :name => "index_analytic_distributions_on_creator_id"
  add_index "analytic_distributions", ["journal_entry_item_id"], :name => "index_analytic_distributions_on_journal_entry_item_id"
  add_index "analytic_distributions", ["production_id"], :name => "index_analytic_distributions_on_production_id"
  add_index "analytic_distributions", ["updated_at"], :name => "index_analytic_distributions_on_updated_at"
  add_index "analytic_distributions", ["updater_id"], :name => "index_analytic_distributions_on_updater_id"

  create_table "attachments", force: true do |t|
    t.integer  "resource_id",               null: false
    t.string   "resource_type",             null: false
    t.integer  "document_id",               null: false
    t.string   "nature",                    null: false
    t.datetime "expired_at"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",  default: 0, null: false
  end

  add_index "attachments", ["created_at"], :name => "index_attachments_on_created_at"
  add_index "attachments", ["creator_id"], :name => "index_attachments_on_creator_id"
  add_index "attachments", ["document_id"], :name => "index_attachments_on_document_id"
  add_index "attachments", ["resource_id", "resource_type"], :name => "index_attachments_on_resource_id_and_resource_type"
  add_index "attachments", ["updated_at"], :name => "index_attachments_on_updated_at"
  add_index "attachments", ["updater_id"], :name => "index_attachments_on_updater_id"

  create_table "bank_statements", force: true do |t|
    t.integer  "cash_id",                                                       null: false
    t.datetime "started_at",                                                    null: false
    t.datetime "stopped_at",                                                    null: false
    t.string   "number",                                                        null: false
    t.decimal  "debit",                  precision: 19, scale: 4, default: 0.0, null: false
    t.decimal  "credit",                 precision: 19, scale: 4, default: 0.0, null: false
    t.string   "currency",     limit: 3,                                        null: false
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    default: 0,   null: false
  end

  add_index "bank_statements", ["cash_id"], :name => "index_bank_statements_on_cash_id"
  add_index "bank_statements", ["created_at"], :name => "index_bank_statements_on_created_at"
  add_index "bank_statements", ["creator_id"], :name => "index_bank_statements_on_creator_id"
  add_index "bank_statements", ["updated_at"], :name => "index_bank_statements_on_updated_at"
  add_index "bank_statements", ["updater_id"], :name => "index_bank_statements_on_updater_id"

  create_table "budget_items", force: true do |t|
    t.integer  "budget_id",                                                    null: false
    t.integer  "production_support_id"
    t.decimal  "quantity",              precision: 19, scale: 4, default: 1.0, null: false
    t.decimal  "global_amount",         precision: 19, scale: 4, default: 0.0, null: false
    t.string   "currency"
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                   default: 0,   null: false
  end

  add_index "budget_items", ["budget_id"], :name => "index_budget_items_on_budget_id"
  add_index "budget_items", ["created_at"], :name => "index_budget_items_on_created_at"
  add_index "budget_items", ["creator_id"], :name => "index_budget_items_on_creator_id"
  add_index "budget_items", ["production_support_id"], :name => "index_budget_items_on_production_support_id"
  add_index "budget_items", ["updated_at"], :name => "index_budget_items_on_updated_at"
  add_index "budget_items", ["updater_id"], :name => "index_budget_items_on_updater_id"

  create_table "budgets", force: true do |t|
    t.integer  "variant_id"
    t.integer  "production_id"
    t.string   "name"
    t.string   "direction"
    t.decimal  "global_amount",      precision: 19, scale: 4, default: 0.0
    t.decimal  "unit_amount",        precision: 19, scale: 4, default: 0.0
    t.decimal  "global_quantity",    precision: 19, scale: 4, default: 0.0
    t.string   "working_indicator"
    t.string   "working_unit"
    t.string   "computation_method"
    t.boolean  "homogeneous_values",                          default: false
    t.string   "currency"
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                default: 0,     null: false
  end

  add_index "budgets", ["created_at"], :name => "index_budgets_on_created_at"
  add_index "budgets", ["creator_id"], :name => "index_budgets_on_creator_id"
  add_index "budgets", ["name"], :name => "index_budgets_on_name"
  add_index "budgets", ["production_id"], :name => "index_budgets_on_production_id"
  add_index "budgets", ["updated_at"], :name => "index_budgets_on_updated_at"
  add_index "budgets", ["updater_id"], :name => "index_budgets_on_updater_id"
  add_index "budgets", ["variant_id"], :name => "index_budgets_on_variant_id"

  create_table "campaigns", force: true do |t|
    t.string   "name",                                    null: false
    t.text     "description"
    t.string   "number",       limit: 60,                 null: false
    t.integer  "harvest_year"
    t.boolean  "closed",                  default: false, null: false
    t.datetime "closed_at"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",            default: 0,     null: false
  end

  add_index "campaigns", ["created_at"], :name => "index_campaigns_on_created_at"
  add_index "campaigns", ["creator_id"], :name => "index_campaigns_on_creator_id"
  add_index "campaigns", ["updated_at"], :name => "index_campaigns_on_updated_at"
  add_index "campaigns", ["updater_id"], :name => "index_campaigns_on_updater_id"

  create_table "cash_sessions", force: true do |t|
    t.integer  "cash_id",                                                               null: false
    t.integer  "sequence_id"
    t.datetime "started_at",                                                            null: false
    t.datetime "stopped_at"
    t.string   "currency",             limit: 3
    t.decimal  "noticed_start_amount",           precision: 19, scale: 4, default: 0.0
    t.decimal  "noticed_stop_amount",            precision: 19, scale: 4, default: 0.0
    t.decimal  "expected_stop_amount",           precision: 19, scale: 4, default: 0.0
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                            default: 0,   null: false
  end

  add_index "cash_sessions", ["cash_id"], :name => "index_cash_sessions_on_cash_id"
  add_index "cash_sessions", ["created_at"], :name => "index_cash_sessions_on_created_at"
  add_index "cash_sessions", ["creator_id"], :name => "index_cash_sessions_on_creator_id"
  add_index "cash_sessions", ["sequence_id"], :name => "index_cash_sessions_on_sequence_id"
  add_index "cash_sessions", ["updated_at"], :name => "index_cash_sessions_on_updated_at"
  add_index "cash_sessions", ["updater_id"], :name => "index_cash_sessions_on_updater_id"

  create_table "cash_transfers", force: true do |t|
    t.string   "number",                                                                     null: false
    t.text     "description"
    t.datetime "transfered_at",                                                              null: false
    t.datetime "accounted_at"
    t.decimal  "emission_amount",                      precision: 19, scale: 4,              null: false
    t.string   "emission_currency",          limit: 3,                                       null: false
    t.integer  "emission_cash_id",                                                           null: false
    t.integer  "emission_journal_entry_id"
    t.decimal  "currency_rate",                        precision: 19, scale: 10,             null: false
    t.decimal  "reception_amount",                     precision: 19, scale: 4,              null: false
    t.string   "reception_currency",         limit: 3,                                       null: false
    t.integer  "reception_cash_id",                                                          null: false
    t.integer  "reception_journal_entry_id"
    t.datetime "created_at",                                                                 null: false
    t.datetime "updated_at",                                                                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                   default: 0, null: false
  end

  add_index "cash_transfers", ["created_at"], :name => "index_cash_transfers_on_created_at"
  add_index "cash_transfers", ["creator_id"], :name => "index_cash_transfers_on_creator_id"
  add_index "cash_transfers", ["emission_cash_id"], :name => "index_cash_transfers_on_emission_cash_id"
  add_index "cash_transfers", ["emission_journal_entry_id"], :name => "index_cash_transfers_on_emission_journal_entry_id"
  add_index "cash_transfers", ["reception_cash_id"], :name => "index_cash_transfers_on_reception_cash_id"
  add_index "cash_transfers", ["reception_journal_entry_id"], :name => "index_cash_transfers_on_reception_journal_entry_id"
  add_index "cash_transfers", ["updated_at"], :name => "index_cash_transfers_on_updated_at"
  add_index "cash_transfers", ["updater_id"], :name => "index_cash_transfers_on_updater_id"

  create_table "cashes", force: true do |t|
    t.string   "name",                                                     null: false
    t.string   "nature",               limit: 20, default: "bank_account", null: false
    t.integer  "journal_id",                                               null: false
    t.integer  "account_id",                                               null: false
    t.string   "bank_code"
    t.string   "bank_agency_code"
    t.string   "bank_account_number"
    t.string   "bank_account_key"
    t.text     "bank_agency_address"
    t.string   "bank_name",            limit: 50
    t.string   "mode",                            default: "iban",         null: false
    t.string   "bank_identifier_code", limit: 11
    t.string   "iban",                 limit: 34
    t.string   "spaced_iban",          limit: 42
    t.string   "currency",             limit: 3,                           null: false
    t.string   "country",              limit: 2
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                    default: 0,              null: false
    t.integer  "container_id"
    t.integer  "last_number"
    t.integer  "owner_id"
  end

  add_index "cashes", ["account_id"], :name => "index_cashes_on_account_id"
  add_index "cashes", ["container_id"], :name => "index_cashes_on_container_id"
  add_index "cashes", ["created_at"], :name => "index_cashes_on_created_at"
  add_index "cashes", ["creator_id"], :name => "index_cashes_on_creator_id"
  add_index "cashes", ["journal_id"], :name => "index_cashes_on_journal_id"
  add_index "cashes", ["owner_id"], :name => "index_cashes_on_owner_id"
  add_index "cashes", ["updated_at"], :name => "index_cashes_on_updated_at"
  add_index "cashes", ["updater_id"], :name => "index_cashes_on_updater_id"

  create_table "catalog_items", force: true do |t|
    t.string   "name",                                                                      null: false
    t.integer  "variant_id",                                                                null: false
    t.integer  "catalog_id",                                                                null: false
    t.integer  "reference_tax_id"
    t.decimal  "amount",                           precision: 19, scale: 4,                 null: false
    t.boolean  "all_taxes_included",                                        default: false, null: false
    t.string   "currency",               limit: 3,                                          null: false
    t.datetime "created_at",                                                                null: false
    t.datetime "updated_at",                                                                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                              default: 0,     null: false
    t.text     "commercial_description"
    t.string   "commercial_name"
  end

  add_index "catalog_items", ["catalog_id", "variant_id"], :name => "index_catalog_items_on_catalog_id_and_variant_id", :unique => true
  add_index "catalog_items", ["catalog_id"], :name => "index_catalog_items_on_catalog_id"
  add_index "catalog_items", ["created_at"], :name => "index_catalog_items_on_created_at"
  add_index "catalog_items", ["creator_id"], :name => "index_catalog_items_on_creator_id"
  add_index "catalog_items", ["reference_tax_id"], :name => "index_catalog_items_on_reference_tax_id"
  add_index "catalog_items", ["updated_at"], :name => "index_catalog_items_on_updated_at"
  add_index "catalog_items", ["updater_id"], :name => "index_catalog_items_on_updater_id"
  add_index "catalog_items", ["variant_id"], :name => "index_catalog_items_on_variant_id"

  create_table "catalogs", force: true do |t|
    t.string   "name",                                          null: false
    t.string   "usage",              limit: 20,                 null: false
    t.string   "code",               limit: 20,                 null: false
    t.boolean  "by_default",                    default: false, null: false
    t.boolean  "all_taxes_included",            default: false, null: false
    t.string   "currency",           limit: 3,                  null: false
    t.text     "description"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                  default: 0,     null: false
  end

  add_index "catalogs", ["created_at"], :name => "index_catalogs_on_created_at"
  add_index "catalogs", ["creator_id"], :name => "index_catalogs_on_creator_id"
  add_index "catalogs", ["updated_at"], :name => "index_catalogs_on_updated_at"
  add_index "catalogs", ["updater_id"], :name => "index_catalogs_on_updater_id"

  create_table "crumbs", force: true do |t|
    t.integer  "user_id"
    t.datetime "read_at",                                                                                         null: false
    t.decimal  "accuracy",                                                   precision: 19, scale: 4,             null: false
    t.string   "nature",                                                                                          null: false
    t.text     "metadata"
    t.datetime "created_at",                                                                                      null: false
    t.datetime "updated_at",                                                                                      null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                        default: 0, null: false
    t.spatial  "geolocation",          limit: {:srid=>4326, :type=>"point"},                                      null: false
    t.integer  "intervention_cast_id"
    t.string   "device_uid",                                                                                      null: false
  end

  add_index "crumbs", ["created_at"], :name => "index_crumbs_on_created_at"
  add_index "crumbs", ["creator_id"], :name => "index_crumbs_on_creator_id"
  add_index "crumbs", ["intervention_cast_id"], :name => "index_crumbs_on_intervention_cast_id"
  add_index "crumbs", ["nature"], :name => "index_crumbs_on_nature"
  add_index "crumbs", ["read_at"], :name => "index_crumbs_on_read_at"
  add_index "crumbs", ["updated_at"], :name => "index_crumbs_on_updated_at"
  add_index "crumbs", ["updater_id"], :name => "index_crumbs_on_updater_id"
  add_index "crumbs", ["user_id"], :name => "index_crumbs_on_user_id"

  create_table "cultivable_zone_memberships", force: true do |t|
    t.integer  "group_id",                                                                                   null: false
    t.integer  "member_id",                                                                                  null: false
    t.decimal  "population",                                            precision: 19, scale: 4
    t.datetime "created_at",                                                                                 null: false
    t.datetime "updated_at",                                                                                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                   default: 0, null: false
    t.spatial  "shape",        limit: {:srid=>4326, :type=>"geometry"}
  end

  add_index "cultivable_zone_memberships", ["created_at"], :name => "index_cultivable_zone_memberships_on_created_at"
  add_index "cultivable_zone_memberships", ["creator_id"], :name => "index_cultivable_zone_memberships_on_creator_id"
  add_index "cultivable_zone_memberships", ["group_id"], :name => "index_cultivable_zone_memberships_on_group_id"
  add_index "cultivable_zone_memberships", ["member_id"], :name => "index_cultivable_zone_memberships_on_member_id"
  add_index "cultivable_zone_memberships", ["updated_at"], :name => "index_cultivable_zone_memberships_on_updated_at"
  add_index "cultivable_zone_memberships", ["updater_id"], :name => "index_cultivable_zone_memberships_on_updater_id"

  create_table "custom_field_choices", force: true do |t|
    t.integer  "custom_field_id",             null: false
    t.string   "name",                        null: false
    t.string   "value"
    t.integer  "position"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "custom_field_choices", ["created_at"], :name => "index_custom_field_choices_on_created_at"
  add_index "custom_field_choices", ["creator_id"], :name => "index_custom_field_choices_on_creator_id"
  add_index "custom_field_choices", ["custom_field_id"], :name => "index_custom_field_choices_on_custom_field_id"
  add_index "custom_field_choices", ["updated_at"], :name => "index_custom_field_choices_on_updated_at"
  add_index "custom_field_choices", ["updater_id"], :name => "index_custom_field_choices_on_updater_id"

  create_table "custom_fields", force: true do |t|
    t.string   "name",                                                                null: false
    t.string   "nature",          limit: 20,                                          null: false
    t.string   "column_name",                                                         null: false
    t.boolean  "active",                                              default: true,  null: false
    t.boolean  "required",                                            default: false, null: false
    t.integer  "maximal_length"
    t.decimal  "minimal_value",              precision: 19, scale: 4
    t.decimal  "maximal_value",              precision: 19, scale: 4
    t.string   "customized_type",                                                     null: false
    t.integer  "minimal_length"
    t.integer  "position"
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                        default: 0,     null: false
  end

  add_index "custom_fields", ["created_at"], :name => "index_custom_fields_on_created_at"
  add_index "custom_fields", ["creator_id"], :name => "index_custom_fields_on_creator_id"
  add_index "custom_fields", ["updated_at"], :name => "index_custom_fields_on_updated_at"
  add_index "custom_fields", ["updater_id"], :name => "index_custom_fields_on_updater_id"

  create_table "deposits", force: true do |t|
    t.string   "number",                                                    null: false
    t.integer  "cash_id",                                                   null: false
    t.integer  "mode_id",                                                   null: false
    t.decimal  "amount",           precision: 19, scale: 4, default: 0.0,   null: false
    t.integer  "payments_count",                            default: 0,     null: false
    t.text     "description"
    t.boolean  "locked",                                    default: false, null: false
    t.integer  "responsible_id"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                              default: 0,     null: false
  end

  add_index "deposits", ["cash_id"], :name => "index_deposits_on_cash_id"
  add_index "deposits", ["created_at"], :name => "index_deposits_on_created_at"
  add_index "deposits", ["creator_id"], :name => "index_deposits_on_creator_id"
  add_index "deposits", ["journal_entry_id"], :name => "index_deposits_on_journal_entry_id"
  add_index "deposits", ["mode_id"], :name => "index_deposits_on_mode_id"
  add_index "deposits", ["responsible_id"], :name => "index_deposits_on_responsible_id"
  add_index "deposits", ["updated_at"], :name => "index_deposits_on_updated_at"
  add_index "deposits", ["updater_id"], :name => "index_deposits_on_updater_id"

  create_table "districts", force: true do |t|
    t.string   "name",                     null: false
    t.string   "code"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", default: 0, null: false
  end

  add_index "districts", ["created_at"], :name => "index_districts_on_created_at"
  add_index "districts", ["creator_id"], :name => "index_districts_on_creator_id"
  add_index "districts", ["updated_at"], :name => "index_districts_on_updated_at"
  add_index "districts", ["updater_id"], :name => "index_districts_on_updater_id"

  create_table "document_archives", force: true do |t|
    t.integer  "document_id",                   null: false
    t.datetime "archived_at",                   null: false
    t.integer  "template_id"
    t.string   "file_file_name"
    t.integer  "file_file_size"
    t.string   "file_content_type"
    t.datetime "file_updated_at"
    t.string   "file_fingerprint"
    t.integer  "file_pages_count"
    t.text     "file_content_text"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",      default: 0, null: false
  end

  add_index "document_archives", ["archived_at"], :name => "index_document_archives_on_archived_at"
  add_index "document_archives", ["created_at"], :name => "index_document_archives_on_created_at"
  add_index "document_archives", ["creator_id"], :name => "index_document_archives_on_creator_id"
  add_index "document_archives", ["document_id"], :name => "index_document_archives_on_document_id"
  add_index "document_archives", ["template_id"], :name => "index_document_archives_on_template_id"
  add_index "document_archives", ["updated_at"], :name => "index_document_archives_on_updated_at"
  add_index "document_archives", ["updater_id"], :name => "index_document_archives_on_updater_id"

  create_table "document_templates", force: true do |t|
    t.string   "name",                                    null: false
    t.boolean  "active",                  default: false, null: false
    t.boolean  "by_default",              default: false, null: false
    t.string   "nature",       limit: 60,                 null: false
    t.string   "language",     limit: 3,                  null: false
    t.string   "archiving",    limit: 60,                 null: false
    t.boolean  "managed",                 default: false, null: false
    t.string   "formats"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",            default: 0,     null: false
  end

  add_index "document_templates", ["created_at"], :name => "index_document_templates_on_created_at"
  add_index "document_templates", ["creator_id"], :name => "index_document_templates_on_creator_id"
  add_index "document_templates", ["updated_at"], :name => "index_document_templates_on_updated_at"
  add_index "document_templates", ["updater_id"], :name => "index_document_templates_on_updater_id"

  create_table "documents", force: true do |t|
    t.string   "number",         limit: 60,              null: false
    t.string   "name",                                   null: false
    t.string   "nature",         limit: 120,             null: false
    t.string   "key",                                    null: false
    t.integer  "archives_count",             default: 0, null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               default: 0, null: false
  end

  add_index "documents", ["created_at"], :name => "index_documents_on_created_at"
  add_index "documents", ["creator_id"], :name => "index_documents_on_creator_id"
  add_index "documents", ["name"], :name => "index_documents_on_name"
  add_index "documents", ["nature", "key"], :name => "index_documents_on_nature_and_key", :unique => true
  add_index "documents", ["nature"], :name => "index_documents_on_nature"
  add_index "documents", ["number"], :name => "index_documents_on_number"
  add_index "documents", ["updated_at"], :name => "index_documents_on_updated_at"
  add_index "documents", ["updater_id"], :name => "index_documents_on_updater_id"

  create_table "entities", force: true do |t|
    t.string   "type"
    t.string   "nature",                                               null: false
    t.string   "last_name",                                            null: false
    t.string   "first_name"
    t.string   "full_name",                                            null: false
    t.string   "number",                    limit: 60
    t.boolean  "active",                               default: true,  null: false
    t.datetime "born_at"
    t.datetime "dead_at"
    t.boolean  "client",                               default: false, null: false
    t.integer  "client_account_id"
    t.boolean  "supplier",                             default: false, null: false
    t.integer  "supplier_account_id"
    t.boolean  "transporter",                          default: false, null: false
    t.boolean  "prospect",                             default: false, null: false
    t.boolean  "vat_subjected",                        default: true,  null: false
    t.boolean  "reminder_submissive",                  default: false, null: false
    t.string   "deliveries_conditions",     limit: 60
    t.text     "description"
    t.string   "language",                  limit: 3,                  null: false
    t.string   "country",                   limit: 2
    t.string   "currency",                                             null: false
    t.integer  "authorized_payments_count"
    t.integer  "responsible_id"
    t.integer  "proposer_id"
    t.string   "meeting_origin"
    t.datetime "first_met_at"
    t.string   "activity_code",             limit: 30
    t.string   "vat_number",                limit: 20
    t.string   "siren",                     limit: 9
    t.boolean  "locked",                               default: false, null: false
    t.boolean  "of_company",                           default: false, null: false
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                         default: 0,     null: false
  end

  add_index "entities", ["client_account_id"], :name => "index_entities_on_client_account_id"
  add_index "entities", ["created_at"], :name => "index_entities_on_created_at"
  add_index "entities", ["creator_id"], :name => "index_entities_on_creator_id"
  add_index "entities", ["full_name"], :name => "index_entities_on_full_name"
  add_index "entities", ["number"], :name => "index_entities_on_number"
  add_index "entities", ["of_company"], :name => "index_entities_on_of_company"
  add_index "entities", ["proposer_id"], :name => "index_entities_on_proposer_id"
  add_index "entities", ["responsible_id"], :name => "index_entities_on_responsible_id"
  add_index "entities", ["supplier_account_id"], :name => "index_entities_on_supplier_account_id"
  add_index "entities", ["updated_at"], :name => "index_entities_on_updated_at"
  add_index "entities", ["updater_id"], :name => "index_entities_on_updater_id"

  create_table "entity_addresses", force: true do |t|
    t.integer  "entity_id",                                                                 null: false
    t.string   "canal",               limit: 20,                                            null: false
    t.string   "coordinate",          limit: 500,                                           null: false
    t.boolean  "by_default",                                                default: false, null: false
    t.datetime "deleted_at"
    t.string   "thread",              limit: 10
    t.string   "name"
    t.string   "mail_line_1"
    t.string   "mail_line_2"
    t.string   "mail_line_3"
    t.string   "mail_line_4"
    t.string   "mail_line_5"
    t.string   "mail_line_6"
    t.string   "mail_country",        limit: 2
    t.integer  "mail_postal_zone_id"
    t.boolean  "mail_auto_update",                                          default: false, null: false
    t.datetime "created_at",                                                                null: false
    t.datetime "updated_at",                                                                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                              default: 0,     null: false
    t.spatial  "mail_geolocation",    limit: {:srid=>4326, :type=>"point"}
  end

  add_index "entity_addresses", ["by_default"], :name => "index_entity_addresses_on_by_default"
  add_index "entity_addresses", ["created_at"], :name => "index_entity_addresses_on_created_at"
  add_index "entity_addresses", ["creator_id"], :name => "index_entity_addresses_on_creator_id"
  add_index "entity_addresses", ["deleted_at"], :name => "index_entity_addresses_on_deleted_at"
  add_index "entity_addresses", ["entity_id"], :name => "index_entity_addresses_on_entity_id"
  add_index "entity_addresses", ["mail_postal_zone_id"], :name => "index_entity_addresses_on_mail_postal_zone_id"
  add_index "entity_addresses", ["thread"], :name => "index_entity_addresses_on_thread"
  add_index "entity_addresses", ["updated_at"], :name => "index_entity_addresses_on_updated_at"
  add_index "entity_addresses", ["updater_id"], :name => "index_entity_addresses_on_updater_id"

  create_table "entity_links", force: true do |t|
    t.string   "nature",                    null: false
    t.integer  "entity_1_id",               null: false
    t.string   "entity_1_role",             null: false
    t.integer  "entity_2_id",               null: false
    t.string   "entity_2_role",             null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.text     "description"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",  default: 0, null: false
  end

  add_index "entity_links", ["created_at"], :name => "index_entity_links_on_created_at"
  add_index "entity_links", ["creator_id"], :name => "index_entity_links_on_creator_id"
  add_index "entity_links", ["entity_1_id"], :name => "index_entity_links_on_entity_1_id"
  add_index "entity_links", ["entity_1_role"], :name => "index_entity_links_on_entity_1_role"
  add_index "entity_links", ["entity_2_id"], :name => "index_entity_links_on_entity_2_id"
  add_index "entity_links", ["entity_2_role"], :name => "index_entity_links_on_entity_2_role"
  add_index "entity_links", ["nature"], :name => "index_entity_links_on_nature"
  add_index "entity_links", ["updated_at"], :name => "index_entity_links_on_updated_at"
  add_index "entity_links", ["updater_id"], :name => "index_entity_links_on_updater_id"

  create_table "entity_versions", force: true do |t|
    t.string   "event",        null: false
    t.integer  "item_id"
    t.text     "item_object"
    t.text     "item_changes"
    t.datetime "created_at",   null: false
    t.integer  "creator_id"
    t.string   "creator_name"
  end

  create_table "establishments", force: true do |t|
    t.string   "name",                     null: false
    t.string   "code"
    t.text     "description"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", default: 0, null: false
  end

  add_index "establishments", ["created_at"], :name => "index_establishments_on_created_at"
  add_index "establishments", ["creator_id"], :name => "index_establishments_on_creator_id"
  add_index "establishments", ["updated_at"], :name => "index_establishments_on_updated_at"
  add_index "establishments", ["updater_id"], :name => "index_establishments_on_updater_id"

  create_table "event_participations", force: true do |t|
    t.integer  "event_id",                   null: false
    t.integer  "participant_id",             null: false
    t.string   "state"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   default: 0, null: false
  end

  add_index "event_participations", ["created_at"], :name => "index_event_participations_on_created_at"
  add_index "event_participations", ["creator_id"], :name => "index_event_participations_on_creator_id"
  add_index "event_participations", ["event_id"], :name => "index_event_participations_on_event_id"
  add_index "event_participations", ["participant_id"], :name => "index_event_participations_on_participant_id"
  add_index "event_participations", ["updated_at"], :name => "index_event_participations_on_updated_at"
  add_index "event_participations", ["updater_id"], :name => "index_event_participations_on_updater_id"

  create_table "events", force: true do |t|
    t.string   "name",                         null: false
    t.datetime "started_at",                   null: false
    t.datetime "stopped_at"
    t.boolean  "restricted",   default: false, null: false
    t.integer  "duration"
    t.string   "place"
    t.text     "description"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", default: 0,     null: false
    t.string   "nature",                       null: false
  end

  add_index "events", ["created_at"], :name => "index_events_on_created_at"
  add_index "events", ["creator_id"], :name => "index_events_on_creator_id"
  add_index "events", ["updated_at"], :name => "index_events_on_updated_at"
  add_index "events", ["updater_id"], :name => "index_events_on_updater_id"

  create_table "financial_asset_depreciations", force: true do |t|
    t.integer  "financial_asset_id",                                          null: false
    t.integer  "journal_entry_id"
    t.boolean  "accountable",                                 default: false, null: false
    t.datetime "accounted_at"
    t.date     "started_on",                                                  null: false
    t.date     "stopped_on",                                                  null: false
    t.decimal  "amount",             precision: 19, scale: 4,                 null: false
    t.integer  "position"
    t.boolean  "locked",                                      default: false, null: false
    t.integer  "financial_year_id"
    t.decimal  "depreciable_amount", precision: 19, scale: 4
    t.decimal  "depreciated_amount", precision: 19, scale: 4
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                default: 0,     null: false
  end

  add_index "financial_asset_depreciations", ["created_at"], :name => "index_financial_asset_depreciations_on_created_at"
  add_index "financial_asset_depreciations", ["creator_id"], :name => "index_financial_asset_depreciations_on_creator_id"
  add_index "financial_asset_depreciations", ["financial_asset_id"], :name => "index_financial_asset_depreciations_on_financial_asset_id"
  add_index "financial_asset_depreciations", ["financial_year_id"], :name => "index_financial_asset_depreciations_on_financial_year_id"
  add_index "financial_asset_depreciations", ["journal_entry_id"], :name => "index_financial_asset_depreciations_on_journal_entry_id"
  add_index "financial_asset_depreciations", ["updated_at"], :name => "index_financial_asset_depreciations_on_updated_at"
  add_index "financial_asset_depreciations", ["updater_id"], :name => "index_financial_asset_depreciations_on_updater_id"

  create_table "financial_assets", force: true do |t|
    t.integer  "allocation_account_id",                                                  null: false
    t.integer  "journal_id",                                                             null: false
    t.string   "name",                                                                   null: false
    t.string   "number",                                                                 null: false
    t.text     "description"
    t.date     "purchased_on"
    t.integer  "purchase_id"
    t.integer  "purchase_item_id"
    t.boolean  "ceded"
    t.date     "ceded_on"
    t.integer  "sale_id"
    t.integer  "sale_item_id"
    t.decimal  "purchase_amount",                   precision: 19, scale: 4
    t.date     "started_on",                                                             null: false
    t.date     "stopped_on",                                                             null: false
    t.decimal  "depreciable_amount",                precision: 19, scale: 4,             null: false
    t.decimal  "depreciated_amount",                precision: 19, scale: 4,             null: false
    t.string   "depreciation_method",                                                    null: false
    t.string   "currency",                limit: 3,                                      null: false
    t.decimal  "current_amount",                    precision: 19, scale: 4
    t.integer  "charges_account_id"
    t.decimal  "depreciation_percentage",           precision: 19, scale: 4
    t.datetime "created_at",                                                             null: false
    t.datetime "updated_at",                                                             null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                               default: 0, null: false
  end

  add_index "financial_assets", ["allocation_account_id"], :name => "index_financial_assets_on_allocation_account_id"
  add_index "financial_assets", ["charges_account_id"], :name => "index_financial_assets_on_charges_account_id"
  add_index "financial_assets", ["created_at"], :name => "index_financial_assets_on_created_at"
  add_index "financial_assets", ["creator_id"], :name => "index_financial_assets_on_creator_id"
  add_index "financial_assets", ["journal_id"], :name => "index_financial_assets_on_journal_id"
  add_index "financial_assets", ["purchase_id"], :name => "index_financial_assets_on_purchase_id"
  add_index "financial_assets", ["purchase_item_id"], :name => "index_financial_assets_on_purchase_item_id"
  add_index "financial_assets", ["sale_id"], :name => "index_financial_assets_on_sale_id"
  add_index "financial_assets", ["sale_item_id"], :name => "index_financial_assets_on_sale_item_id"
  add_index "financial_assets", ["updated_at"], :name => "index_financial_assets_on_updated_at"
  add_index "financial_assets", ["updater_id"], :name => "index_financial_assets_on_updater_id"

  create_table "financial_years", force: true do |t|
    t.string   "code",                  limit: 20,                 null: false
    t.boolean  "closed",                           default: false, null: false
    t.date     "started_on",                                       null: false
    t.date     "stopped_on",                                       null: false
    t.string   "currency",              limit: 3,                  null: false
    t.integer  "currency_precision"
    t.integer  "last_journal_entry_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                     default: 0,     null: false
  end

  add_index "financial_years", ["created_at"], :name => "index_financial_years_on_created_at"
  add_index "financial_years", ["creator_id"], :name => "index_financial_years_on_creator_id"
  add_index "financial_years", ["last_journal_entry_id"], :name => "index_financial_years_on_last_journal_entry_id"
  add_index "financial_years", ["updated_at"], :name => "index_financial_years_on_updated_at"
  add_index "financial_years", ["updater_id"], :name => "index_financial_years_on_updater_id"

  create_table "gap_items", force: true do |t|
    t.integer  "gap_id",                                                         null: false
    t.decimal  "pretax_amount",           precision: 19, scale: 4, default: 0.0, null: false
    t.decimal  "amount",                  precision: 19, scale: 4, default: 0.0, null: false
    t.integer  "tax_id"
    t.string   "currency",      limit: 3,                                        null: false
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     default: 0,   null: false
  end

  add_index "gap_items", ["created_at"], :name => "index_gap_items_on_created_at"
  add_index "gap_items", ["creator_id"], :name => "index_gap_items_on_creator_id"
  add_index "gap_items", ["gap_id"], :name => "index_gap_items_on_gap_id"
  add_index "gap_items", ["tax_id"], :name => "index_gap_items_on_tax_id"
  add_index "gap_items", ["updated_at"], :name => "index_gap_items_on_updated_at"
  add_index "gap_items", ["updater_id"], :name => "index_gap_items_on_updater_id"

  create_table "gaps", force: true do |t|
    t.string   "number",                                                            null: false
    t.datetime "printed_at",                                                        null: false
    t.string   "direction",                                                         null: false
    t.integer  "affair_id",                                                         null: false
    t.integer  "entity_id",                                                         null: false
    t.string   "entity_role",                                                       null: false
    t.decimal  "pretax_amount",              precision: 19, scale: 4, default: 0.0, null: false
    t.decimal  "amount",                     precision: 19, scale: 4, default: 0.0, null: false
    t.string   "currency",         limit: 3,                                        null: false
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                        default: 0,   null: false
  end

  add_index "gaps", ["affair_id"], :name => "index_gaps_on_affair_id"
  add_index "gaps", ["created_at"], :name => "index_gaps_on_created_at"
  add_index "gaps", ["creator_id"], :name => "index_gaps_on_creator_id"
  add_index "gaps", ["direction"], :name => "index_gaps_on_direction"
  add_index "gaps", ["entity_id"], :name => "index_gaps_on_entity_id"
  add_index "gaps", ["journal_entry_id"], :name => "index_gaps_on_journal_entry_id"
  add_index "gaps", ["number"], :name => "index_gaps_on_number"
  add_index "gaps", ["updated_at"], :name => "index_gaps_on_updated_at"
  add_index "gaps", ["updater_id"], :name => "index_gaps_on_updater_id"

  create_table "georeadings", force: true do |t|
    t.string   "name",                                                              null: false
    t.string   "nature",                                                            null: false
    t.string   "number"
    t.text     "description"
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                          default: 0, null: false
    t.spatial  "content",      limit: {:srid=>4326, :type=>"geometry"},             null: false
  end

  add_index "georeadings", ["created_at"], :name => "index_georeadings_on_created_at"
  add_index "georeadings", ["creator_id"], :name => "index_georeadings_on_creator_id"
  add_index "georeadings", ["name"], :name => "index_georeadings_on_name"
  add_index "georeadings", ["nature"], :name => "index_georeadings_on_nature"
  add_index "georeadings", ["number"], :name => "index_georeadings_on_number"
  add_index "georeadings", ["updated_at"], :name => "index_georeadings_on_updated_at"
  add_index "georeadings", ["updater_id"], :name => "index_georeadings_on_updater_id"

  create_table "guide_analyses", force: true do |t|
    t.integer  "guide_id",                          null: false
    t.integer  "execution_number",                  null: false
    t.boolean  "latest",            default: false, null: false
    t.datetime "started_at",                        null: false
    t.datetime "stopped_at",                        null: false
    t.string   "acceptance_status",                 null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",      default: 0,     null: false
  end

  add_index "guide_analyses", ["created_at"], :name => "index_guide_analyses_on_created_at"
  add_index "guide_analyses", ["creator_id"], :name => "index_guide_analyses_on_creator_id"
  add_index "guide_analyses", ["guide_id"], :name => "index_guide_analyses_on_guide_id"
  add_index "guide_analyses", ["updated_at"], :name => "index_guide_analyses_on_updated_at"
  add_index "guide_analyses", ["updater_id"], :name => "index_guide_analyses_on_updater_id"

  create_table "guide_analysis_points", force: true do |t|
    t.integer  "analysis_id",                       null: false
    t.string   "reference_name",                    null: false
    t.string   "acceptance_status",                 null: false
    t.string   "advice_reference_name"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",          default: 0, null: false
  end

  add_index "guide_analysis_points", ["analysis_id"], :name => "index_guide_analysis_points_on_analysis_id"
  add_index "guide_analysis_points", ["created_at"], :name => "index_guide_analysis_points_on_created_at"
  add_index "guide_analysis_points", ["creator_id"], :name => "index_guide_analysis_points_on_creator_id"
  add_index "guide_analysis_points", ["updated_at"], :name => "index_guide_analysis_points_on_updated_at"
  add_index "guide_analysis_points", ["updater_id"], :name => "index_guide_analysis_points_on_updater_id"

  create_table "guides", force: true do |t|
    t.string   "name",                                          null: false
    t.string   "nature",                                        null: false
    t.boolean  "active",                        default: false, null: false
    t.boolean  "external",                      default: false, null: false
    t.string   "frequency",                                     null: false
    t.string   "reference_name"
    t.string   "reference_source_file_name"
    t.string   "reference_source_content_type"
    t.integer  "reference_source_file_size"
    t.datetime "reference_source_updated_at"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                  default: 0,     null: false
  end

  add_index "guides", ["created_at"], :name => "index_guides_on_created_at"
  add_index "guides", ["creator_id"], :name => "index_guides_on_creator_id"
  add_index "guides", ["updated_at"], :name => "index_guides_on_updated_at"
  add_index "guides", ["updater_id"], :name => "index_guides_on_updater_id"

  create_table "identifiers", force: true do |t|
    t.integer  "net_service_id"
    t.string   "nature",                     null: false
    t.string   "value",                      null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   default: 0, null: false
  end

  add_index "identifiers", ["created_at"], :name => "index_identifiers_on_created_at"
  add_index "identifiers", ["creator_id"], :name => "index_identifiers_on_creator_id"
  add_index "identifiers", ["nature"], :name => "index_identifiers_on_nature"
  add_index "identifiers", ["net_service_id"], :name => "index_identifiers_on_net_service_id"
  add_index "identifiers", ["updated_at"], :name => "index_identifiers_on_updated_at"
  add_index "identifiers", ["updater_id"], :name => "index_identifiers_on_updater_id"

  create_table "imports", force: true do |t|
    t.string   "state",                                                       null: false
    t.string   "nature",                                                      null: false
    t.string   "archive_file_name"
    t.string   "archive_content_type"
    t.integer  "archive_file_size"
    t.datetime "archive_updated_at"
    t.integer  "importer_id"
    t.datetime "imported_at"
    t.decimal  "progression_percentage", precision: 19, scale: 4
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                    default: 0, null: false
  end

  add_index "imports", ["created_at"], :name => "index_imports_on_created_at"
  add_index "imports", ["creator_id"], :name => "index_imports_on_creator_id"
  add_index "imports", ["imported_at"], :name => "index_imports_on_imported_at"
  add_index "imports", ["updated_at"], :name => "index_imports_on_updated_at"
  add_index "imports", ["updater_id"], :name => "index_imports_on_updater_id"

  create_table "incoming_deliveries", force: true do |t|
    t.string   "number",                                                null: false
    t.integer  "sender_id",                                             null: false
    t.string   "reference_number"
    t.integer  "purchase_id"
    t.integer  "address_id"
    t.datetime "received_at"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                              default: 0, null: false
    t.decimal  "net_mass",         precision: 19, scale: 4
    t.string   "mode"
  end

  add_index "incoming_deliveries", ["address_id"], :name => "index_incoming_deliveries_on_address_id"
  add_index "incoming_deliveries", ["created_at"], :name => "index_incoming_deliveries_on_created_at"
  add_index "incoming_deliveries", ["creator_id"], :name => "index_incoming_deliveries_on_creator_id"
  add_index "incoming_deliveries", ["purchase_id"], :name => "index_incoming_deliveries_on_purchase_id"
  add_index "incoming_deliveries", ["sender_id"], :name => "index_incoming_deliveries_on_sender_id"
  add_index "incoming_deliveries", ["updated_at"], :name => "index_incoming_deliveries_on_updated_at"
  add_index "incoming_deliveries", ["updater_id"], :name => "index_incoming_deliveries_on_updater_id"

  create_table "incoming_delivery_items", force: true do |t|
    t.integer  "delivery_id",                                                                                    null: false
    t.integer  "purchase_item_id"
    t.integer  "product_id",                                                                                     null: false
    t.decimal  "population",                                                precision: 19, scale: 4
    t.integer  "container_id"
    t.datetime "created_at",                                                                                     null: false
    t.datetime "updated_at",                                                                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                       default: 0, null: false
    t.spatial  "shape",            limit: {:srid=>4326, :type=>"geometry"}
    t.decimal  "net_mass",                                                  precision: 19, scale: 4
  end

  add_index "incoming_delivery_items", ["container_id"], :name => "index_incoming_delivery_items_on_container_id"
  add_index "incoming_delivery_items", ["created_at"], :name => "index_incoming_delivery_items_on_created_at"
  add_index "incoming_delivery_items", ["creator_id"], :name => "index_incoming_delivery_items_on_creator_id"
  add_index "incoming_delivery_items", ["delivery_id"], :name => "index_incoming_delivery_items_on_delivery_id"
  add_index "incoming_delivery_items", ["product_id"], :name => "index_incoming_delivery_items_on_product_id"
  add_index "incoming_delivery_items", ["purchase_item_id"], :name => "index_incoming_delivery_items_on_purchase_item_id"
  add_index "incoming_delivery_items", ["updated_at"], :name => "index_incoming_delivery_items_on_updated_at"
  add_index "incoming_delivery_items", ["updater_id"], :name => "index_incoming_delivery_items_on_updater_id"

  create_table "incoming_payment_modes", force: true do |t|
    t.string   "name",                    limit: 50,                                          null: false
    t.integer  "cash_id"
    t.boolean  "active",                                                      default: false
    t.integer  "position"
    t.boolean  "with_accounting",                                             default: false, null: false
    t.boolean  "with_commission",                                             default: false, null: false
    t.decimal  "commission_percentage",              precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "commission_base_amount",             precision: 19, scale: 4, default: 0.0,   null: false
    t.integer  "commission_account_id"
    t.boolean  "with_deposit",                                                default: false, null: false
    t.integer  "depositables_account_id"
    t.integer  "depositables_journal_id"
    t.boolean  "detail_payments",                                             default: false, null: false
    t.datetime "created_at",                                                                  null: false
    t.datetime "updated_at",                                                                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                default: 0,     null: false
  end

  add_index "incoming_payment_modes", ["cash_id"], :name => "index_incoming_payment_modes_on_cash_id"
  add_index "incoming_payment_modes", ["commission_account_id"], :name => "index_incoming_payment_modes_on_commission_account_id"
  add_index "incoming_payment_modes", ["created_at"], :name => "index_incoming_payment_modes_on_created_at"
  add_index "incoming_payment_modes", ["creator_id"], :name => "index_incoming_payment_modes_on_creator_id"
  add_index "incoming_payment_modes", ["depositables_account_id"], :name => "index_incoming_payment_modes_on_depositables_account_id"
  add_index "incoming_payment_modes", ["depositables_journal_id"], :name => "index_incoming_payment_modes_on_depositables_journal_id"
  add_index "incoming_payment_modes", ["updated_at"], :name => "index_incoming_payment_modes_on_updated_at"
  add_index "incoming_payment_modes", ["updater_id"], :name => "index_incoming_payment_modes_on_updater_id"

  create_table "incoming_payments", force: true do |t|
    t.datetime "paid_at"
    t.decimal  "amount",                          precision: 19, scale: 4,                 null: false
    t.integer  "mode_id",                                                                  null: false
    t.string   "bank_name"
    t.string   "bank_check_number"
    t.string   "bank_account_number"
    t.integer  "payer_id"
    t.datetime "to_bank_at",                                                               null: false
    t.integer  "deposit_id"
    t.integer  "responsible_id"
    t.boolean  "scheduled",                                                default: false, null: false
    t.boolean  "received",                                                 default: true,  null: false
    t.string   "number"
    t.datetime "accounted_at"
    t.text     "receipt"
    t.integer  "journal_entry_id"
    t.integer  "commission_account_id"
    t.decimal  "commission_amount",               precision: 19, scale: 4, default: 0.0,   null: false
    t.string   "currency",              limit: 3,                                          null: false
    t.boolean  "downpayment",                                              default: true,  null: false
    t.integer  "affair_id"
    t.datetime "created_at",                                                               null: false
    t.datetime "updated_at",                                                               null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                             default: 0,     null: false
  end

  add_index "incoming_payments", ["accounted_at"], :name => "index_incoming_payments_on_accounted_at"
  add_index "incoming_payments", ["affair_id"], :name => "index_incoming_payments_on_affair_id"
  add_index "incoming_payments", ["commission_account_id"], :name => "index_incoming_payments_on_commission_account_id"
  add_index "incoming_payments", ["created_at"], :name => "index_incoming_payments_on_created_at"
  add_index "incoming_payments", ["creator_id"], :name => "index_incoming_payments_on_creator_id"
  add_index "incoming_payments", ["deposit_id"], :name => "index_incoming_payments_on_deposit_id"
  add_index "incoming_payments", ["journal_entry_id"], :name => "index_incoming_payments_on_journal_entry_id"
  add_index "incoming_payments", ["mode_id"], :name => "index_incoming_payments_on_mode_id"
  add_index "incoming_payments", ["payer_id"], :name => "index_incoming_payments_on_payer_id"
  add_index "incoming_payments", ["responsible_id"], :name => "index_incoming_payments_on_responsible_id"
  add_index "incoming_payments", ["updated_at"], :name => "index_incoming_payments_on_updated_at"
  add_index "incoming_payments", ["updater_id"], :name => "index_incoming_payments_on_updater_id"

  create_table "intervention_casts", force: true do |t|
    t.integer  "intervention_id",                                                                                      null: false
    t.integer  "actor_id"
    t.integer  "variant_id"
    t.decimal  "population",                                                      precision: 19, scale: 4
    t.string   "roles",                  limit: 320
    t.string   "reference_name",                                                                                       null: false
    t.integer  "position",                                                                                             null: false
    t.datetime "created_at",                                                                                           null: false
    t.datetime "updated_at",                                                                                           null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                             default: 0, null: false
    t.spatial  "shape",                  limit: {:srid=>4326, :type=>"geometry"}
    t.integer  "event_participation_id"
    t.string   "nature",                                                                                               null: false
  end

  add_index "intervention_casts", ["actor_id"], :name => "index_intervention_casts_on_actor_id"
  add_index "intervention_casts", ["created_at"], :name => "index_intervention_casts_on_created_at"
  add_index "intervention_casts", ["creator_id"], :name => "index_intervention_casts_on_creator_id"
  add_index "intervention_casts", ["event_participation_id"], :name => "index_intervention_casts_on_event_participation_id"
  add_index "intervention_casts", ["intervention_id"], :name => "index_intervention_casts_on_intervention_id"
  add_index "intervention_casts", ["reference_name"], :name => "index_intervention_casts_on_reference_name"
  add_index "intervention_casts", ["updated_at"], :name => "index_intervention_casts_on_updated_at"
  add_index "intervention_casts", ["updater_id"], :name => "index_intervention_casts_on_updater_id"
  add_index "intervention_casts", ["variant_id"], :name => "index_intervention_casts_on_variant_id"

  create_table "interventions", force: true do |t|
    t.integer  "ressource_id"
    t.string   "ressource_type"
    t.integer  "provisional_intervention_id"
    t.integer  "production_support_id"
    t.boolean  "provisional",                 default: false, null: false
    t.boolean  "recommended",                 default: false, null: false
    t.integer  "recommender_id"
    t.integer  "issue_id"
    t.integer  "prescription_id"
    t.integer  "production_id",                               null: false
    t.string   "reference_name",                              null: false
    t.string   "natures",                                     null: false
    t.string   "state",                                       null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                default: 0,     null: false
    t.integer  "event_id"
    t.string   "number"
    t.text     "parameters"
    t.text     "description"
  end

  add_index "interventions", ["created_at"], :name => "index_interventions_on_created_at"
  add_index "interventions", ["creator_id"], :name => "index_interventions_on_creator_id"
  add_index "interventions", ["event_id"], :name => "index_interventions_on_event_id"
  add_index "interventions", ["issue_id"], :name => "index_interventions_on_issue_id"
  add_index "interventions", ["prescription_id"], :name => "index_interventions_on_prescription_id"
  add_index "interventions", ["production_id"], :name => "index_interventions_on_production_id"
  add_index "interventions", ["production_support_id"], :name => "index_interventions_on_production_support_id"
  add_index "interventions", ["provisional_intervention_id"], :name => "index_interventions_on_provisional_intervention_id"
  add_index "interventions", ["recommender_id"], :name => "index_interventions_on_recommender_id"
  add_index "interventions", ["reference_name"], :name => "index_interventions_on_reference_name"
  add_index "interventions", ["ressource_id", "ressource_type"], :name => "index_interventions_on_ressource_id_and_ressource_type"
  add_index "interventions", ["started_at"], :name => "index_interventions_on_started_at"
  add_index "interventions", ["stopped_at"], :name => "index_interventions_on_stopped_at"
  add_index "interventions", ["updated_at"], :name => "index_interventions_on_updated_at"
  add_index "interventions", ["updater_id"], :name => "index_interventions_on_updater_id"

  create_table "inventories", force: true do |t|
    t.string   "number",           limit: 20
    t.datetime "reflected_at"
    t.boolean  "reflected",                   default: false, null: false
    t.integer  "responsible_id"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                default: 0,     null: false
    t.string   "name",                                        null: false
    t.datetime "achieved_at"
  end

  add_index "inventories", ["created_at"], :name => "index_inventories_on_created_at"
  add_index "inventories", ["creator_id"], :name => "index_inventories_on_creator_id"
  add_index "inventories", ["journal_entry_id"], :name => "index_inventories_on_journal_entry_id"
  add_index "inventories", ["responsible_id"], :name => "index_inventories_on_responsible_id"
  add_index "inventories", ["updated_at"], :name => "index_inventories_on_updated_at"
  add_index "inventories", ["updater_id"], :name => "index_inventories_on_updater_id"

  create_table "inventory_items", force: true do |t|
    t.integer  "inventory_id",                                                                                      null: false
    t.integer  "product_id",                                                                                        null: false
    t.decimal  "expected_population",                                          precision: 19, scale: 4,             null: false
    t.decimal  "actual_population",                                            precision: 19, scale: 4,             null: false
    t.datetime "created_at",                                                                                        null: false
    t.datetime "updated_at",                                                                                        null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                          default: 0, null: false
    t.spatial  "actual_shape",        limit: {:srid=>4326, :type=>"geometry"}
    t.spatial  "expected_shape",      limit: {:srid=>4326, :type=>"geometry"}
  end

  add_index "inventory_items", ["created_at"], :name => "index_inventory_items_on_created_at"
  add_index "inventory_items", ["creator_id"], :name => "index_inventory_items_on_creator_id"
  add_index "inventory_items", ["inventory_id"], :name => "index_inventory_items_on_inventory_id"
  add_index "inventory_items", ["product_id"], :name => "index_inventory_items_on_product_id"
  add_index "inventory_items", ["updated_at"], :name => "index_inventory_items_on_updated_at"
  add_index "inventory_items", ["updater_id"], :name => "index_inventory_items_on_updater_id"

  create_table "issue_versions", force: true do |t|
    t.string   "event",        null: false
    t.integer  "item_id"
    t.text     "item_object"
    t.text     "item_changes"
    t.datetime "created_at",   null: false
    t.integer  "creator_id"
    t.string   "creator_name"
  end

  create_table "issues", force: true do |t|
    t.integer  "target_id",                                                              null: false
    t.string   "target_type",                                                            null: false
    t.string   "nature",                                                                 null: false
    t.datetime "observed_at",                                                            null: false
    t.integer  "priority"
    t.integer  "gravity"
    t.string   "state"
    t.string   "name",                                                                   null: false
    t.text     "description"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.datetime "created_at",                                                             null: false
    t.datetime "updated_at",                                                             null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                               default: 0, null: false
    t.spatial  "geolocation",          limit: {:srid=>4326, :type=>"point"}
  end

  add_index "issues", ["created_at"], :name => "index_issues_on_created_at"
  add_index "issues", ["creator_id"], :name => "index_issues_on_creator_id"
  add_index "issues", ["name"], :name => "index_issues_on_name"
  add_index "issues", ["nature"], :name => "index_issues_on_nature"
  add_index "issues", ["target_id", "target_type"], :name => "index_issues_on_target_id_and_target_type"
  add_index "issues", ["updated_at"], :name => "index_issues_on_updated_at"
  add_index "issues", ["updater_id"], :name => "index_issues_on_updater_id"

  create_table "journal_entries", force: true do |t|
    t.integer  "journal_id",                                                            null: false
    t.integer  "financial_year_id"
    t.string   "number",                                                                null: false
    t.integer  "resource_id"
    t.string   "resource_type"
    t.string   "state",              limit: 30,                                         null: false
    t.date     "printed_on",                                                            null: false
    t.decimal  "real_debit",                    precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "real_credit",                   precision: 19, scale: 4,  default: 0.0, null: false
    t.string   "real_currency",      limit: 3,                                          null: false
    t.decimal  "real_currency_rate",            precision: 19, scale: 10, default: 0.0, null: false
    t.decimal  "debit",                         precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "credit",                        precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "balance",                       precision: 19, scale: 4,  default: 0.0, null: false
    t.string   "currency",           limit: 3,                                          null: false
    t.decimal  "absolute_debit",                precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "absolute_credit",               precision: 19, scale: 4,  default: 0.0, null: false
    t.string   "absolute_currency",  limit: 3,                                          null: false
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                            default: 0,   null: false
  end

  add_index "journal_entries", ["created_at"], :name => "index_journal_entries_on_created_at"
  add_index "journal_entries", ["creator_id"], :name => "index_journal_entries_on_creator_id"
  add_index "journal_entries", ["financial_year_id"], :name => "index_journal_entries_on_financial_year_id"
  add_index "journal_entries", ["journal_id"], :name => "index_journal_entries_on_journal_id"
  add_index "journal_entries", ["number"], :name => "index_journal_entries_on_number"
  add_index "journal_entries", ["resource_id", "resource_type"], :name => "index_journal_entries_on_resource_id_and_resource_type"
  add_index "journal_entries", ["updated_at"], :name => "index_journal_entries_on_updated_at"
  add_index "journal_entries", ["updater_id"], :name => "index_journal_entries_on_updater_id"

  create_table "journal_entry_items", force: true do |t|
    t.integer  "entry_id",                                                                     null: false
    t.integer  "journal_id",                                                                   null: false
    t.integer  "bank_statement_id"
    t.integer  "financial_year_id",                                                            null: false
    t.string   "state",                     limit: 30,                                         null: false
    t.date     "printed_on",                                                                   null: false
    t.string   "entry_number",                                                                 null: false
    t.string   "letter",                    limit: 10
    t.integer  "position"
    t.text     "description"
    t.integer  "account_id",                                                                   null: false
    t.string   "name",                                                                         null: false
    t.decimal  "real_debit",                           precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "real_credit",                          precision: 19, scale: 4,  default: 0.0, null: false
    t.string   "real_currency",             limit: 3,                                          null: false
    t.decimal  "real_currency_rate",                   precision: 19, scale: 10, default: 0.0, null: false
    t.decimal  "debit",                                precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "credit",                               precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "balance",                              precision: 19, scale: 4,  default: 0.0, null: false
    t.string   "currency",                  limit: 3,                                          null: false
    t.decimal  "absolute_debit",                       precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "absolute_credit",                      precision: 19, scale: 4,  default: 0.0, null: false
    t.string   "absolute_currency",         limit: 3,                                          null: false
    t.decimal  "cumulated_absolute_debit",             precision: 19, scale: 4,  default: 0.0, null: false
    t.decimal  "cumulated_absolute_credit",            precision: 19, scale: 4,  default: 0.0, null: false
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                   default: 0,   null: false
  end

  add_index "journal_entry_items", ["account_id"], :name => "index_journal_entry_items_on_account_id"
  add_index "journal_entry_items", ["bank_statement_id"], :name => "index_journal_entry_items_on_bank_statement_id"
  add_index "journal_entry_items", ["created_at"], :name => "index_journal_entry_items_on_created_at"
  add_index "journal_entry_items", ["creator_id"], :name => "index_journal_entry_items_on_creator_id"
  add_index "journal_entry_items", ["entry_id"], :name => "index_journal_entry_items_on_entry_id"
  add_index "journal_entry_items", ["financial_year_id"], :name => "index_journal_entry_items_on_financial_year_id"
  add_index "journal_entry_items", ["journal_id"], :name => "index_journal_entry_items_on_journal_id"
  add_index "journal_entry_items", ["letter"], :name => "index_journal_entry_items_on_letter"
  add_index "journal_entry_items", ["name"], :name => "index_journal_entry_items_on_name"
  add_index "journal_entry_items", ["updated_at"], :name => "index_journal_entry_items_on_updated_at"
  add_index "journal_entry_items", ["updater_id"], :name => "index_journal_entry_items_on_updater_id"

  create_table "journals", force: true do |t|
    t.string   "nature",           limit: 30,                 null: false
    t.string   "name",                                        null: false
    t.string   "code",             limit: 4,                  null: false
    t.date     "closed_on",                                   null: false
    t.string   "currency",         limit: 3,                  null: false
    t.boolean  "used_for_affairs",            default: false, null: false
    t.boolean  "used_for_gaps",               default: false, null: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                default: 0,     null: false
  end

  add_index "journals", ["created_at"], :name => "index_journals_on_created_at"
  add_index "journals", ["creator_id"], :name => "index_journals_on_creator_id"
  add_index "journals", ["updated_at"], :name => "index_journals_on_updated_at"
  add_index "journals", ["updater_id"], :name => "index_journals_on_updater_id"

  create_table "listing_node_items", force: true do |t|
    t.integer  "node_id",                             null: false
    t.string   "nature",       limit: 10,             null: false
    t.text     "value"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",            default: 0, null: false
  end

  add_index "listing_node_items", ["created_at"], :name => "index_listing_node_items_on_created_at"
  add_index "listing_node_items", ["creator_id"], :name => "index_listing_node_items_on_creator_id"
  add_index "listing_node_items", ["node_id"], :name => "index_listing_node_items_on_node_id"
  add_index "listing_node_items", ["updated_at"], :name => "index_listing_node_items_on_updated_at"
  add_index "listing_node_items", ["updater_id"], :name => "index_listing_node_items_on_updater_id"

  create_table "listing_nodes", force: true do |t|
    t.string   "name",                                           null: false
    t.string   "label",                                          null: false
    t.string   "nature",                                         null: false
    t.integer  "position"
    t.boolean  "exportable",                      default: true, null: false
    t.integer  "parent_id"
    t.string   "item_nature",          limit: 10
    t.text     "item_value"
    t.integer  "item_listing_id"
    t.integer  "item_listing_node_id"
    t.integer  "listing_id",                                     null: false
    t.string   "key"
    t.string   "sql_type"
    t.string   "condition_value"
    t.string   "condition_operator"
    t.string   "attribute_name"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth",                           default: 0,    null: false
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                    default: 0,    null: false
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

  create_table "listings", force: true do |t|
    t.string   "name",                     null: false
    t.string   "root_model",               null: false
    t.text     "query"
    t.text     "description"
    t.text     "story"
    t.text     "conditions"
    t.text     "mail"
    t.text     "source"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", default: 0, null: false
  end

  add_index "listings", ["created_at"], :name => "index_listings_on_created_at"
  add_index "listings", ["creator_id"], :name => "index_listings_on_creator_id"
  add_index "listings", ["name"], :name => "index_listings_on_name"
  add_index "listings", ["root_model"], :name => "index_listings_on_root_model"
  add_index "listings", ["updated_at"], :name => "index_listings_on_updated_at"
  add_index "listings", ["updater_id"], :name => "index_listings_on_updater_id"

  create_table "manure_management_plan_zones", force: true do |t|
    t.integer  "plan_id",                                                                              null: false
    t.integer  "support_id",                                                                           null: false
    t.string   "computation_method",                                                                   null: false
    t.string   "administrative_area"
    t.string   "cultivation_variety"
    t.string   "soil_nature"
    t.decimal  "expected_yield",                                  precision: 19, scale: 4
    t.decimal  "nitrogen_need",                                   precision: 19, scale: 4
    t.decimal  "absorbed_nitrogen_at_opening",                    precision: 19, scale: 4
    t.decimal  "mineral_nitrogen_at_opening",                     precision: 19, scale: 4
    t.decimal  "humus_mineralization",                            precision: 19, scale: 4
    t.decimal  "meadow_humus_mineralization",                     precision: 19, scale: 4
    t.decimal  "previous_cultivation_residue_mineralization",     precision: 19, scale: 4
    t.decimal  "intermediate_cultivation_residue_mineralization", precision: 19, scale: 4
    t.decimal  "irrigation_water_nitrogen",                       precision: 19, scale: 4
    t.decimal  "organic_fertilizer_mineral_fraction",             precision: 19, scale: 4
    t.decimal  "nitrogen_at_closing",                             precision: 19, scale: 4
    t.decimal  "soil_production",                                 precision: 19, scale: 4
    t.decimal  "nitrogen_input",                                  precision: 19, scale: 4
    t.datetime "created_at",                                                                           null: false
    t.datetime "updated_at",                                                                           null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                             default: 0, null: false
    t.decimal  "maximum_nitrogen_input",                          precision: 19, scale: 4
  end

  add_index "manure_management_plan_zones", ["created_at"], :name => "index_manure_management_plan_zones_on_created_at"
  add_index "manure_management_plan_zones", ["creator_id"], :name => "index_manure_management_plan_zones_on_creator_id"
  add_index "manure_management_plan_zones", ["plan_id"], :name => "index_manure_management_plan_zones_on_plan_id"
  add_index "manure_management_plan_zones", ["support_id"], :name => "index_manure_management_plan_zones_on_support_id"
  add_index "manure_management_plan_zones", ["updated_at"], :name => "index_manure_management_plan_zones_on_updated_at"
  add_index "manure_management_plan_zones", ["updater_id"], :name => "index_manure_management_plan_zones_on_updater_id"

  create_table "manure_management_plans", force: true do |t|
    t.string   "name",                                       null: false
    t.integer  "campaign_id",                                null: false
    t.integer  "recommender_id",                             null: false
    t.datetime "opened_at",                                  null: false
    t.string   "default_computation_method",                 null: false
    t.boolean  "locked",                     default: false, null: false
    t.boolean  "selected",                   default: false, null: false
    t.text     "annotation"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               default: 0,     null: false
  end

  add_index "manure_management_plans", ["campaign_id"], :name => "index_manure_management_plans_on_campaign_id"
  add_index "manure_management_plans", ["created_at"], :name => "index_manure_management_plans_on_created_at"
  add_index "manure_management_plans", ["creator_id"], :name => "index_manure_management_plans_on_creator_id"
  add_index "manure_management_plans", ["recommender_id"], :name => "index_manure_management_plans_on_recommender_id"
  add_index "manure_management_plans", ["updated_at"], :name => "index_manure_management_plans_on_updated_at"
  add_index "manure_management_plans", ["updater_id"], :name => "index_manure_management_plans_on_updater_id"

  create_table "net_services", force: true do |t|
    t.string   "reference_name",             null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   default: 0, null: false
  end

  add_index "net_services", ["created_at"], :name => "index_net_services_on_created_at"
  add_index "net_services", ["creator_id"], :name => "index_net_services_on_creator_id"
  add_index "net_services", ["reference_name"], :name => "index_net_services_on_reference_name"
  add_index "net_services", ["updated_at"], :name => "index_net_services_on_updated_at"
  add_index "net_services", ["updater_id"], :name => "index_net_services_on_updater_id"

  create_table "observations", force: true do |t|
    t.integer  "subject_id",                          null: false
    t.string   "subject_type",                        null: false
    t.string   "importance",   limit: 10,             null: false
    t.text     "content",                             null: false
    t.datetime "observed_at",                         null: false
    t.integer  "author_id",                           null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",            default: 0, null: false
  end

  add_index "observations", ["author_id"], :name => "index_observations_on_author_id"
  add_index "observations", ["created_at"], :name => "index_observations_on_created_at"
  add_index "observations", ["creator_id"], :name => "index_observations_on_creator_id"
  add_index "observations", ["subject_id", "subject_type"], :name => "index_observations_on_subject_id_and_subject_type"
  add_index "observations", ["updated_at"], :name => "index_observations_on_updated_at"
  add_index "observations", ["updater_id"], :name => "index_observations_on_updater_id"

  create_table "operations", force: true do |t|
    t.integer  "intervention_id",             null: false
    t.datetime "started_at",                  null: false
    t.datetime "stopped_at",                  null: false
    t.integer  "duration"
    t.string   "reference_name",              null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "operations", ["created_at"], :name => "index_operations_on_created_at"
  add_index "operations", ["creator_id"], :name => "index_operations_on_creator_id"
  add_index "operations", ["intervention_id"], :name => "index_operations_on_intervention_id"
  add_index "operations", ["reference_name"], :name => "index_operations_on_reference_name"
  add_index "operations", ["started_at"], :name => "index_operations_on_started_at"
  add_index "operations", ["stopped_at"], :name => "index_operations_on_stopped_at"
  add_index "operations", ["updated_at"], :name => "index_operations_on_updated_at"
  add_index "operations", ["updater_id"], :name => "index_operations_on_updater_id"

  create_table "outgoing_deliveries", force: true do |t|
    t.string   "number",                                                    null: false
    t.integer  "recipient_id",                                              null: false
    t.string   "reference_number"
    t.integer  "sale_id"
    t.integer  "address_id",                                                null: false
    t.datetime "sent_at"
    t.decimal  "net_mass",         precision: 19, scale: 4
    t.integer  "transport_id"
    t.integer  "transporter_id"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                              default: 0,     null: false
    t.boolean  "with_transport",                            default: false, null: false
    t.string   "mode",                                                      null: false
  end

  add_index "outgoing_deliveries", ["address_id"], :name => "index_outgoing_deliveries_on_address_id"
  add_index "outgoing_deliveries", ["created_at"], :name => "index_outgoing_deliveries_on_created_at"
  add_index "outgoing_deliveries", ["creator_id"], :name => "index_outgoing_deliveries_on_creator_id"
  add_index "outgoing_deliveries", ["recipient_id"], :name => "index_outgoing_deliveries_on_recipient_id"
  add_index "outgoing_deliveries", ["sale_id"], :name => "index_outgoing_deliveries_on_sale_id"
  add_index "outgoing_deliveries", ["transport_id"], :name => "index_outgoing_deliveries_on_transport_id"
  add_index "outgoing_deliveries", ["transporter_id"], :name => "index_outgoing_deliveries_on_transporter_id"
  add_index "outgoing_deliveries", ["updated_at"], :name => "index_outgoing_deliveries_on_updated_at"
  add_index "outgoing_deliveries", ["updater_id"], :name => "index_outgoing_deliveries_on_updater_id"

  create_table "outgoing_delivery_items", force: true do |t|
    t.integer  "delivery_id",                                                                                null: false
    t.integer  "sale_item_id"
    t.decimal  "population",                                            precision: 19, scale: 4
    t.integer  "product_id",                                                                                 null: false
    t.datetime "created_at",                                                                                 null: false
    t.datetime "updated_at",                                                                                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                   default: 0, null: false
    t.spatial  "shape",        limit: {:srid=>4326, :type=>"geometry"}
    t.decimal  "net_mass",                                              precision: 19, scale: 4
    t.integer  "container_id"
  end

  add_index "outgoing_delivery_items", ["container_id"], :name => "index_outgoing_delivery_items_on_container_id"
  add_index "outgoing_delivery_items", ["created_at"], :name => "index_outgoing_delivery_items_on_created_at"
  add_index "outgoing_delivery_items", ["creator_id"], :name => "index_outgoing_delivery_items_on_creator_id"
  add_index "outgoing_delivery_items", ["delivery_id"], :name => "index_outgoing_delivery_items_on_delivery_id"
  add_index "outgoing_delivery_items", ["product_id"], :name => "index_outgoing_delivery_items_on_product_id"
  add_index "outgoing_delivery_items", ["sale_item_id"], :name => "index_outgoing_delivery_items_on_sale_item_id"
  add_index "outgoing_delivery_items", ["updated_at"], :name => "index_outgoing_delivery_items_on_updated_at"
  add_index "outgoing_delivery_items", ["updater_id"], :name => "index_outgoing_delivery_items_on_updater_id"

  create_table "outgoing_payment_modes", force: true do |t|
    t.string   "name",            limit: 50,                 null: false
    t.boolean  "with_accounting",            default: false, null: false
    t.integer  "cash_id"
    t.integer  "position"
    t.boolean  "active",                     default: false, null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               default: 0,     null: false
  end

  add_index "outgoing_payment_modes", ["cash_id"], :name => "index_outgoing_payment_modes_on_cash_id"
  add_index "outgoing_payment_modes", ["created_at"], :name => "index_outgoing_payment_modes_on_created_at"
  add_index "outgoing_payment_modes", ["creator_id"], :name => "index_outgoing_payment_modes_on_creator_id"
  add_index "outgoing_payment_modes", ["updated_at"], :name => "index_outgoing_payment_modes_on_updated_at"
  add_index "outgoing_payment_modes", ["updater_id"], :name => "index_outgoing_payment_modes_on_updater_id"

  create_table "outgoing_payments", force: true do |t|
    t.datetime "accounted_at"
    t.decimal  "amount",                      precision: 19, scale: 4, default: 0.0,  null: false
    t.string   "bank_check_number"
    t.boolean  "delivered",                                            default: true, null: false
    t.integer  "journal_entry_id"
    t.integer  "responsible_id",                                                      null: false
    t.integer  "payee_id",                                                            null: false
    t.integer  "mode_id",                                                             null: false
    t.string   "number"
    t.datetime "paid_at"
    t.datetime "to_bank_at",                                                          null: false
    t.integer  "cash_id",                                                             null: false
    t.string   "currency",          limit: 3,                                         null: false
    t.boolean  "downpayment",                                          default: true, null: false
    t.integer  "affair_id"
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                         default: 0,    null: false
  end

  add_index "outgoing_payments", ["affair_id"], :name => "index_outgoing_payments_on_affair_id"
  add_index "outgoing_payments", ["cash_id"], :name => "index_outgoing_payments_on_cash_id"
  add_index "outgoing_payments", ["created_at"], :name => "index_outgoing_payments_on_created_at"
  add_index "outgoing_payments", ["creator_id"], :name => "index_outgoing_payments_on_creator_id"
  add_index "outgoing_payments", ["journal_entry_id"], :name => "index_outgoing_payments_on_journal_entry_id"
  add_index "outgoing_payments", ["mode_id"], :name => "index_outgoing_payments_on_mode_id"
  add_index "outgoing_payments", ["payee_id"], :name => "index_outgoing_payments_on_payee_id"
  add_index "outgoing_payments", ["responsible_id"], :name => "index_outgoing_payments_on_responsible_id"
  add_index "outgoing_payments", ["updated_at"], :name => "index_outgoing_payments_on_updated_at"
  add_index "outgoing_payments", ["updater_id"], :name => "index_outgoing_payments_on_updater_id"

  create_table "postal_zones", force: true do |t|
    t.string   "postal_code",                        null: false
    t.string   "name",                               null: false
    t.string   "country",      limit: 2,             null: false
    t.integer  "district_id"
    t.string   "city"
    t.string   "city_name"
    t.string   "code"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",           default: 0, null: false
  end

  add_index "postal_zones", ["created_at"], :name => "index_postal_zones_on_created_at"
  add_index "postal_zones", ["creator_id"], :name => "index_postal_zones_on_creator_id"
  add_index "postal_zones", ["district_id"], :name => "index_postal_zones_on_district_id"
  add_index "postal_zones", ["updated_at"], :name => "index_postal_zones_on_updated_at"
  add_index "postal_zones", ["updater_id"], :name => "index_postal_zones_on_updater_id"

  create_table "preferences", force: true do |t|
    t.string   "name",                                                              null: false
    t.string   "nature",            limit: 60,                                      null: false
    t.text     "string_value"
    t.boolean  "boolean_value"
    t.integer  "integer_value"
    t.decimal  "decimal_value",                precision: 19, scale: 4
    t.integer  "record_value_id"
    t.string   "record_value_type"
    t.integer  "user_id"
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                          default: 0, null: false
  end

  add_index "preferences", ["created_at"], :name => "index_preferences_on_created_at"
  add_index "preferences", ["creator_id"], :name => "index_preferences_on_creator_id"
  add_index "preferences", ["name"], :name => "index_preferences_on_name"
  add_index "preferences", ["record_value_id", "record_value_type"], :name => "index_preferences_on_record_value_id_and_record_value_type"
  add_index "preferences", ["updated_at"], :name => "index_preferences_on_updated_at"
  add_index "preferences", ["updater_id"], :name => "index_preferences_on_updater_id"
  add_index "preferences", ["user_id"], :name => "index_preferences_on_user_id"

  create_table "prescriptions", force: true do |t|
    t.integer  "prescriptor_id",               null: false
    t.string   "reference_number"
    t.datetime "delivered_at"
    t.text     "description"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     default: 0, null: false
  end

  add_index "prescriptions", ["created_at"], :name => "index_prescriptions_on_created_at"
  add_index "prescriptions", ["creator_id"], :name => "index_prescriptions_on_creator_id"
  add_index "prescriptions", ["delivered_at"], :name => "index_prescriptions_on_delivered_at"
  add_index "prescriptions", ["prescriptor_id"], :name => "index_prescriptions_on_prescriptor_id"
  add_index "prescriptions", ["reference_number"], :name => "index_prescriptions_on_reference_number"
  add_index "prescriptions", ["updated_at"], :name => "index_prescriptions_on_updated_at"
  add_index "prescriptions", ["updater_id"], :name => "index_prescriptions_on_updater_id"

  create_table "product_enjoyments", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "product_id",                  null: false
    t.string   "nature",                      null: false
    t.integer  "enjoyer_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "product_enjoyments", ["created_at"], :name => "index_product_enjoyments_on_created_at"
  add_index "product_enjoyments", ["creator_id"], :name => "index_product_enjoyments_on_creator_id"
  add_index "product_enjoyments", ["enjoyer_id"], :name => "index_product_enjoyments_on_enjoyer_id"
  add_index "product_enjoyments", ["operation_id"], :name => "index_product_enjoyments_on_operation_id"
  add_index "product_enjoyments", ["originator_id", "originator_type"], :name => "index_product_enjoyments_on_originator_id_and_originator_type"
  add_index "product_enjoyments", ["product_id"], :name => "index_product_enjoyments_on_product_id"
  add_index "product_enjoyments", ["started_at"], :name => "index_product_enjoyments_on_started_at"
  add_index "product_enjoyments", ["stopped_at"], :name => "index_product_enjoyments_on_stopped_at"
  add_index "product_enjoyments", ["updated_at"], :name => "index_product_enjoyments_on_updated_at"
  add_index "product_enjoyments", ["updater_id"], :name => "index_product_enjoyments_on_updater_id"

  create_table "product_junction_ways", force: true do |t|
    t.integer  "junction_id",                                                                                null: false
    t.string   "role",                                                                                       null: false
    t.string   "nature",                                                                                     null: false
    t.integer  "road_id",                                                                                    null: false
    t.decimal  "population",                                            precision: 19, scale: 4
    t.datetime "created_at",                                                                                 null: false
    t.datetime "updated_at",                                                                                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                   default: 0, null: false
    t.spatial  "shape",        limit: {:srid=>4326, :type=>"geometry"}
  end

  add_index "product_junction_ways", ["created_at"], :name => "index_product_junction_ways_on_created_at"
  add_index "product_junction_ways", ["creator_id"], :name => "index_product_junction_ways_on_creator_id"
  add_index "product_junction_ways", ["junction_id"], :name => "index_product_junction_ways_on_junction_id"
  add_index "product_junction_ways", ["nature"], :name => "index_product_junction_ways_on_nature"
  add_index "product_junction_ways", ["road_id"], :name => "index_product_junction_ways_on_road_id"
  add_index "product_junction_ways", ["role"], :name => "index_product_junction_ways_on_role"
  add_index "product_junction_ways", ["updated_at"], :name => "index_product_junction_ways_on_updated_at"
  add_index "product_junction_ways", ["updater_id"], :name => "index_product_junction_ways_on_updater_id"

  create_table "product_junctions", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.string   "type"
    t.integer  "tool_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "product_junctions", ["created_at"], :name => "index_product_junctions_on_created_at"
  add_index "product_junctions", ["creator_id"], :name => "index_product_junctions_on_creator_id"
  add_index "product_junctions", ["operation_id"], :name => "index_product_junctions_on_operation_id"
  add_index "product_junctions", ["originator_id", "originator_type"], :name => "index_product_junctions_on_originator_id_and_originator_type"
  add_index "product_junctions", ["started_at"], :name => "index_product_junctions_on_started_at"
  add_index "product_junctions", ["stopped_at"], :name => "index_product_junctions_on_stopped_at"
  add_index "product_junctions", ["tool_id"], :name => "index_product_junctions_on_tool_id"
  add_index "product_junctions", ["updated_at"], :name => "index_product_junctions_on_updated_at"
  add_index "product_junctions", ["updater_id"], :name => "index_product_junctions_on_updater_id"

  create_table "product_linkages", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "carrier_id",                  null: false
    t.string   "point",                       null: false
    t.string   "nature",                      null: false
    t.integer  "carried_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "product_linkages", ["carried_id"], :name => "index_product_linkages_on_carried_id"
  add_index "product_linkages", ["carrier_id"], :name => "index_product_linkages_on_carrier_id"
  add_index "product_linkages", ["created_at"], :name => "index_product_linkages_on_created_at"
  add_index "product_linkages", ["creator_id"], :name => "index_product_linkages_on_creator_id"
  add_index "product_linkages", ["operation_id"], :name => "index_product_linkages_on_operation_id"
  add_index "product_linkages", ["originator_id", "originator_type"], :name => "index_product_linkages_on_originator_id_and_originator_type"
  add_index "product_linkages", ["started_at"], :name => "index_product_linkages_on_started_at"
  add_index "product_linkages", ["stopped_at"], :name => "index_product_linkages_on_stopped_at"
  add_index "product_linkages", ["updated_at"], :name => "index_product_linkages_on_updated_at"
  add_index "product_linkages", ["updater_id"], :name => "index_product_linkages_on_updater_id"

  create_table "product_links", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "product_id",                  null: false
    t.string   "nature",                      null: false
    t.integer  "linked_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "product_links", ["created_at"], :name => "index_product_links_on_created_at"
  add_index "product_links", ["creator_id"], :name => "index_product_links_on_creator_id"
  add_index "product_links", ["linked_id"], :name => "index_product_links_on_linked_id"
  add_index "product_links", ["operation_id"], :name => "index_product_links_on_operation_id"
  add_index "product_links", ["originator_id", "originator_type"], :name => "index_product_links_on_originator_id_and_originator_type"
  add_index "product_links", ["product_id"], :name => "index_product_links_on_product_id"
  add_index "product_links", ["started_at"], :name => "index_product_links_on_started_at"
  add_index "product_links", ["stopped_at"], :name => "index_product_links_on_stopped_at"
  add_index "product_links", ["updated_at"], :name => "index_product_links_on_updated_at"
  add_index "product_links", ["updater_id"], :name => "index_product_links_on_updater_id"

  create_table "product_localizations", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "product_id",                  null: false
    t.string   "nature",                      null: false
    t.integer  "container_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "product_localizations", ["container_id"], :name => "index_product_localizations_on_container_id"
  add_index "product_localizations", ["created_at"], :name => "index_product_localizations_on_created_at"
  add_index "product_localizations", ["creator_id"], :name => "index_product_localizations_on_creator_id"
  add_index "product_localizations", ["operation_id"], :name => "index_product_localizations_on_operation_id"
  add_index "product_localizations", ["originator_id", "originator_type"], :name => "index_product_localizations_on_originator"
  add_index "product_localizations", ["product_id"], :name => "index_product_localizations_on_product_id"
  add_index "product_localizations", ["started_at"], :name => "index_product_localizations_on_started_at"
  add_index "product_localizations", ["stopped_at"], :name => "index_product_localizations_on_stopped_at"
  add_index "product_localizations", ["updated_at"], :name => "index_product_localizations_on_updated_at"
  add_index "product_localizations", ["updater_id"], :name => "index_product_localizations_on_updater_id"

  create_table "product_memberships", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "member_id",                   null: false
    t.string   "nature",                      null: false
    t.integer  "group_id",                    null: false
    t.datetime "started_at",                  null: false
    t.datetime "stopped_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "product_memberships", ["created_at"], :name => "index_product_memberships_on_created_at"
  add_index "product_memberships", ["creator_id"], :name => "index_product_memberships_on_creator_id"
  add_index "product_memberships", ["group_id"], :name => "index_product_memberships_on_group_id"
  add_index "product_memberships", ["member_id"], :name => "index_product_memberships_on_member_id"
  add_index "product_memberships", ["operation_id"], :name => "index_product_memberships_on_operation_id"
  add_index "product_memberships", ["originator_id", "originator_type"], :name => "index_product_memberships_on_originator_id_and_originator_type"
  add_index "product_memberships", ["started_at"], :name => "index_product_memberships_on_started_at"
  add_index "product_memberships", ["stopped_at"], :name => "index_product_memberships_on_stopped_at"
  add_index "product_memberships", ["updated_at"], :name => "index_product_memberships_on_updated_at"
  add_index "product_memberships", ["updater_id"], :name => "index_product_memberships_on_updater_id"

  create_table "product_nature_categories", force: true do |t|
    t.string   "name",                                                                                      null: false
    t.string   "number",                                                        limit: 30,                  null: false
    t.text     "description"
    t.string   "reference_name"
    t.string   "pictogram",                                                     limit: 120
    t.boolean  "active",                                                                    default: false, null: false
    t.boolean  "depreciable",                                                               default: false, null: false
    t.boolean  "saleable",                                                                  default: false, null: false
    t.boolean  "purchasable",                                                               default: false, null: false
    t.boolean  "storable",                                                                  default: false, null: false
    t.boolean  "reductible",                                                                default: false, null: false
    t.boolean  "subscribing",                                                               default: false, null: false
    t.integer  "subscription_nature_id"
    t.string   "subscription_duration"
    t.integer  "charge_account_id"
    t.integer  "product_account_id"
    t.integer  "financial_asset_account_id"
    t.integer  "stock_account_id"
    t.datetime "created_at",                                                                                null: false
    t.datetime "updated_at",                                                                                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                              default: 0,     null: false
    t.integer  "financial_asset_depreciations_account_id"
    t.integer  "financial_asset_depreciations_inputations_expenses_account_id"
  end

  add_index "product_nature_categories", ["charge_account_id"], :name => "index_product_nature_categories_on_charge_account_id"
  add_index "product_nature_categories", ["created_at"], :name => "index_product_nature_categories_on_created_at"
  add_index "product_nature_categories", ["creator_id"], :name => "index_product_nature_categories_on_creator_id"
  add_index "product_nature_categories", ["financial_asset_account_id"], :name => "index_product_nature_categories_on_financial_asset_account_id"
  add_index "product_nature_categories", ["name"], :name => "index_product_nature_categories_on_name"
  add_index "product_nature_categories", ["number"], :name => "index_product_nature_categories_on_number", :unique => true
  add_index "product_nature_categories", ["product_account_id"], :name => "index_product_nature_categories_on_product_account_id"
  add_index "product_nature_categories", ["stock_account_id"], :name => "index_product_nature_categories_on_stock_account_id"
  add_index "product_nature_categories", ["subscription_nature_id"], :name => "index_product_nature_categories_on_subscription_nature_id"
  add_index "product_nature_categories", ["updated_at"], :name => "index_product_nature_categories_on_updated_at"
  add_index "product_nature_categories", ["updater_id"], :name => "index_product_nature_categories_on_updater_id"

  create_table "product_nature_category_taxations", force: true do |t|
    t.integer  "product_nature_category_id",             null: false
    t.integer  "tax_id",                                 null: false
    t.string   "usage",                                  null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",               default: 0, null: false
  end

  add_index "product_nature_category_taxations", ["created_at"], :name => "index_product_nature_category_taxations_on_created_at"
  add_index "product_nature_category_taxations", ["creator_id"], :name => "index_product_nature_category_taxations_on_creator_id"
  add_index "product_nature_category_taxations", ["product_nature_category_id"], :name => "index_product_nature_category_taxations_on_category_id"
  add_index "product_nature_category_taxations", ["tax_id"], :name => "index_product_nature_category_taxations_on_tax_id"
  add_index "product_nature_category_taxations", ["updated_at"], :name => "index_product_nature_category_taxations_on_updated_at"
  add_index "product_nature_category_taxations", ["updater_id"], :name => "index_product_nature_category_taxations_on_updater_id"
  add_index "product_nature_category_taxations", ["usage"], :name => "index_product_nature_category_taxations_on_usage"

  create_table "product_nature_variant_readings", force: true do |t|
    t.integer  "variant_id",                                                                                                     null: false
    t.string   "indicator_name",                                                                                                 null: false
    t.string   "indicator_datatype",                                                                                             null: false
    t.decimal  "absolute_measure_value_value",                                          precision: 19, scale: 4
    t.string   "absolute_measure_value_unit"
    t.boolean  "boolean_value",                                                                                  default: false, null: false
    t.string   "choice_value"
    t.decimal  "decimal_value",                                                         precision: 19, scale: 4
    t.integer  "integer_value"
    t.decimal  "measure_value_value",                                                   precision: 19, scale: 4
    t.string   "measure_value_unit"
    t.text     "string_value"
    t.datetime "created_at",                                                                                                     null: false
    t.datetime "updated_at",                                                                                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                                   default: 0,     null: false
    t.spatial  "geometry_value",               limit: {:srid=>4326, :type=>"geometry"}
    t.spatial  "point_value",                  limit: {:srid=>4326, :type=>"point"}
  end

  add_index "product_nature_variant_readings", ["created_at"], :name => "index_product_nature_variant_readings_on_created_at"
  add_index "product_nature_variant_readings", ["creator_id"], :name => "index_product_nature_variant_readings_on_creator_id"
  add_index "product_nature_variant_readings", ["indicator_name"], :name => "index_product_nature_variant_readings_on_indicator_name"
  add_index "product_nature_variant_readings", ["updated_at"], :name => "index_product_nature_variant_readings_on_updated_at"
  add_index "product_nature_variant_readings", ["updater_id"], :name => "index_product_nature_variant_readings_on_updater_id"
  add_index "product_nature_variant_readings", ["variant_id"], :name => "index_product_nature_variant_readings_on_variant_id"

  create_table "product_nature_variants", force: true do |t|
    t.integer  "category_id",                                      null: false
    t.integer  "nature_id",                                        null: false
    t.string   "name"
    t.string   "number"
    t.string   "variety",              limit: 120,                 null: false
    t.string   "derivative_of",        limit: 120
    t.string   "reference_name"
    t.string   "unit_name",                                        null: false
    t.boolean  "active",                           default: false, null: false
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                     default: 0,     null: false
  end

  add_index "product_nature_variants", ["category_id"], :name => "index_product_nature_variants_on_category_id"
  add_index "product_nature_variants", ["created_at"], :name => "index_product_nature_variants_on_created_at"
  add_index "product_nature_variants", ["creator_id"], :name => "index_product_nature_variants_on_creator_id"
  add_index "product_nature_variants", ["nature_id"], :name => "index_product_nature_variants_on_nature_id"
  add_index "product_nature_variants", ["updated_at"], :name => "index_product_nature_variants_on_updated_at"
  add_index "product_nature_variants", ["updater_id"], :name => "index_product_nature_variants_on_updater_id"

  create_table "product_natures", force: true do |t|
    t.integer  "category_id",                                          null: false
    t.string   "name",                                                 null: false
    t.string   "number",                   limit: 30,                  null: false
    t.string   "variety",                  limit: 120,                 null: false
    t.string   "derivative_of",            limit: 120
    t.string   "reference_name",           limit: 120
    t.boolean  "active",                               default: false, null: false
    t.boolean  "evolvable",                            default: false, null: false
    t.string   "population_counting",                                  null: false
    t.text     "abilities_list"
    t.text     "variable_indicators_list"
    t.text     "frozen_indicators_list"
    t.text     "linkage_points_list"
    t.text     "derivatives_list"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.text     "description"
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                         default: 0,     null: false
  end

  add_index "product_natures", ["category_id"], :name => "index_product_natures_on_category_id"
  add_index "product_natures", ["created_at"], :name => "index_product_natures_on_created_at"
  add_index "product_natures", ["creator_id"], :name => "index_product_natures_on_creator_id"
  add_index "product_natures", ["name"], :name => "index_product_natures_on_name"
  add_index "product_natures", ["number"], :name => "index_product_natures_on_number", :unique => true
  add_index "product_natures", ["updated_at"], :name => "index_product_natures_on_updated_at"
  add_index "product_natures", ["updater_id"], :name => "index_product_natures_on_updater_id"

  create_table "product_ownerships", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "product_id",                  null: false
    t.string   "nature",                      null: false
    t.integer  "owner_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "product_ownerships", ["created_at"], :name => "index_product_ownerships_on_created_at"
  add_index "product_ownerships", ["creator_id"], :name => "index_product_ownerships_on_creator_id"
  add_index "product_ownerships", ["operation_id"], :name => "index_product_ownerships_on_operation_id"
  add_index "product_ownerships", ["originator_id", "originator_type"], :name => "index_product_ownerships_on_originator_id_and_originator_type"
  add_index "product_ownerships", ["owner_id"], :name => "index_product_ownerships_on_owner_id"
  add_index "product_ownerships", ["product_id"], :name => "index_product_ownerships_on_product_id"
  add_index "product_ownerships", ["started_at"], :name => "index_product_ownerships_on_started_at"
  add_index "product_ownerships", ["stopped_at"], :name => "index_product_ownerships_on_stopped_at"
  add_index "product_ownerships", ["updated_at"], :name => "index_product_ownerships_on_updated_at"
  add_index "product_ownerships", ["updater_id"], :name => "index_product_ownerships_on_updater_id"

  create_table "product_phases", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "product_id",                  null: false
    t.integer  "variant_id",                  null: false
    t.integer  "nature_id",                   null: false
    t.integer  "category_id",                 null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",    default: 0, null: false
  end

  add_index "product_phases", ["category_id"], :name => "index_product_phases_on_category_id"
  add_index "product_phases", ["created_at"], :name => "index_product_phases_on_created_at"
  add_index "product_phases", ["creator_id"], :name => "index_product_phases_on_creator_id"
  add_index "product_phases", ["nature_id"], :name => "index_product_phases_on_nature_id"
  add_index "product_phases", ["operation_id"], :name => "index_product_phases_on_operation_id"
  add_index "product_phases", ["originator_id", "originator_type"], :name => "index_product_phases_on_originator_id_and_originator_type"
  add_index "product_phases", ["product_id"], :name => "index_product_phases_on_product_id"
  add_index "product_phases", ["started_at"], :name => "index_product_phases_on_started_at"
  add_index "product_phases", ["stopped_at"], :name => "index_product_phases_on_stopped_at"
  add_index "product_phases", ["updated_at"], :name => "index_product_phases_on_updated_at"
  add_index "product_phases", ["updater_id"], :name => "index_product_phases_on_updater_id"
  add_index "product_phases", ["variant_id"], :name => "index_product_phases_on_variant_id"

  create_table "product_reading_tasks", force: true do |t|
    t.integer  "operation_id"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "product_id",                                                                                                     null: false
    t.string   "indicator_name",                                                                                                 null: false
    t.string   "indicator_datatype",                                                                                             null: false
    t.decimal  "absolute_measure_value_value",                                          precision: 19, scale: 4
    t.string   "absolute_measure_value_unit"
    t.boolean  "boolean_value",                                                                                  default: false, null: false
    t.string   "choice_value"
    t.decimal  "decimal_value",                                                         precision: 19, scale: 4
    t.integer  "integer_value"
    t.decimal  "measure_value_value",                                                   precision: 19, scale: 4
    t.string   "measure_value_unit"
    t.text     "string_value"
    t.integer  "reporter_id"
    t.integer  "tool_id"
    t.datetime "started_at",                                                                                                     null: false
    t.datetime "stopped_at"
    t.datetime "created_at",                                                                                                     null: false
    t.datetime "updated_at",                                                                                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                                   default: 0,     null: false
    t.spatial  "geometry_value",               limit: {:srid=>4326, :type=>"geometry"}
    t.spatial  "point_value",                  limit: {:srid=>4326, :type=>"point"}
  end

  add_index "product_reading_tasks", ["created_at"], :name => "index_product_reading_tasks_on_created_at"
  add_index "product_reading_tasks", ["creator_id"], :name => "index_product_reading_tasks_on_creator_id"
  add_index "product_reading_tasks", ["indicator_name"], :name => "index_product_reading_tasks_on_indicator_name"
  add_index "product_reading_tasks", ["operation_id"], :name => "index_product_reading_tasks_on_operation_id"
  add_index "product_reading_tasks", ["originator_id", "originator_type"], :name => "index_product_reading_tasks_on_originator"
  add_index "product_reading_tasks", ["product_id"], :name => "index_product_reading_tasks_on_product_id"
  add_index "product_reading_tasks", ["reporter_id"], :name => "index_product_reading_tasks_on_reporter_id"
  add_index "product_reading_tasks", ["started_at"], :name => "index_product_reading_tasks_on_started_at"
  add_index "product_reading_tasks", ["stopped_at"], :name => "index_product_reading_tasks_on_stopped_at"
  add_index "product_reading_tasks", ["tool_id"], :name => "index_product_reading_tasks_on_tool_id"
  add_index "product_reading_tasks", ["updated_at"], :name => "index_product_reading_tasks_on_updated_at"
  add_index "product_reading_tasks", ["updater_id"], :name => "index_product_reading_tasks_on_updater_id"

  create_table "product_readings", force: true do |t|
    t.integer  "originator_id"
    t.string   "originator_type"
    t.integer  "product_id",                                                                                                     null: false
    t.datetime "read_at",                                                                                                        null: false
    t.string   "indicator_name",                                                                                                 null: false
    t.string   "indicator_datatype",                                                                                             null: false
    t.decimal  "absolute_measure_value_value",                                          precision: 19, scale: 4
    t.string   "absolute_measure_value_unit"
    t.boolean  "boolean_value",                                                                                  default: false, null: false
    t.string   "choice_value"
    t.decimal  "decimal_value",                                                         precision: 19, scale: 4
    t.integer  "integer_value"
    t.decimal  "measure_value_value",                                                   precision: 19, scale: 4
    t.string   "measure_value_unit"
    t.text     "string_value"
    t.datetime "created_at",                                                                                                     null: false
    t.datetime "updated_at",                                                                                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                                   default: 0,     null: false
    t.spatial  "geometry_value",               limit: {:srid=>4326, :type=>"geometry"}
    t.spatial  "point_value",                  limit: {:srid=>4326, :type=>"point"}
  end

  add_index "product_readings", ["created_at"], :name => "index_product_readings_on_created_at"
  add_index "product_readings", ["creator_id"], :name => "index_product_readings_on_creator_id"
  add_index "product_readings", ["indicator_name"], :name => "index_product_readings_on_indicator_name"
  add_index "product_readings", ["originator_id", "originator_type"], :name => "index_product_readings_on_originator"
  add_index "product_readings", ["product_id"], :name => "index_product_readings_on_product_id"
  add_index "product_readings", ["read_at"], :name => "index_product_readings_on_read_at"
  add_index "product_readings", ["updated_at"], :name => "index_product_readings_on_updated_at"
  add_index "product_readings", ["updater_id"], :name => "index_product_readings_on_updater_id"

  create_table "product_versions", force: true do |t|
    t.string   "event",        null: false
    t.integer  "item_id"
    t.text     "item_object"
    t.text     "item_changes"
    t.datetime "created_at",   null: false
    t.integer  "creator_id"
    t.string   "creator_name"
  end

  add_index "product_versions", ["created_at"], :name => "index_product_versions_on_created_at"
  add_index "product_versions", ["creator_id"], :name => "index_product_versions_on_creator_id"

  create_table "production_support_markers", force: true do |t|
    t.integer  "support_id",                                                                                                     null: false
    t.string   "aim",                                                                                                            null: false
    t.string   "subject"
    t.string   "derivative"
    t.string   "indicator_name",                                                                                                 null: false
    t.string   "indicator_datatype",                                                                                             null: false
    t.decimal  "absolute_measure_value_value",                                          precision: 19, scale: 4
    t.string   "absolute_measure_value_unit"
    t.boolean  "boolean_value",                                                                                  default: false, null: false
    t.string   "choice_value"
    t.decimal  "decimal_value",                                                         precision: 19, scale: 4
    t.integer  "integer_value"
    t.decimal  "measure_value_value",                                                   precision: 19, scale: 4
    t.string   "measure_value_unit"
    t.text     "string_value"
    t.datetime "created_at",                                                                                                     null: false
    t.datetime "updated_at",                                                                                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                                   default: 0,     null: false
    t.spatial  "geometry_value",               limit: {:srid=>4326, :type=>"geometry"}
    t.spatial  "point_value",                  limit: {:srid=>4326, :type=>"point"}
  end

  add_index "production_support_markers", ["created_at"], :name => "index_production_support_markers_on_created_at"
  add_index "production_support_markers", ["creator_id"], :name => "index_production_support_markers_on_creator_id"
  add_index "production_support_markers", ["indicator_name"], :name => "index_production_support_markers_on_indicator_name"
  add_index "production_support_markers", ["support_id"], :name => "index_production_support_markers_on_support_id"
  add_index "production_support_markers", ["updated_at"], :name => "index_production_support_markers_on_updated_at"
  add_index "production_support_markers", ["updater_id"], :name => "index_production_support_markers_on_updater_id"

  create_table "production_supports", force: true do |t|
    t.integer  "production_id",                    null: false
    t.integer  "storage_id",                       null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.boolean  "exclusive",        default: false, null: false
    t.boolean  "irrigated",        default: false, null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     default: 0,     null: false
    t.string   "nature",                           null: false
    t.string   "production_usage",                 null: false
  end

  add_index "production_supports", ["created_at"], :name => "index_production_supports_on_created_at"
  add_index "production_supports", ["creator_id"], :name => "index_production_supports_on_creator_id"
  add_index "production_supports", ["production_id"], :name => "index_production_supports_on_production_id"
  add_index "production_supports", ["started_at"], :name => "index_production_supports_on_started_at"
  add_index "production_supports", ["stopped_at"], :name => "index_production_supports_on_stopped_at"
  add_index "production_supports", ["storage_id"], :name => "index_production_supports_on_storage_id"
  add_index "production_supports", ["updated_at"], :name => "index_production_supports_on_updated_at"
  add_index "production_supports", ["updater_id"], :name => "index_production_supports_on_updater_id"

  create_table "productions", force: true do |t|
    t.integer  "activity_id",                          null: false
    t.integer  "campaign_id",                          null: false
    t.integer  "variant_id"
    t.string   "name",                                 null: false
    t.string   "state",                                null: false
    t.boolean  "static_support",       default: false, null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.integer  "position"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",         default: 0,     null: false
    t.string   "working_indicator"
    t.string   "working_unit"
    t.integer  "support_variant_id"
    t.boolean  "homogeneous_expenses", default: false
    t.boolean  "homogeneous_revenues", default: false
  end

  add_index "productions", ["activity_id"], :name => "index_productions_on_activity_id"
  add_index "productions", ["campaign_id"], :name => "index_productions_on_campaign_id"
  add_index "productions", ["created_at"], :name => "index_productions_on_created_at"
  add_index "productions", ["creator_id"], :name => "index_productions_on_creator_id"
  add_index "productions", ["name"], :name => "index_productions_on_name"
  add_index "productions", ["started_at"], :name => "index_productions_on_started_at"
  add_index "productions", ["stopped_at"], :name => "index_productions_on_stopped_at"
  add_index "productions", ["support_variant_id"], :name => "index_productions_on_support_variant_id"
  add_index "productions", ["updated_at"], :name => "index_productions_on_updated_at"
  add_index "productions", ["updater_id"], :name => "index_productions_on_updater_id"
  add_index "productions", ["variant_id"], :name => "index_productions_on_variant_id"

  create_table "products", force: true do |t|
    t.string   "type"
    t.string   "name",                                                                                                    null: false
    t.string   "number",                                                                                                  null: false
    t.integer  "variant_id",                                                                                              null: false
    t.integer  "nature_id",                                                                                               null: false
    t.integer  "category_id",                                                                                             null: false
    t.boolean  "extjuncted",                                                                              default: false, null: false
    t.datetime "initial_born_at"
    t.datetime "initial_dead_at"
    t.integer  "initial_container_id"
    t.integer  "initial_owner_id"
    t.integer  "initial_enjoyer_id"
    t.decimal  "initial_population",                                             precision: 19, scale: 4, default: 0.0
    t.integer  "initial_father_id"
    t.integer  "initial_mother_id"
    t.string   "variety",               limit: 120,                                                                       null: false
    t.string   "derivative_of",         limit: 120
    t.integer  "tracking_id"
    t.integer  "financial_asset_id"
    t.datetime "born_at"
    t.datetime "dead_at"
    t.text     "description"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.string   "identification_number"
    t.string   "work_number"
    t.integer  "address_id"
    t.integer  "parent_id"
    t.integer  "default_storage_id"
    t.datetime "created_at",                                                                                              null: false
    t.datetime "updated_at",                                                                                              null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                                            default: 0,     null: false
    t.spatial  "initial_shape",         limit: {:srid=>4326, :type=>"geometry"}
    t.integer  "person_id"
  end

  add_index "products", ["address_id"], :name => "index_products_on_address_id"
  add_index "products", ["category_id"], :name => "index_products_on_category_id"
  add_index "products", ["created_at"], :name => "index_products_on_created_at"
  add_index "products", ["creator_id"], :name => "index_products_on_creator_id"
  add_index "products", ["default_storage_id"], :name => "index_products_on_default_storage_id"
  add_index "products", ["financial_asset_id"], :name => "index_products_on_financial_asset_id"
  add_index "products", ["initial_container_id"], :name => "index_products_on_initial_container_id"
  add_index "products", ["initial_enjoyer_id"], :name => "index_products_on_initial_enjoyer_id"
  add_index "products", ["initial_father_id"], :name => "index_products_on_initial_father_id"
  add_index "products", ["initial_mother_id"], :name => "index_products_on_initial_mother_id"
  add_index "products", ["initial_owner_id"], :name => "index_products_on_initial_owner_id"
  add_index "products", ["name"], :name => "index_products_on_name"
  add_index "products", ["nature_id"], :name => "index_products_on_nature_id"
  add_index "products", ["number"], :name => "index_products_on_number", :unique => true
  add_index "products", ["parent_id"], :name => "index_products_on_parent_id"
  add_index "products", ["tracking_id"], :name => "index_products_on_tracking_id"
  add_index "products", ["type"], :name => "index_products_on_type"
  add_index "products", ["updated_at"], :name => "index_products_on_updated_at"
  add_index "products", ["updater_id"], :name => "index_products_on_updater_id"
  add_index "products", ["variant_id"], :name => "index_products_on_variant_id"
  add_index "products", ["variety"], :name => "index_products_on_variety"

  create_table "purchase_items", force: true do |t|
    t.integer  "purchase_id",                                                           null: false
    t.integer  "variant_id",                                                            null: false
    t.decimal  "quantity",                     precision: 19, scale: 4, default: 1.0,   null: false
    t.decimal  "pretax_amount",                precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "amount",                       precision: 19, scale: 4, default: 0.0,   null: false
    t.integer  "tax_id",                                                                null: false
    t.string   "currency",           limit: 3,                                          null: false
    t.text     "label"
    t.text     "annotation"
    t.integer  "position"
    t.integer  "account_id",                                                            null: false
    t.decimal  "unit_pretax_amount",           precision: 19, scale: 4,                 null: false
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                          default: 0,     null: false
    t.decimal  "unit_amount",                  precision: 19, scale: 4, default: 0.0,   null: false
    t.boolean  "all_taxes_included",                                    default: false, null: false
  end

  add_index "purchase_items", ["account_id"], :name => "index_purchase_items_on_account_id"
  add_index "purchase_items", ["created_at"], :name => "index_purchase_items_on_created_at"
  add_index "purchase_items", ["creator_id"], :name => "index_purchase_items_on_creator_id"
  add_index "purchase_items", ["purchase_id"], :name => "index_purchase_items_on_purchase_id"
  add_index "purchase_items", ["tax_id"], :name => "index_purchase_items_on_tax_id"
  add_index "purchase_items", ["updated_at"], :name => "index_purchase_items_on_updated_at"
  add_index "purchase_items", ["updater_id"], :name => "index_purchase_items_on_updater_id"
  add_index "purchase_items", ["variant_id"], :name => "index_purchase_items_on_variant_id"

  create_table "purchase_natures", force: true do |t|
    t.boolean  "active",                    default: true,  null: false
    t.string   "name"
    t.text     "description"
    t.string   "currency",        limit: 3,                 null: false
    t.boolean  "with_accounting",           default: false, null: false
    t.integer  "journal_id"
    t.boolean  "by_default",                default: false, null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",              default: 0,     null: false
  end

  add_index "purchase_natures", ["created_at"], :name => "index_purchase_natures_on_created_at"
  add_index "purchase_natures", ["creator_id"], :name => "index_purchase_natures_on_creator_id"
  add_index "purchase_natures", ["currency"], :name => "index_purchase_natures_on_currency"
  add_index "purchase_natures", ["journal_id"], :name => "index_purchase_natures_on_journal_id"
  add_index "purchase_natures", ["updated_at"], :name => "index_purchase_natures_on_updated_at"
  add_index "purchase_natures", ["updater_id"], :name => "index_purchase_natures_on_updater_id"

  create_table "purchases", force: true do |t|
    t.integer  "supplier_id",                                                           null: false
    t.string   "number",              limit: 60,                                        null: false
    t.decimal  "pretax_amount",                  precision: 19, scale: 4, default: 0.0, null: false
    t.decimal  "amount",                         precision: 19, scale: 4, default: 0.0, null: false
    t.integer  "delivery_address_id"
    t.text     "description"
    t.datetime "planned_at"
    t.datetime "confirmed_at"
    t.datetime "invoiced_at"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.string   "reference_number"
    t.string   "state",               limit: 60
    t.integer  "responsible_id"
    t.string   "currency",            limit: 3,                                         null: false
    t.integer  "nature_id"
    t.integer  "affair_id"
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                            default: 0,   null: false
  end

  add_index "purchases", ["accounted_at"], :name => "index_purchases_on_accounted_at"
  add_index "purchases", ["affair_id"], :name => "index_purchases_on_affair_id"
  add_index "purchases", ["created_at"], :name => "index_purchases_on_created_at"
  add_index "purchases", ["creator_id"], :name => "index_purchases_on_creator_id"
  add_index "purchases", ["currency"], :name => "index_purchases_on_currency"
  add_index "purchases", ["delivery_address_id"], :name => "index_purchases_on_delivery_address_id"
  add_index "purchases", ["journal_entry_id"], :name => "index_purchases_on_journal_entry_id"
  add_index "purchases", ["nature_id"], :name => "index_purchases_on_nature_id"
  add_index "purchases", ["responsible_id"], :name => "index_purchases_on_responsible_id"
  add_index "purchases", ["supplier_id"], :name => "index_purchases_on_supplier_id"
  add_index "purchases", ["updated_at"], :name => "index_purchases_on_updated_at"
  add_index "purchases", ["updater_id"], :name => "index_purchases_on_updater_id"

  create_table "roles", force: true do |t|
    t.string   "name",                       null: false
    t.text     "rights"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",   default: 0, null: false
    t.string   "reference_name"
  end

  add_index "roles", ["created_at"], :name => "index_roles_on_created_at"
  add_index "roles", ["creator_id"], :name => "index_roles_on_creator_id"
  add_index "roles", ["updated_at"], :name => "index_roles_on_updated_at"
  add_index "roles", ["updater_id"], :name => "index_roles_on_updater_id"

  create_table "sale_items", force: true do |t|
    t.integer  "sale_id",                                                                       null: false
    t.integer  "variant_id",                                                                    null: false
    t.decimal  "quantity",                             precision: 19, scale: 4, default: 1.0,   null: false
    t.decimal  "pretax_amount",                        precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "amount",                               precision: 19, scale: 4, default: 0.0,   null: false
    t.integer  "tax_id"
    t.string   "currency",                   limit: 3,                                          null: false
    t.text     "label"
    t.text     "annotation"
    t.integer  "position"
    t.integer  "account_id"
    t.decimal  "unit_pretax_amount",                   precision: 19, scale: 4
    t.decimal  "reduction_percentage",                 precision: 19, scale: 4, default: 0.0,   null: false
    t.integer  "credited_item_id"
    t.datetime "created_at",                                                                    null: false
    t.datetime "updated_at",                                                                    null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                  default: 0,     null: false
    t.decimal  "unit_amount",                          precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "reduced_unit_pretax_amount",           precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "reduced_unit_amount",                  precision: 19, scale: 4, default: 0.0,   null: false
    t.boolean  "all_taxes_included",                                            default: false, null: false
  end

  add_index "sale_items", ["account_id"], :name => "index_sale_items_on_account_id"
  add_index "sale_items", ["created_at"], :name => "index_sale_items_on_created_at"
  add_index "sale_items", ["creator_id"], :name => "index_sale_items_on_creator_id"
  add_index "sale_items", ["credited_item_id"], :name => "index_sale_items_on_credited_item_id"
  add_index "sale_items", ["sale_id"], :name => "index_sale_items_on_sale_id"
  add_index "sale_items", ["tax_id"], :name => "index_sale_items_on_tax_id"
  add_index "sale_items", ["updated_at"], :name => "index_sale_items_on_updated_at"
  add_index "sale_items", ["updater_id"], :name => "index_sale_items_on_updater_id"
  add_index "sale_items", ["variant_id"], :name => "index_sale_items_on_variant_id"

  create_table "sale_natures", force: true do |t|
    t.string   "name",                                                                       null: false
    t.boolean  "active",                                                     default: true,  null: false
    t.boolean  "by_default",                                                 default: false, null: false
    t.boolean  "downpayment",                                                default: false, null: false
    t.decimal  "downpayment_minimum",               precision: 19, scale: 4, default: 0.0
    t.decimal  "downpayment_percentage",            precision: 19, scale: 4, default: 0.0
    t.integer  "payment_mode_id"
    t.integer  "catalog_id",                                                                 null: false
    t.text     "payment_mode_complement"
    t.string   "currency",                limit: 3,                                          null: false
    t.text     "sales_conditions"
    t.string   "expiration_delay",                                                           null: false
    t.string   "payment_delay",                                                              null: false
    t.boolean  "with_accounting",                                            default: false, null: false
    t.integer  "journal_id"
    t.text     "description"
    t.datetime "created_at",                                                                 null: false
    t.datetime "updated_at",                                                                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                               default: 0,     null: false
  end

  add_index "sale_natures", ["catalog_id"], :name => "index_sale_natures_on_catalog_id"
  add_index "sale_natures", ["created_at"], :name => "index_sale_natures_on_created_at"
  add_index "sale_natures", ["creator_id"], :name => "index_sale_natures_on_creator_id"
  add_index "sale_natures", ["journal_id"], :name => "index_sale_natures_on_journal_id"
  add_index "sale_natures", ["payment_mode_id"], :name => "index_sale_natures_on_payment_mode_id"
  add_index "sale_natures", ["updated_at"], :name => "index_sale_natures_on_updated_at"
  add_index "sale_natures", ["updater_id"], :name => "index_sale_natures_on_updater_id"

  create_table "sales", force: true do |t|
    t.integer  "client_id",                                                                      null: false
    t.integer  "nature_id"
    t.string   "number",                     limit: 60,                                          null: false
    t.decimal  "pretax_amount",                         precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "amount",                                precision: 19, scale: 4, default: 0.0,   null: false
    t.string   "state",                      limit: 60,                                          null: false
    t.datetime "expired_at"
    t.boolean  "has_downpayment",                                                default: false, null: false
    t.decimal  "downpayment_amount",                    precision: 19, scale: 4, default: 0.0,   null: false
    t.integer  "address_id"
    t.integer  "invoice_address_id"
    t.integer  "delivery_address_id"
    t.string   "subject"
    t.string   "function_title"
    t.text     "introduction"
    t.text     "conclusion"
    t.text     "description"
    t.datetime "confirmed_at"
    t.integer  "responsible_id"
    t.boolean  "letter_format",                                                  default: true,  null: false
    t.text     "annotation"
    t.integer  "transporter_id"
    t.datetime "accounted_at"
    t.integer  "journal_entry_id"
    t.string   "reference_number"
    t.datetime "invoiced_at"
    t.boolean  "credit",                                                         default: false, null: false
    t.datetime "payment_at"
    t.integer  "credited_sale_id"
    t.string   "initial_number",             limit: 60
    t.string   "currency",                   limit: 3,                                           null: false
    t.integer  "affair_id"
    t.string   "expiration_delay"
    t.string   "payment_delay",                                                                  null: false
    t.datetime "created_at",                                                                     null: false
    t.datetime "updated_at",                                                                     null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                   default: 0,     null: false
    t.decimal  "reduction_percentage",                  precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "prereduction_amount",                   precision: 19, scale: 4, default: 0.0,   null: false
    t.decimal  "prereduction_pretax_amount",            precision: 19, scale: 4, default: 0.0,   null: false
  end

  add_index "sales", ["accounted_at"], :name => "index_sales_on_accounted_at"
  add_index "sales", ["address_id"], :name => "index_sales_on_address_id"
  add_index "sales", ["affair_id"], :name => "index_sales_on_affair_id"
  add_index "sales", ["client_id"], :name => "index_sales_on_client_id"
  add_index "sales", ["created_at"], :name => "index_sales_on_created_at"
  add_index "sales", ["creator_id"], :name => "index_sales_on_creator_id"
  add_index "sales", ["credited_sale_id"], :name => "index_sales_on_credited_sale_id"
  add_index "sales", ["currency"], :name => "index_sales_on_currency"
  add_index "sales", ["delivery_address_id"], :name => "index_sales_on_delivery_address_id"
  add_index "sales", ["invoice_address_id"], :name => "index_sales_on_invoice_address_id"
  add_index "sales", ["journal_entry_id"], :name => "index_sales_on_journal_entry_id"
  add_index "sales", ["nature_id"], :name => "index_sales_on_nature_id"
  add_index "sales", ["responsible_id"], :name => "index_sales_on_responsible_id"
  add_index "sales", ["transporter_id"], :name => "index_sales_on_transporter_id"
  add_index "sales", ["updated_at"], :name => "index_sales_on_updated_at"
  add_index "sales", ["updater_id"], :name => "index_sales_on_updater_id"

  create_table "sequences", force: true do |t|
    t.string   "name",                                null: false
    t.string   "number_format",                       null: false
    t.string   "period",           default: "number", null: false
    t.integer  "last_year"
    t.integer  "last_month"
    t.integer  "last_cweek"
    t.integer  "last_number"
    t.integer  "number_increment", default: 1,        null: false
    t.integer  "number_start",     default: 1,        null: false
    t.string   "usage"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     default: 0,        null: false
  end

  add_index "sequences", ["created_at"], :name => "index_sequences_on_created_at"
  add_index "sequences", ["creator_id"], :name => "index_sequences_on_creator_id"
  add_index "sequences", ["updated_at"], :name => "index_sequences_on_updated_at"
  add_index "sequences", ["updater_id"], :name => "index_sequences_on_updater_id"

  create_table "subscription_natures", force: true do |t|
    t.string   "name",                                                                   null: false
    t.integer  "actual_number"
    t.string   "nature",                                                                 null: false
    t.text     "description"
    t.decimal  "reduction_percentage",              precision: 19, scale: 4
    t.string   "entity_link_nature",    limit: 120
    t.string   "entity_link_direction", limit: 30
    t.datetime "created_at",                                                             null: false
    t.datetime "updated_at",                                                             null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                               default: 0, null: false
  end

  add_index "subscription_natures", ["created_at"], :name => "index_subscription_natures_on_created_at"
  add_index "subscription_natures", ["creator_id"], :name => "index_subscription_natures_on_creator_id"
  add_index "subscription_natures", ["updated_at"], :name => "index_subscription_natures_on_updated_at"
  add_index "subscription_natures", ["updater_id"], :name => "index_subscription_natures_on_updater_id"

  create_table "subscriptions", force: true do |t|
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.integer  "first_number"
    t.integer  "last_number"
    t.integer  "sale_id"
    t.integer  "product_nature_id"
    t.integer  "address_id"
    t.decimal  "quantity",          precision: 19, scale: 4
    t.boolean  "suspended",                                  default: false, null: false
    t.integer  "nature_id"
    t.integer  "subscriber_id"
    t.text     "description"
    t.string   "number"
    t.integer  "sale_item_id"
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                               default: 0,     null: false
  end

  add_index "subscriptions", ["address_id"], :name => "index_subscriptions_on_address_id"
  add_index "subscriptions", ["created_at"], :name => "index_subscriptions_on_created_at"
  add_index "subscriptions", ["creator_id"], :name => "index_subscriptions_on_creator_id"
  add_index "subscriptions", ["nature_id"], :name => "index_subscriptions_on_nature_id"
  add_index "subscriptions", ["product_nature_id"], :name => "index_subscriptions_on_product_nature_id"
  add_index "subscriptions", ["sale_id"], :name => "index_subscriptions_on_sale_id"
  add_index "subscriptions", ["sale_item_id"], :name => "index_subscriptions_on_sale_item_id"
  add_index "subscriptions", ["subscriber_id"], :name => "index_subscriptions_on_subscriber_id"
  add_index "subscriptions", ["updated_at"], :name => "index_subscriptions_on_updated_at"
  add_index "subscriptions", ["updater_id"], :name => "index_subscriptions_on_updater_id"

  create_table "taxes", force: true do |t|
    t.string   "name",                                                                      null: false
    t.boolean  "included",                                                  default: false, null: false
    t.boolean  "reductible",                                                default: true,  null: false
    t.string   "computation_method",   limit: 20,                                           null: false
    t.decimal  "amount",                           precision: 19, scale: 4, default: 0.0,   null: false
    t.text     "description"
    t.integer  "collect_account_id"
    t.integer  "deduction_account_id"
    t.string   "reference_name",       limit: 120
    t.datetime "created_at",                                                                null: false
    t.datetime "updated_at",                                                                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                              default: 0,     null: false
  end

  add_index "taxes", ["collect_account_id"], :name => "index_taxes_on_collect_account_id"
  add_index "taxes", ["created_at"], :name => "index_taxes_on_created_at"
  add_index "taxes", ["creator_id"], :name => "index_taxes_on_creator_id"
  add_index "taxes", ["deduction_account_id"], :name => "index_taxes_on_deduction_account_id"
  add_index "taxes", ["updated_at"], :name => "index_taxes_on_updated_at"
  add_index "taxes", ["updater_id"], :name => "index_taxes_on_updater_id"

  create_table "teams", force: true do |t|
    t.string   "name",                         null: false
    t.text     "description"
    t.integer  "parent_id"
    t.text     "sales_conditions"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth",            default: 0, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",     default: 0, null: false
  end

  add_index "teams", ["created_at"], :name => "index_teams_on_created_at"
  add_index "teams", ["creator_id"], :name => "index_teams_on_creator_id"
  add_index "teams", ["parent_id"], :name => "index_teams_on_parent_id"
  add_index "teams", ["updated_at"], :name => "index_teams_on_updated_at"
  add_index "teams", ["updater_id"], :name => "index_teams_on_updater_id"

  create_table "trackings", force: true do |t|
    t.string   "name",                        null: false
    t.string   "serial"
    t.boolean  "active",       default: true, null: false
    t.text     "description"
    t.integer  "product_id"
    t.integer  "producer_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version", default: 0,    null: false
  end

  add_index "trackings", ["created_at"], :name => "index_trackings_on_created_at"
  add_index "trackings", ["creator_id"], :name => "index_trackings_on_creator_id"
  add_index "trackings", ["producer_id"], :name => "index_trackings_on_producer_id"
  add_index "trackings", ["product_id"], :name => "index_trackings_on_product_id"
  add_index "trackings", ["updated_at"], :name => "index_trackings_on_updated_at"
  add_index "trackings", ["updater_id"], :name => "index_trackings_on_updater_id"

  create_table "transports", force: true do |t|
    t.integer  "transporter_id",                                               null: false
    t.integer  "responsible_id"
    t.decimal  "net_mass",                precision: 19, scale: 4
    t.datetime "departed_at"
    t.text     "annotation"
    t.string   "number"
    t.string   "reference_number"
    t.integer  "transporter_purchase_id"
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                     default: 0, null: false
  end

  add_index "transports", ["created_at"], :name => "index_transports_on_created_at"
  add_index "transports", ["creator_id"], :name => "index_transports_on_creator_id"
  add_index "transports", ["responsible_id"], :name => "index_transports_on_responsible_id"
  add_index "transports", ["transporter_id"], :name => "index_transports_on_transporter_id"
  add_index "transports", ["transporter_purchase_id"], :name => "index_transports_on_transporter_purchase_id"
  add_index "transports", ["updated_at"], :name => "index_transports_on_updated_at"
  add_index "transports", ["updater_id"], :name => "index_transports_on_updater_id"

  create_table "users", force: true do |t|
    t.string   "first_name",                                                                                null: false
    t.string   "last_name",                                                                                 null: false
    t.boolean  "locked",                                                                    default: false, null: false
    t.string   "email",                                                                                     null: false
    t.integer  "person_id"
    t.integer  "role_id",                                                                                   null: false
    t.decimal  "maximal_grantable_reduction_percentage",           precision: 19, scale: 4, default: 5.0,   null: false
    t.boolean  "administrator",                                                             default: true,  null: false
    t.text     "rights"
    t.text     "description"
    t.boolean  "commercial",                                                                default: false, null: false
    t.integer  "team_id"
    t.integer  "establishment_id"
    t.boolean  "employed",                                                                  default: false, null: false
    t.string   "employment"
    t.string   "language",                               limit: 3,                                          null: false
    t.datetime "last_sign_in_at"
    t.string   "encrypted_password",                                                        default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                                             default: 0
    t.datetime "current_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",                                                           default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at",                                                                                null: false
    t.datetime "updated_at",                                                                                null: false
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.integer  "lock_version",                                                              default: 0,     null: false
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["created_at"], :name => "index_users_on_created_at"
  add_index "users", ["creator_id"], :name => "index_users_on_creator_id"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["establishment_id"], :name => "index_users_on_establishment_id"
  add_index "users", ["person_id"], :name => "index_users_on_person_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["role_id"], :name => "index_users_on_role_id"
  add_index "users", ["team_id"], :name => "index_users_on_team_id"
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true
  add_index "users", ["updated_at"], :name => "index_users_on_updated_at"
  add_index "users", ["updater_id"], :name => "index_users_on_updater_id"

end
