class AddMissingForeignKeys < ActiveRecord::Migration
  def change
    reversible do |d|
      d.up do
        # Adds missing SaleNature catalog
        execute "INSERT INTO catalogs (code, currency, name, usage, created_at, updated_at) SELECT 'SAXX' || currency, currency, 'missing_sale_catalog:' || currency, 'sale', min(created_at), min(updated_at) FROM sales WHERE nature_id IS NOT NULL AND nature_id NOT IN (SELECT id FROM sale_natures) GROUP BY 1, 2, 3, 4"

        # Adds missing Sale natures
        execute "INSERT INTO sale_natures (id, active, name, catalog_id, currency, expiration_delay, created_at, updated_at) SELECT DISTINCT ON (nature_id) nature_id, FALSE, 'missing_sale_nature:' || nature_id::VARCHAR, c.id, s.currency, '', min(created_at), min(updated_at) FROM sales AS s JOIN (SELECT id, currency FROM catalogs WHERE usage = 'sale' ORDER BY by_default DESC) AS c ON (c.currency = s.currency) WHERE nature_id IS NOT NULL AND nature_id NOT IN (SELECT id FROM sale_natures) GROUP BY 1, 2, 3, 4, 5"

        # Adds missing Purchase natures
        execute "INSERT INTO purchase_natures (id, active, name, currency, created_at, updated_at) SELECT nature_id, FALSE, 'missing_purchase_nature:' || nature_id::VARCHAR, currency, min(created_at), min(updated_at) FROM purchases WHERE nature_id IS NOT NULL AND nature_id NOT IN (SELECT id FROM purchase_natures) GROUP BY 1, 2, 3, 4"

        # Adds missing Cash journal
        execute "INSERT INTO journals (code, name, nature, currency, closed_on, created_at, updated_at) SELECT DISTINCT 'C' || currency, 'missing_journal:' || currency, 'bank', currency, COALESCE(x.closed_on, '1899-12-31'), min(opm.created_at), min(opm.updated_at) FROM outgoing_payments AS op JOIN outgoing_payment_modes AS opm ON (op.mode_id = opm.id), (SELECT min(closed_on) AS closed_on FROM journals) AS x WHERE opm.cash_id IS NOT NULL AND opm.cash_id NOT IN (SELECT id FROM cashes) GROUP BY 1, 2, 3, 4, 5"

        # Adds missing Cash main_account
        execute "INSERT INTO accounts (number, name, label, created_at, updated_at) SELECT DISTINCT '512XXX' || currency, 'missing_account:' || currency, '512XXX' || currency || ' - missing_account:' || currency, min(opm.created_at), min(opm.updated_at) FROM outgoing_payments AS op JOIN outgoing_payment_modes AS opm ON (op.mode_id = opm.id) WHERE opm.cash_id IS NOT NULL AND opm.cash_id NOT IN (SELECT id FROM cashes) GROUP BY 1, 2, 3"

        # Adds missing OutgoingPaymentMode cashes
        execute "INSERT INTO cashes (id, currency, journal_id, main_account_id, name, nature, created_at, updated_at) SELECT DISTINCT ON (opm.cash_id) opm.cash_id, op.currency, j.id, a.id, 'missing_cash:' || op.currency, 'bank_account', min(opm.created_at), min(opm.updated_at) FROM outgoing_payments AS op JOIN outgoing_payment_modes AS opm ON (op.mode_id = opm.id) JOIN journals AS j ON (op.currency = j.currency), accounts AS a WHERE opm.cash_id IS NOT NULL AND opm.cash_id NOT IN (SELECT id FROM cashes) AND j.nature = 'bank' AND a.number = '512XXX' || op.currency GROUP BY 1, 2, 3, 4, 5, 6"

        # Adds missing Cash journal
        execute "INSERT INTO journals (code, name, nature, currency, closed_on, created_at, updated_at) SELECT DISTINCT 'C' || currency, 'missing_journal:' || currency, 'bank', currency, COALESCE(x.closed_on, '1899-12-31'), min(opm.created_at), min(opm.updated_at) FROM incoming_payments AS op JOIN incoming_payment_modes AS opm ON (op.mode_id = opm.id), (SELECT min(closed_on) AS closed_on FROM journals) AS x WHERE opm.cash_id IS NOT NULL AND opm.cash_id NOT IN (SELECT id FROM cashes) GROUP BY 1, 2, 3, 4, 5"

        # Adds missing Cash main_account
        execute "INSERT INTO accounts (number, name, label, created_at, updated_at) SELECT DISTINCT '512XXX' || currency, 'missing_account:' || currency, '512XXX' || currency || ' - missing_account:' || currency, min(opm.created_at), min(opm.updated_at) FROM incoming_payments AS op JOIN incoming_payment_modes AS opm ON (op.mode_id = opm.id) WHERE opm.cash_id IS NOT NULL AND opm.cash_id NOT IN (SELECT id FROM cashes) GROUP BY 1, 2, 3"

        # Adds missing IncomingPaymentMode cashes
        execute "INSERT INTO cashes (id, currency, journal_id, main_account_id, name, nature, created_at, updated_at) SELECT DISTINCT ON (opm.cash_id) opm.cash_id, op.currency, j.id, a.id, 'missing_cash:' || op.currency, 'bank_account', min(opm.created_at), min(opm.updated_at) FROM incoming_payments AS op JOIN incoming_payment_modes AS opm ON (op.mode_id = opm.id) JOIN journals AS j ON (op.currency = j.currency), accounts AS a WHERE opm.cash_id IS NOT NULL AND opm.cash_id NOT IN (SELECT id FROM cashes) AND j.nature = 'bank' AND a.number = '512XXX' || op.currency GROUP BY 1, 2, 3, 4, 5, 6"
      end
    end

    # Account
    add_properly_foreign_key :accounts, :creator_id, :users, :nullify
    add_properly_foreign_key :accounts, :updater_id, :users, :nullify
    # AccountBalance
    add_properly_foreign_key :account_balances, :creator_id, :users, :nullify
    add_properly_foreign_key :account_balances, :updater_id, :users, :nullify
    add_properly_foreign_key :account_balances, :account_id, :accounts, :cascade
    add_properly_foreign_key :account_balances, :financial_year_id, :financial_years, :cascade
    # Activity
    add_properly_foreign_key :activities, :creator_id, :users, :nullify
    add_properly_foreign_key :activities, :updater_id, :users, :nullify
    # ActivityBudget
    add_properly_foreign_key :activity_budgets, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_budgets, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_budgets, :activity_id, :activities, :cascade
    add_properly_foreign_key :activity_budgets, :campaign_id, :campaigns, :cascade
    # ActivityBudgetItem
    add_properly_foreign_key :activity_budget_items, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_budget_items, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_budget_items, :activity_budget_id, :activity_budgets, :cascade
    add_properly_foreign_key :activity_budget_items, :variant_id, :product_nature_variants, :notnull_restrict
    change_column_null :activity_budget_items, :variant_id, false
    # ActivityDistribution
    add_properly_foreign_key :activity_distributions, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_distributions, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_distributions, :activity_id, :activities, :cascade
    add_properly_foreign_key :activity_distributions, :main_activity_id, :activities, :cascade
    # ActivityInspectionCalibrationNature
    add_properly_foreign_key :activity_inspection_calibration_natures, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_inspection_calibration_natures, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_inspection_calibration_natures, :scale_id, :activity_inspection_calibration_scales, :cascade
    # ActivityInspectionCalibrationScale
    add_properly_foreign_key :activity_inspection_calibration_scales, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_inspection_calibration_scales, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_inspection_calibration_scales, :activity_id, :activities, :cascade
    # ActivityInspectionPointNature
    add_properly_foreign_key :activity_inspection_point_natures, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_inspection_point_natures, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_inspection_point_natures, :activity_id, :activities, :cascade
    # ActivityProduction
    add_properly_foreign_key :activity_productions, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_productions, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_productions, :activity_id, :activities, :cascade
    add_properly_foreign_key :activity_productions, :campaign_id, :campaigns, :nullify
    add_properly_foreign_key :activity_productions, :cultivable_zone_id, :cultivable_zones, :nullify
    add_properly_foreign_key :activity_productions, :support_id, :products, :cascade
    add_properly_foreign_key :activity_productions, :tactic_id, :activity_tactics, :nullify
    add_properly_foreign_key :activity_productions, :season_id, :activity_seasons, :nullify
    # ActivitySeason
    add_properly_foreign_key :activity_seasons, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_seasons, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_seasons, :activity_id, :activities, :cascade
    # ActivityTactic
    add_properly_foreign_key :activity_tactics, :creator_id, :users, :nullify
    add_properly_foreign_key :activity_tactics, :updater_id, :users, :nullify
    add_properly_foreign_key :activity_tactics, :activity_id, :activities, :cascade
    # Affair
    add_properly_foreign_key :affairs, :creator_id, :users, :nullify
    add_properly_foreign_key :affairs, :updater_id, :users, :nullify
    add_properly_foreign_key :affairs, :cash_session_id, :cash_sessions, :nullify
    add_properly_foreign_key :affairs, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :affairs, :responsible_id, :entities, :nullify
    add_properly_foreign_key :affairs, :third_id, :entities, :cascade
    # Alert
    add_properly_foreign_key :alerts, :creator_id, :users, :nullify
    add_properly_foreign_key :alerts, :updater_id, :users, :nullify
    # AlertPhase
    add_properly_foreign_key :alert_phases, :creator_id, :users, :nullify
    add_properly_foreign_key :alert_phases, :updater_id, :users, :nullify
    # Analysis
    add_properly_foreign_key :analyses, :creator_id, :users, :nullify
    add_properly_foreign_key :analyses, :updater_id, :users, :nullify
    add_properly_foreign_key :analyses, :analyser_id, :entities, :nullify
    add_properly_foreign_key :analyses, :sampler_id, :entities, :nullify
    add_properly_foreign_key :analyses, :product_id, :products, :nullify
    add_properly_foreign_key :analyses, :sensor_id, :sensors, :nullify
    add_properly_foreign_key :analyses, :host_id, :products, :nullify
    # AnalysisItem
    add_properly_foreign_key :analysis_items, :creator_id, :users, :nullify
    add_properly_foreign_key :analysis_items, :updater_id, :users, :nullify
    add_properly_foreign_key :analysis_items, :analysis_id, :analyses, :cascade
    add_properly_foreign_key :analysis_items, :product_reading_id, :product_readings, :nullify
    # Animal
    # AnimalGroup
    # Attachment
    add_properly_foreign_key :attachments, :creator_id, :users, :nullify
    add_properly_foreign_key :attachments, :updater_id, :users, :nullify
    add_properly_foreign_key :attachments, :document_id, :documents, :cascade
    # BankStatement
    add_properly_foreign_key :bank_statements, :creator_id, :users, :nullify
    add_properly_foreign_key :bank_statements, :updater_id, :users, :nullify
    add_properly_foreign_key :bank_statements, :cash_id, :cashes, :cascade
    add_properly_foreign_key :bank_statements, :journal_entry_id, :journal_entries, :restrict
    # BankStatementItem
    add_properly_foreign_key :bank_statement_items, :creator_id, :users, :nullify
    add_properly_foreign_key :bank_statement_items, :updater_id, :users, :nullify
    add_properly_foreign_key :bank_statement_items, :bank_statement_id, :bank_statements, :cascade
    # Bioproduct
    # Building
    # BuildingDivision
    # Call
    add_properly_foreign_key :calls, :creator_id, :users, :nullify
    add_properly_foreign_key :calls, :updater_id, :users, :nullify
    # CallMessage
    add_properly_foreign_key :call_messages, :creator_id, :users, :nullify
    add_properly_foreign_key :call_messages, :updater_id, :users, :nullify
    add_properly_foreign_key :call_messages, :call_id, :calls, :nullify
    # CallRequest
    # CallResponse
    # Campaign
    add_properly_foreign_key :campaigns, :creator_id, :users, :nullify
    add_properly_foreign_key :campaigns, :updater_id, :users, :nullify
    # CapIslet
    add_properly_foreign_key :cap_islets, :creator_id, :users, :nullify
    add_properly_foreign_key :cap_islets, :updater_id, :users, :nullify
    add_properly_foreign_key :cap_islets, :cap_statement_id, :cap_statements, :cascade
    # CapLandParcel
    add_properly_foreign_key :cap_land_parcels, :creator_id, :users, :nullify
    add_properly_foreign_key :cap_land_parcels, :updater_id, :users, :nullify
    add_properly_foreign_key :cap_land_parcels, :support_id, :activity_productions, :nullify
    add_properly_foreign_key :cap_land_parcels, :cap_islet_id, :cap_islets, :cascade
    # CapStatement
    add_properly_foreign_key :cap_statements, :creator_id, :users, :nullify
    add_properly_foreign_key :cap_statements, :updater_id, :users, :nullify
    add_properly_foreign_key :cap_statements, :campaign_id, :campaigns, :cascade
    add_properly_foreign_key :cap_statements, :declarant_id, :entities, :nullify
    # Cash
    add_properly_foreign_key :cashes, :creator_id, :users, :nullify
    add_properly_foreign_key :cashes, :updater_id, :users, :nullify
    add_properly_foreign_key :cashes, :container_id, :products, :nullify
    add_properly_foreign_key :cashes, :journal_id, :journals, :cascade
    add_properly_foreign_key :cashes, :main_account_id, :accounts, :cascade
    add_properly_foreign_key :cashes, :owner_id, :entities, :nullify
    add_properly_foreign_key :cashes, :suspense_account_id, :accounts, :nullify
    # CashSession
    add_properly_foreign_key :cash_sessions, :creator_id, :users, :nullify
    add_properly_foreign_key :cash_sessions, :updater_id, :users, :nullify
    add_properly_foreign_key :cash_sessions, :cash_id, :cashes, :cascade
    # CashTransfer
    add_properly_foreign_key :cash_transfers, :creator_id, :users, :nullify
    add_properly_foreign_key :cash_transfers, :updater_id, :users, :nullify
    add_properly_foreign_key :cash_transfers, :emission_cash_id, :cashes, :cascade
    add_properly_foreign_key :cash_transfers, :emission_journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :cash_transfers, :reception_cash_id, :cashes, :cascade
    add_properly_foreign_key :cash_transfers, :reception_journal_entry_id, :journal_entries, :restrict
    # Catalog
    add_properly_foreign_key :catalogs, :creator_id, :users, :nullify
    add_properly_foreign_key :catalogs, :updater_id, :users, :nullify
    # CatalogItem
    add_properly_foreign_key :catalog_items, :creator_id, :users, :nullify
    add_properly_foreign_key :catalog_items, :updater_id, :users, :nullify
    add_properly_foreign_key :catalog_items, :variant_id, :product_nature_variants, :cascade
    add_properly_foreign_key :catalog_items, :reference_tax_id, :taxes, :nullify
    add_properly_foreign_key :catalog_items, :catalog_id, :catalogs, :cascade
    # Contract
    add_properly_foreign_key :contracts, :creator_id, :users, :nullify
    add_properly_foreign_key :contracts, :updater_id, :users, :nullify
    add_properly_foreign_key :contracts, :supplier_id, :entities, :cascade
    add_properly_foreign_key :contracts, :responsible_id, :users, :cascade
    # ContractItem
    add_properly_foreign_key :contract_items, :creator_id, :users, :nullify
    add_properly_foreign_key :contract_items, :updater_id, :users, :nullify
    add_properly_foreign_key :contract_items, :contract_id, :contracts, :cascade
    add_properly_foreign_key :contract_items, :variant_id, :product_nature_variants, :cascade
    # Crumb
    add_properly_foreign_key :crumbs, :creator_id, :users, :nullify
    add_properly_foreign_key :crumbs, :updater_id, :users, :nullify
    add_properly_foreign_key :crumbs, :user_id, :users, :nullify
    add_properly_foreign_key :crumbs, :intervention_parameter_id, :intervention_parameters, :nullify
    # CultivableZone
    add_properly_foreign_key :cultivable_zones, :creator_id, :users, :nullify
    add_properly_foreign_key :cultivable_zones, :updater_id, :users, :nullify
    add_properly_foreign_key :cultivable_zones, :farmer_id, :entities, :nullify
    add_properly_foreign_key :cultivable_zones, :owner_id, :entities, :nullify
    # CustomField
    add_properly_foreign_key :custom_fields, :creator_id, :users, :nullify
    add_properly_foreign_key :custom_fields, :updater_id, :users, :nullify
    # CustomFieldChoice
    add_properly_foreign_key :custom_field_choices, :creator_id, :users, :nullify
    add_properly_foreign_key :custom_field_choices, :updater_id, :users, :nullify
    add_properly_foreign_key :custom_field_choices, :custom_field_id, :custom_fields, :cascade
    # Dashboard
    add_properly_foreign_key :dashboards, :creator_id, :users, :nullify
    add_properly_foreign_key :dashboards, :updater_id, :users, :nullify
    add_properly_foreign_key :dashboards, :owner_id, :users, :cascade
    # DebtTransfer
    add_properly_foreign_key :debt_transfers, :creator_id, :users, :nullify
    add_properly_foreign_key :debt_transfers, :updater_id, :users, :nullify
    add_properly_foreign_key :debt_transfers, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :debt_transfers, :affair_id, :affairs, :cascade
    add_properly_foreign_key :debt_transfers, :debt_transfer_affair_id, :affairs, :cascade
    # Delivery
    add_properly_foreign_key :deliveries, :creator_id, :users, :nullify
    add_properly_foreign_key :deliveries, :updater_id, :users, :nullify
    add_properly_foreign_key :deliveries, :driver_id, :entities, :nullify
    add_properly_foreign_key :deliveries, :responsible_id, :entities, :nullify
    add_properly_foreign_key :deliveries, :transporter_id, :entities, :nullify
    add_properly_foreign_key :deliveries, :transporter_purchase_id, :purchases, :nullify
    # DeliveryTool
    add_properly_foreign_key :delivery_tools, :creator_id, :users, :nullify
    add_properly_foreign_key :delivery_tools, :updater_id, :users, :nullify
    add_properly_foreign_key :delivery_tools, :delivery_id, :deliveries, :nullify
    add_properly_foreign_key :delivery_tools, :tool_id, :products, :nullify
    # Deposit
    add_properly_foreign_key :deposits, :creator_id, :users, :nullify
    add_properly_foreign_key :deposits, :updater_id, :users, :nullify
    add_properly_foreign_key :deposits, :cash_id, :cashes, :cascade
    add_properly_foreign_key :deposits, :responsible_id, :entities, :nullify
    add_properly_foreign_key :deposits, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :deposits, :mode_id, :incoming_payment_modes, :cascade
    # District
    add_properly_foreign_key :districts, :creator_id, :users, :nullify
    add_properly_foreign_key :districts, :updater_id, :users, :nullify
    # Document
    add_properly_foreign_key :documents, :creator_id, :users, :nullify
    add_properly_foreign_key :documents, :updater_id, :users, :nullify
    add_properly_foreign_key :documents, :template_id, :document_templates, :nullify
    # DocumentTemplate
    add_properly_foreign_key :document_templates, :creator_id, :users, :nullify
    add_properly_foreign_key :document_templates, :updater_id, :users, :nullify
    # Easement
    # Entity
    add_properly_foreign_key :entities, :creator_id, :users, :nullify
    add_properly_foreign_key :entities, :updater_id, :users, :nullify
    add_properly_foreign_key :entities, :client_account_id, :accounts, :nullify
    add_properly_foreign_key :entities, :employee_account_id, :accounts, :nullify
    add_properly_foreign_key :entities, :proposer_id, :entities, :nullify
    add_properly_foreign_key :entities, :responsible_id, :users, :nullify
    add_properly_foreign_key :entities, :supplier_account_id, :accounts, :nullify
    add_properly_foreign_key :entities, :supplier_payment_mode_id, :outgoing_payment_modes, :nullify
    # EntityAddress
    add_properly_foreign_key :entity_addresses, :creator_id, :users, :nullify
    add_properly_foreign_key :entity_addresses, :updater_id, :users, :nullify
    add_properly_foreign_key :entity_addresses, :mail_postal_zone_id, :postal_zones, :nullify
    add_properly_foreign_key :entity_addresses, :entity_id, :entities, :cascade
    # EntityLink
    add_properly_foreign_key :entity_links, :creator_id, :users, :nullify
    add_properly_foreign_key :entity_links, :updater_id, :users, :nullify
    add_properly_foreign_key :entity_links, :entity_id, :entities, :cascade
    add_properly_foreign_key :entity_links, :linked_id, :entities, :cascade
    # Equipment
    # EquipmentFleet
    # Event
    add_properly_foreign_key :events, :creator_id, :users, :nullify
    add_properly_foreign_key :events, :updater_id, :users, :nullify
    add_properly_foreign_key :events, :affair_id, :affairs, :nullify
    # EventParticipation
    add_properly_foreign_key :event_participations, :creator_id, :users, :nullify
    add_properly_foreign_key :event_participations, :updater_id, :users, :nullify
    add_properly_foreign_key :event_participations, :event_id, :events, :cascade
    add_properly_foreign_key :event_participations, :participant_id, :entities, :cascade
    # FinancialYear
    add_properly_foreign_key :financial_years, :creator_id, :users, :nullify
    add_properly_foreign_key :financial_years, :updater_id, :users, :nullify
    add_properly_foreign_key :financial_years, :last_journal_entry_id, :journal_entries, :restrict
    # FinancialYearExchange
    add_properly_foreign_key :financial_year_exchanges, :creator_id, :users, :nullify
    add_properly_foreign_key :financial_year_exchanges, :updater_id, :users, :nullify
    # FixedAsset
    add_properly_foreign_key :fixed_assets, :creator_id, :users, :nullify
    add_properly_foreign_key :fixed_assets, :updater_id, :users, :nullify
    add_properly_foreign_key :fixed_assets, :asset_account_id, :accounts, :restrict
    add_properly_foreign_key :fixed_assets, :expenses_account_id, :accounts, :restrict
    add_properly_foreign_key :fixed_assets, :allocation_account_id, :accounts, :cascade
    add_properly_foreign_key :fixed_assets, :journal_id, :journals, :cascade
    add_properly_foreign_key :fixed_assets, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :fixed_assets, :sold_journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :fixed_assets, :scrapped_journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :fixed_assets, :product_id, :products, :nullify
    # FixedAssetDepreciation
    add_properly_foreign_key :fixed_asset_depreciations, :creator_id, :users, :nullify
    add_properly_foreign_key :fixed_asset_depreciations, :updater_id, :users, :nullify
    add_properly_foreign_key :fixed_asset_depreciations, :fixed_asset_id, :fixed_assets, :cascade
    add_properly_foreign_key :fixed_asset_depreciations, :financial_year_id, :financial_years, :nullify
    add_properly_foreign_key :fixed_asset_depreciations, :journal_entry_id, :journal_entries, :restrict
    # Fungus
    # Gap
    add_properly_foreign_key :gaps, :creator_id, :users, :nullify
    add_properly_foreign_key :gaps, :updater_id, :users, :nullify
    add_properly_foreign_key :gaps, :affair_id, :affairs, :nullify
    add_properly_foreign_key :gaps, :entity_id, :entities, :cascade
    add_properly_foreign_key :gaps, :journal_entry_id, :journal_entries, :restrict
    # GapItem
    add_properly_foreign_key :gap_items, :creator_id, :users, :nullify
    add_properly_foreign_key :gap_items, :updater_id, :users, :nullify
    add_properly_foreign_key :gap_items, :gap_id, :gaps, :cascade
    add_properly_foreign_key :gap_items, :tax_id, :taxes, :nullify
    # Georeading
    add_properly_foreign_key :georeadings, :creator_id, :users, :nullify
    add_properly_foreign_key :georeadings, :updater_id, :users, :nullify
    # Guide
    add_properly_foreign_key :guides, :creator_id, :users, :nullify
    add_properly_foreign_key :guides, :updater_id, :users, :nullify
    # GuideAnalysis
    add_properly_foreign_key :guide_analyses, :creator_id, :users, :nullify
    add_properly_foreign_key :guide_analyses, :updater_id, :users, :nullify
    add_properly_foreign_key :guide_analyses, :guide_id, :guides, :cascade
    # GuideAnalysisPoint
    add_properly_foreign_key :guide_analysis_points, :creator_id, :users, :nullify
    add_properly_foreign_key :guide_analysis_points, :updater_id, :users, :nullify
    add_properly_foreign_key :guide_analysis_points, :analysis_id, :guide_analyses, :cascade
    # Identifier
    add_properly_foreign_key :identifiers, :creator_id, :users, :nullify
    add_properly_foreign_key :identifiers, :updater_id, :users, :nullify
    add_properly_foreign_key :identifiers, :net_service_id, :net_services, :nullify
    # Import
    add_properly_foreign_key :imports, :creator_id, :users, :nullify
    add_properly_foreign_key :imports, :updater_id, :users, :nullify
    add_properly_foreign_key :imports, :importer_id, :users, :nullify
    # IncomingPayment
    add_properly_foreign_key :incoming_payments, :creator_id, :users, :nullify
    add_properly_foreign_key :incoming_payments, :updater_id, :users, :nullify
    add_properly_foreign_key :incoming_payments, :commission_account_id, :accounts, :nullify
    add_properly_foreign_key :incoming_payments, :responsible_id, :users, :nullify
    add_properly_foreign_key :incoming_payments, :deposit_id, :deposits, :nullify
    add_properly_foreign_key :incoming_payments, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :incoming_payments, :payer_id, :entities, :notnull_restrict
    change_column_null :incoming_payments, :payer_id, false
    add_properly_foreign_key :incoming_payments, :mode_id, :incoming_payment_modes, :cascade
    add_properly_foreign_key :incoming_payments, :affair_id, :affairs, :nullify
    # IncomingPaymentMode
    add_properly_foreign_key :incoming_payment_modes, :creator_id, :users, :nullify
    add_properly_foreign_key :incoming_payment_modes, :updater_id, :users, :nullify
    add_properly_foreign_key :incoming_payment_modes, :cash_id, :cashes, :notnull_restrict
    change_column_null :incoming_payment_modes, :cash_id, false
    add_properly_foreign_key :incoming_payment_modes, :commission_account_id, :accounts, :nullify
    add_properly_foreign_key :incoming_payment_modes, :depositables_account_id, :accounts, :nullify
    add_properly_foreign_key :incoming_payment_modes, :depositables_journal_id, :journals, :nullify
    # Inspection
    add_properly_foreign_key :inspections, :creator_id, :users, :nullify
    add_properly_foreign_key :inspections, :updater_id, :users, :nullify
    add_properly_foreign_key :inspections, :activity_id, :activities, :cascade
    add_properly_foreign_key :inspections, :product_id, :products, :cascade
    # InspectionCalibration
    add_properly_foreign_key :inspection_calibrations, :creator_id, :users, :nullify
    add_properly_foreign_key :inspection_calibrations, :updater_id, :users, :nullify
    add_properly_foreign_key :inspection_calibrations, :nature_id, :activity_inspection_calibration_natures, :cascade
    add_properly_foreign_key :inspection_calibrations, :inspection_id, :inspections, :cascade
    # InspectionPoint
    add_properly_foreign_key :inspection_points, :creator_id, :users, :nullify
    add_properly_foreign_key :inspection_points, :updater_id, :users, :nullify
    add_properly_foreign_key :inspection_points, :nature_id, :activity_inspection_point_natures, :cascade
    add_properly_foreign_key :inspection_points, :inspection_id, :inspections, :cascade
    # Integration
    add_properly_foreign_key :integrations, :creator_id, :users, :nullify
    add_properly_foreign_key :integrations, :updater_id, :users, :nullify
    # Intervention
    add_properly_foreign_key :interventions, :creator_id, :users, :nullify
    add_properly_foreign_key :interventions, :updater_id, :users, :nullify
    add_properly_foreign_key :interventions, :event_id, :events, :nullify
    add_properly_foreign_key :interventions, :request_intervention_id, :interventions, :nullify
    add_properly_foreign_key :interventions, :issue_id, :issues, :nullify
    add_properly_foreign_key :interventions, :prescription_id, :prescriptions, :nullify
    add_properly_foreign_key :interventions, :journal_entry_id, :journal_entries, :restrict
    # InterventionAgent
    # InterventionDoer
    # InterventionGroupParameter
    # InterventionInput
    # InterventionLabelling
    add_properly_foreign_key :intervention_labellings, :creator_id, :users, :nullify
    add_properly_foreign_key :intervention_labellings, :updater_id, :users, :nullify
    add_properly_foreign_key :intervention_labellings, :label_id, :labels, :cascade
    add_properly_foreign_key :intervention_labellings, :intervention_id, :interventions, :cascade
    # InterventionOutput
    # InterventionParameter
    add_properly_foreign_key :intervention_parameters, :creator_id, :users, :nullify
    add_properly_foreign_key :intervention_parameters, :updater_id, :users, :nullify
    add_properly_foreign_key :intervention_parameters, :group_id, :intervention_parameters, :nullify
    add_properly_foreign_key :intervention_parameters, :intervention_id, :interventions, :cascade
    # InterventionParameterReading
    add_properly_foreign_key :intervention_parameter_readings, :creator_id, :users, :nullify
    add_properly_foreign_key :intervention_parameter_readings, :updater_id, :users, :nullify
    add_properly_foreign_key :intervention_parameter_readings, :parameter_id, :intervention_parameters, :cascade
    # InterventionParticipation
    add_properly_foreign_key :intervention_participations, :creator_id, :users, :nullify
    add_properly_foreign_key :intervention_participations, :updater_id, :users, :nullify
    # InterventionProductParameter
    # InterventionTarget
    # InterventionTool
    # InterventionWorkingPeriod
    add_properly_foreign_key :intervention_working_periods, :creator_id, :users, :nullify
    add_properly_foreign_key :intervention_working_periods, :updater_id, :users, :nullify
    add_properly_foreign_key :intervention_working_periods, :intervention_id, :interventions, :null_cascade
    remove_foreign_key :intervention_working_periods, :intervention_participations
    add_properly_foreign_key :intervention_working_periods, :intervention_participation_id, :intervention_participations, :null_cascade
    # Inventory
    add_properly_foreign_key :inventories, :creator_id, :users, :nullify
    add_properly_foreign_key :inventories, :updater_id, :users, :nullify
    add_properly_foreign_key :inventories, :responsible_id, :entities, :nullify
    add_properly_foreign_key :inventories, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :inventories, :financial_year_id, :financial_years, :nullify
    # InventoryItem
    add_properly_foreign_key :inventory_items, :creator_id, :users, :nullify
    add_properly_foreign_key :inventory_items, :updater_id, :users, :nullify
    add_properly_foreign_key :inventory_items, :inventory_id, :inventories, :cascade
    add_properly_foreign_key :inventory_items, :product_id, :products, :cascade
    add_properly_foreign_key :inventory_items, :product_movement_id, :product_movements, :nullify
    # Issue
    add_properly_foreign_key :issues, :creator_id, :users, :nullify
    add_properly_foreign_key :issues, :updater_id, :users, :nullify
    # Journal
    add_properly_foreign_key :journals, :creator_id, :users, :nullify
    add_properly_foreign_key :journals, :updater_id, :users, :nullify
    # JournalEntry
    add_properly_foreign_key :journal_entries, :creator_id, :users, :nullify
    add_properly_foreign_key :journal_entries, :updater_id, :users, :nullify
    add_properly_foreign_key :journal_entries, :financial_year_id, :financial_years, :nullify
    add_properly_foreign_key :journal_entries, :journal_id, :journals, :cascade
    # JournalEntryItem
    add_properly_foreign_key :journal_entry_items, :creator_id, :users, :nullify
    add_properly_foreign_key :journal_entry_items, :updater_id, :users, :nullify
    add_properly_foreign_key :journal_entry_items, :account_id, :accounts, :cascade
    add_properly_foreign_key :journal_entry_items, :activity_budget_id, :activity_budgets, :nullify
    add_properly_foreign_key :journal_entry_items, :bank_statement_id, :bank_statements, :nullify
    add_properly_foreign_key :journal_entry_items, :entry_id, :journal_entries, :cascade
    add_properly_foreign_key :journal_entry_items, :financial_year_id, :financial_years, :cascade
    add_properly_foreign_key :journal_entry_items, :journal_id, :journals, :cascade
    add_properly_foreign_key :journal_entry_items, :tax_id, :taxes, :nullify
    add_properly_foreign_key :journal_entry_items, :tax_declaration_item_id, :tax_declaration_items, :nullify
    add_properly_foreign_key :journal_entry_items, :team_id, :teams, :nullify
    # Label
    add_properly_foreign_key :labels, :creator_id, :users, :nullify
    add_properly_foreign_key :labels, :updater_id, :users, :nullify
    # LandParcel
    # Listing
    add_properly_foreign_key :listings, :creator_id, :users, :nullify
    add_properly_foreign_key :listings, :updater_id, :users, :nullify
    # ListingNode
    add_properly_foreign_key :listing_nodes, :creator_id, :users, :nullify
    add_properly_foreign_key :listing_nodes, :updater_id, :users, :nullify
    add_properly_foreign_key :listing_nodes, :parent_id, :listing_nodes, :null_cascade
    add_properly_foreign_key :listing_nodes, :listing_id, :listings, :cascade
    add_properly_foreign_key :listing_nodes, :item_listing_id, :listings, :nullify
    add_properly_foreign_key :listing_nodes, :item_listing_node_id, :listing_nodes, :nullify
    # ListingNodeItem
    add_properly_foreign_key :listing_node_items, :creator_id, :users, :nullify
    add_properly_foreign_key :listing_node_items, :updater_id, :users, :nullify
    add_properly_foreign_key :listing_node_items, :node_id, :listing_nodes, :cascade
    # Loan
    add_properly_foreign_key :loans, :creator_id, :users, :nullify
    add_properly_foreign_key :loans, :updater_id, :users, :nullify
    add_properly_foreign_key :loans, :cash_id, :cashes, :cascade
    add_properly_foreign_key :loans, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :loans, :lender_id, :entities, :cascade
    add_properly_foreign_key :loans, :loan_account_id, :accounts, :restrict
    add_properly_foreign_key :loans, :interest_account_id, :accounts, :restrict
    add_properly_foreign_key :loans, :insurance_account_id, :accounts, :nullify
    add_properly_foreign_key :loans, :bank_guarantee_account_id, :accounts, :nullify
    # LoanRepayment
    add_properly_foreign_key :loan_repayments, :creator_id, :users, :nullify
    add_properly_foreign_key :loan_repayments, :updater_id, :users, :nullify
    add_properly_foreign_key :loan_repayments, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :loan_repayments, :loan_id, :loans, :cascade
    # ManureManagementPlan
    add_properly_foreign_key :manure_management_plans, :creator_id, :users, :nullify
    add_properly_foreign_key :manure_management_plans, :updater_id, :users, :nullify
    add_properly_foreign_key :manure_management_plans, :campaign_id, :campaigns, :cascade
    add_properly_foreign_key :manure_management_plans, :recommender_id, :entities, :cascade
    # ManureManagementPlanZone
    add_properly_foreign_key :manure_management_plan_zones, :creator_id, :users, :nullify
    add_properly_foreign_key :manure_management_plan_zones, :updater_id, :users, :nullify
    add_properly_foreign_key :manure_management_plan_zones, :plan_id, :manure_management_plans, :cascade
    add_properly_foreign_key :manure_management_plan_zones, :activity_production_id, :activity_productions, :cascade
    # MapLayer
    add_properly_foreign_key :map_layers, :creator_id, :users, :nullify
    add_properly_foreign_key :map_layers, :updater_id, :users, :nullify
    # Matter
    # NetService
    add_properly_foreign_key :net_services, :creator_id, :users, :nullify
    add_properly_foreign_key :net_services, :updater_id, :users, :nullify
    # Notification
    add_properly_foreign_key :notifications, :creator_id, :users, :nullify
    add_properly_foreign_key :notifications, :updater_id, :users, :nullify
    add_properly_foreign_key :notifications, :recipient_id, :users, :cascade
    # Observation
    add_properly_foreign_key :observations, :creator_id, :users, :nullify
    add_properly_foreign_key :observations, :updater_id, :users, :nullify
    add_properly_foreign_key :observations, :author_id, :users, :cascade
    # OutgoingPayment
    add_properly_foreign_key :outgoing_payments, :creator_id, :users, :nullify
    add_properly_foreign_key :outgoing_payments, :updater_id, :users, :nullify
    add_properly_foreign_key :outgoing_payments, :cash_id, :cashes, :cascade
    add_properly_foreign_key :outgoing_payments, :responsible_id, :users, :cascade
    add_properly_foreign_key :outgoing_payments, :affair_id, :affairs, :nullify
    # OutgoingPaymentList
    add_properly_foreign_key :outgoing_payment_lists, :creator_id, :users, :nullify
    add_properly_foreign_key :outgoing_payment_lists, :updater_id, :users, :nullify
    add_properly_foreign_key :outgoing_payment_lists, :mode_id, :outgoing_payment_modes, :cascade
    # OutgoingPaymentMode
    add_properly_foreign_key :outgoing_payment_modes, :creator_id, :users, :nullify
    add_properly_foreign_key :outgoing_payment_modes, :updater_id, :users, :nullify
    add_properly_foreign_key :outgoing_payment_modes, :cash_id, :cashes, :cascade
    change_column_null :outgoing_payment_modes, :cash_id, false
    # Parcel
    add_properly_foreign_key :parcels, :creator_id, :users, :nullify
    add_properly_foreign_key :parcels, :updater_id, :users, :nullify
    add_properly_foreign_key :parcels, :address_id, :entity_addresses, :restrict
    add_properly_foreign_key :parcels, :delivery_id, :deliveries, :nullify
    add_properly_foreign_key :parcels, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :parcels, :undelivered_invoice_journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :parcels, :storage_id, :products, :restrict
    add_properly_foreign_key :parcels, :sale_id, :sales, :nullify
    add_properly_foreign_key :parcels, :purchase_id, :purchases, :nullify
    add_properly_foreign_key :parcels, :recipient_id, :entities, :restrict
    add_properly_foreign_key :parcels, :responsible_id, :users, :nullify
    add_properly_foreign_key :parcels, :sender_id, :entities, :restrict
    add_properly_foreign_key :parcels, :transporter_id, :entities, :nullify
    add_properly_foreign_key :parcels, :contract_id, :contracts, :nullify
    # ParcelItem
    add_properly_foreign_key :parcel_items, :creator_id, :users, :nullify
    add_properly_foreign_key :parcel_items, :updater_id, :users, :nullify
    add_properly_foreign_key :parcel_items, :analysis_id, :analyses, :nullify
    add_properly_foreign_key :parcel_items, :parcel_id, :parcels, :cascade
    add_properly_foreign_key :parcel_items, :product_id, :products, :restrict
    add_properly_foreign_key :parcel_items, :product_enjoyment_id, :product_enjoyments, :nullify
    add_properly_foreign_key :parcel_items, :product_localization_id, :product_localizations, :nullify
    add_properly_foreign_key :parcel_items, :product_ownership_id, :product_ownerships, :nullify
    add_properly_foreign_key :parcel_items, :product_movement_id, :product_movements, :nullify
    add_properly_foreign_key :parcel_items, :purchase_item_id, :purchase_items, :nullify
    add_properly_foreign_key :parcel_items, :sale_item_id, :sale_items, :nullify
    add_properly_foreign_key :parcel_items, :source_product_id, :products, :restrict
    add_properly_foreign_key :parcel_items, :source_product_movement_id, :product_movements, :nullify
    add_properly_foreign_key :parcel_items, :variant_id, :product_nature_variants, :restrict
    # Payslip
    add_properly_foreign_key :payslips, :creator_id, :users, :nullify
    add_properly_foreign_key :payslips, :updater_id, :users, :nullify
    # PayslipNature
    add_properly_foreign_key :payslip_natures, :creator_id, :users, :nullify
    add_properly_foreign_key :payslip_natures, :updater_id, :users, :nullify
    # Plant
    # PlantCounting
    add_properly_foreign_key :plant_countings, :creator_id, :users, :nullify
    add_properly_foreign_key :plant_countings, :updater_id, :users, :nullify
    add_properly_foreign_key :plant_countings, :plant_id, :products, :cascade
    add_properly_foreign_key :plant_countings, :plant_density_abacus_id, :plant_density_abaci, :cascade
    add_properly_foreign_key :plant_countings, :plant_density_abacus_item_id, :plant_density_abacus_items, :cascade
    # PlantCountingItem
    add_properly_foreign_key :plant_counting_items, :creator_id, :users, :nullify
    add_properly_foreign_key :plant_counting_items, :updater_id, :users, :nullify
    add_properly_foreign_key :plant_counting_items, :plant_counting_id, :plant_countings, :cascade
    # PlantDensityAbacus
    add_properly_foreign_key :plant_density_abaci, :creator_id, :users, :nullify
    add_properly_foreign_key :plant_density_abaci, :updater_id, :users, :nullify
    add_properly_foreign_key :plant_density_abaci, :activity_id, :activities, :cascade
    # PlantDensityAbacusItem
    add_properly_foreign_key :plant_density_abacus_items, :creator_id, :users, :nullify
    add_properly_foreign_key :plant_density_abacus_items, :updater_id, :users, :nullify
    add_properly_foreign_key :plant_density_abacus_items, :plant_density_abacus_id, :plant_density_abaci, :cascade
    # PostalZone
    add_properly_foreign_key :postal_zones, :creator_id, :users, :nullify
    add_properly_foreign_key :postal_zones, :updater_id, :users, :nullify
    add_properly_foreign_key :postal_zones, :district_id, :districts, :nullify
    # Preference
    add_properly_foreign_key :preferences, :creator_id, :users, :nullify
    add_properly_foreign_key :preferences, :updater_id, :users, :nullify
    add_properly_foreign_key :preferences, :user_id, :users, :null_cascade
    # Prescription
    add_properly_foreign_key :prescriptions, :creator_id, :users, :nullify
    add_properly_foreign_key :prescriptions, :updater_id, :users, :nullify
    add_properly_foreign_key :prescriptions, :prescriptor_id, :entities, :cascade
    # Product
    add_properly_foreign_key :products, :creator_id, :users, :nullify
    add_properly_foreign_key :products, :updater_id, :users, :nullify
    add_properly_foreign_key :products, :address_id, :entity_addresses, :nullify
    add_properly_foreign_key :products, :category_id, :product_nature_categories, :cascade
    add_properly_foreign_key :products, :default_storage_id, :products, :nullify
    add_properly_foreign_key :products, :initial_container_id, :products, :nullify
    add_properly_foreign_key :products, :initial_enjoyer_id, :entities, :nullify
    add_properly_foreign_key :products, :initial_movement_id, :product_movements, :nullify
    add_properly_foreign_key :products, :initial_father_id, :products, :nullify
    add_properly_foreign_key :products, :initial_mother_id, :products, :nullify
    add_properly_foreign_key :products, :initial_owner_id, :entities, :nullify
    add_properly_foreign_key :products, :nature_id, :product_natures, :cascade
    add_properly_foreign_key :products, :parent_id, :products, :nullify
    add_properly_foreign_key :products, :person_id, :entities, :nullify
    add_properly_foreign_key :products, :tracking_id, :trackings, :nullify
    add_properly_foreign_key :products, :variant_id, :product_nature_variants, :cascade
    add_properly_foreign_key :products, :member_variant_id, :product_nature_variants, :nullify
    # ProductEnjoyment
    add_properly_foreign_key :product_enjoyments, :creator_id, :users, :nullify
    add_properly_foreign_key :product_enjoyments, :updater_id, :users, :nullify
    add_properly_foreign_key :product_enjoyments, :intervention_id, :interventions, :nullify
    add_properly_foreign_key :product_enjoyments, :enjoyer_id, :entities, :null_cascade
    add_properly_foreign_key :product_enjoyments, :product_id, :products, :cascade
    # ProductGroup
    # ProductLabelling
    add_properly_foreign_key :product_labellings, :creator_id, :users, :nullify
    add_properly_foreign_key :product_labellings, :updater_id, :users, :nullify
    add_properly_foreign_key :product_labellings, :label_id, :labels, :cascade
    add_properly_foreign_key :product_labellings, :product_id, :products, :cascade
    # ProductLink
    add_properly_foreign_key :product_links, :creator_id, :users, :nullify
    add_properly_foreign_key :product_links, :updater_id, :users, :nullify
    add_properly_foreign_key :product_links, :intervention_id, :interventions, :nullify
    add_properly_foreign_key :product_links, :product_id, :products, :cascade
    add_properly_foreign_key :product_links, :linked_id, :products, :cascade
    change_column_null :product_links, :linked_id, false
    # ProductLinkage
    add_properly_foreign_key :product_linkages, :creator_id, :users, :nullify
    add_properly_foreign_key :product_linkages, :updater_id, :users, :nullify
    add_properly_foreign_key :product_linkages, :intervention_id, :interventions, :nullify
    add_properly_foreign_key :product_linkages, :carrier_id, :products, :cascade
    add_properly_foreign_key :product_linkages, :carried_id, :products, :cascade
    change_column_null :product_linkages, :carried_id, false
    # ProductLocalization
    add_properly_foreign_key :product_localizations, :creator_id, :users, :nullify
    add_properly_foreign_key :product_localizations, :updater_id, :users, :nullify
    add_properly_foreign_key :product_localizations, :intervention_id, :interventions, :nullify
    add_properly_foreign_key :product_localizations, :container_id, :products, :null_cascade
    add_properly_foreign_key :product_localizations, :product_id, :products, :cascade
    # ProductMembership
    add_properly_foreign_key :product_memberships, :creator_id, :users, :nullify
    add_properly_foreign_key :product_memberships, :updater_id, :users, :nullify
    add_properly_foreign_key :product_memberships, :intervention_id, :interventions, :nullify
    add_properly_foreign_key :product_memberships, :group_id, :products, :cascade
    add_properly_foreign_key :product_memberships, :member_id, :products, :cascade
    # ProductMovement
    add_properly_foreign_key :product_movements, :creator_id, :users, :nullify
    add_properly_foreign_key :product_movements, :updater_id, :users, :nullify
    add_properly_foreign_key :product_movements, :intervention_id, :interventions, :nullify
    add_properly_foreign_key :product_movements, :product_id, :products, :cascade
    # ProductNature
    add_properly_foreign_key :product_natures, :creator_id, :users, :nullify
    add_properly_foreign_key :product_natures, :updater_id, :users, :nullify
    add_properly_foreign_key :product_natures, :category_id, :product_nature_categories, :cascade
    add_properly_foreign_key :product_natures, :subscription_nature_id, :subscription_natures, :nullify
    # ProductNatureCategory
    add_properly_foreign_key :product_nature_categories, :creator_id, :users, :nullify
    add_properly_foreign_key :product_nature_categories, :updater_id, :users, :nullify
    add_properly_foreign_key :product_nature_categories, :fixed_asset_account_id, :accounts, :restrict
    add_properly_foreign_key :product_nature_categories, :fixed_asset_allocation_account_id, :accounts, :restrict
    add_properly_foreign_key :product_nature_categories, :fixed_asset_expenses_account_id, :accounts, :restrict
    add_properly_foreign_key :product_nature_categories, :charge_account_id, :accounts, :restrict
    add_properly_foreign_key :product_nature_categories, :product_account_id, :accounts, :restrict
    add_properly_foreign_key :product_nature_categories, :stock_account_id, :accounts, :restrict
    add_properly_foreign_key :product_nature_categories, :stock_movement_account_id, :accounts, :restrict
    # ProductNatureCategoryTaxation
    add_properly_foreign_key :product_nature_category_taxations, :creator_id, :users, :nullify
    add_properly_foreign_key :product_nature_category_taxations, :updater_id, :users, :nullify
    add_properly_foreign_key :product_nature_category_taxations, :product_nature_category_id, :product_nature_categories, :cascade
    add_properly_foreign_key :product_nature_category_taxations, :tax_id, :taxes, :cascade
    # ProductNatureVariant
    add_properly_foreign_key :product_nature_variants, :creator_id, :users, :nullify
    add_properly_foreign_key :product_nature_variants, :updater_id, :users, :nullify
    add_properly_foreign_key :product_nature_variants, :nature_id, :product_natures, :cascade
    add_properly_foreign_key :product_nature_variants, :category_id, :product_nature_categories, :cascade
    add_properly_foreign_key :product_nature_variants, :stock_movement_account_id, :accounts, :nullify
    add_properly_foreign_key :product_nature_variants, :stock_account_id, :accounts, :nullify
    # ProductNatureVariantComponent
    add_properly_foreign_key :product_nature_variant_components, :creator_id, :users, :nullify
    add_properly_foreign_key :product_nature_variant_components, :updater_id, :users, :nullify
    add_properly_foreign_key :product_nature_variant_components, :product_nature_variant_id, :product_nature_variants, :cascade
    add_properly_foreign_key :product_nature_variant_components, :part_product_nature_variant_id, :product_nature_variants, :nullify
    add_properly_foreign_key :product_nature_variant_components, :parent_id, :product_nature_variant_components, :null_cascade
    # ProductNatureVariantReading
    add_properly_foreign_key :product_nature_variant_readings, :creator_id, :users, :nullify
    add_properly_foreign_key :product_nature_variant_readings, :updater_id, :users, :nullify
    add_properly_foreign_key :product_nature_variant_readings, :variant_id, :product_nature_variants, :cascade
    # ProductOwnership
    add_properly_foreign_key :product_ownerships, :creator_id, :users, :nullify
    add_properly_foreign_key :product_ownerships, :updater_id, :users, :nullify
    add_properly_foreign_key :product_ownerships, :intervention_id, :interventions, :nullify
    add_properly_foreign_key :product_ownerships, :owner_id, :entities, :null_cascade
    add_properly_foreign_key :product_ownerships, :product_id, :products, :cascade
    # ProductPhase
    add_properly_foreign_key :product_phases, :creator_id, :users, :nullify
    add_properly_foreign_key :product_phases, :updater_id, :users, :nullify
    add_properly_foreign_key :product_phases, :intervention_id, :interventions, :nullify
    add_properly_foreign_key :product_phases, :product_id, :products, :cascade
    add_properly_foreign_key :product_phases, :variant_id, :product_nature_variants, :cascade
    add_properly_foreign_key :product_phases, :nature_id, :product_natures, :cascade
    add_properly_foreign_key :product_phases, :category_id, :product_nature_categories, :cascade
    # ProductReading
    add_properly_foreign_key :product_readings, :creator_id, :users, :nullify
    add_properly_foreign_key :product_readings, :updater_id, :users, :nullify
    add_properly_foreign_key :product_readings, :product_id, :products, :cascade
    # Purchase
    add_properly_foreign_key :purchases, :creator_id, :users, :nullify
    add_properly_foreign_key :purchases, :updater_id, :users, :nullify
    add_properly_foreign_key :purchases, :delivery_address_id, :entity_addresses, :nullify
    add_properly_foreign_key :purchases, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :purchases, :undelivered_invoice_journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :purchases, :quantity_gap_on_invoice_journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :purchases, :nature_id, :purchase_natures, :notnull_restrict
    change_column_null :purchases, :nature_id, false
    add_properly_foreign_key :purchases, :supplier_id, :entities, :cascade
    add_properly_foreign_key :purchases, :responsible_id, :users, :nullify
    add_properly_foreign_key :purchases, :contract_id, :contracts, :nullify
    add_properly_foreign_key :purchases, :affair_id, :affairs, :nullify
    # PurchaseAffair
    # PurchaseGap
    # PurchaseItem
    add_properly_foreign_key :purchase_items, :creator_id, :users, :nullify
    add_properly_foreign_key :purchase_items, :updater_id, :users, :nullify
    add_properly_foreign_key :purchase_items, :account_id, :accounts, :cascade
    add_properly_foreign_key :purchase_items, :activity_budget_id, :activity_budgets, :nullify
    add_properly_foreign_key :purchase_items, :team_id, :teams, :nullify
    add_properly_foreign_key :purchase_items, :purchase_id, :purchases, :cascade
    add_properly_foreign_key :purchase_items, :variant_id, :product_nature_variants, :cascade
    add_properly_foreign_key :purchase_items, :tax_id, :taxes, :cascade
    add_properly_foreign_key :purchase_items, :fixed_asset_id, :fixed_assets, :nullify
    add_properly_foreign_key :purchase_items, :depreciable_product_id, :products, :nullify
    # PurchaseNature
    add_properly_foreign_key :purchase_natures, :creator_id, :users, :nullify
    add_properly_foreign_key :purchase_natures, :updater_id, :users, :nullify
    add_properly_foreign_key :purchase_natures, :journal_id, :journals, :nullify
    # Regularization
    add_properly_foreign_key :regularizations, :creator_id, :users, :nullify
    add_properly_foreign_key :regularizations, :updater_id, :users, :nullify
    # Role
    add_properly_foreign_key :roles, :creator_id, :users, :nullify
    add_properly_foreign_key :roles, :updater_id, :users, :nullify
    # Sale
    add_properly_foreign_key :sales, :creator_id, :users, :nullify
    add_properly_foreign_key :sales, :updater_id, :users, :nullify
    add_properly_foreign_key :sales, :affair_id, :affairs, :nullify
    add_properly_foreign_key :sales, :client_id, :entities, :cascade
    add_properly_foreign_key :sales, :address_id, :entity_addresses, :nullify
    add_properly_foreign_key :sales, :delivery_address_id, :entity_addresses, :nullify
    add_properly_foreign_key :sales, :invoice_address_id, :entity_addresses, :nullify
    add_properly_foreign_key :sales, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :sales, :undelivered_invoice_journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :sales, :quantity_gap_on_invoice_journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :sales, :nature_id, :sale_natures, :notnull_restrict
    change_column_null :sales, :nature_id, false
    add_properly_foreign_key :sales, :credited_sale_id, :sales, :nullify
    add_properly_foreign_key :sales, :responsible_id, :entities, :nullify
    add_properly_foreign_key :sales, :transporter_id, :entities, :nullify
    # SaleAffair
    # SaleGap
    # SaleItem
    add_properly_foreign_key :sale_items, :creator_id, :users, :nullify
    add_properly_foreign_key :sale_items, :updater_id, :users, :nullify
    add_properly_foreign_key :sale_items, :account_id, :accounts, :nullify
    add_properly_foreign_key :sale_items, :activity_budget_id, :activity_budgets, :nullify
    add_properly_foreign_key :sale_items, :team_id, :teams, :nullify
    add_properly_foreign_key :sale_items, :sale_id, :sales, :cascade
    add_properly_foreign_key :sale_items, :credited_item_id, :sale_items, :nullify
    add_properly_foreign_key :sale_items, :variant_id, :product_nature_variants, :cascade
    add_properly_foreign_key :sale_items, :tax_id, :taxes, :restrict
    # SaleNature
    add_properly_foreign_key :sale_natures, :creator_id, :users, :nullify
    add_properly_foreign_key :sale_natures, :updater_id, :users, :nullify
    add_properly_foreign_key :sale_natures, :catalog_id, :catalogs, :cascade
    add_properly_foreign_key :sale_natures, :journal_id, :journals, :nullify
    add_properly_foreign_key :sale_natures, :payment_mode_id, :incoming_payment_modes, :nullify
    # SaleOpportunity
    # SaleTicket
    # Sensor
    add_properly_foreign_key :sensors, :creator_id, :users, :nullify
    add_properly_foreign_key :sensors, :updater_id, :users, :nullify
    add_properly_foreign_key :sensors, :product_id, :products, :nullify
    add_properly_foreign_key :sensors, :host_id, :products, :nullify
    # Sequence
    add_properly_foreign_key :sequences, :creator_id, :users, :nullify
    add_properly_foreign_key :sequences, :updater_id, :users, :nullify
    # Settlement
    # SubZone
    # Subscription
    add_properly_foreign_key :subscriptions, :creator_id, :users, :nullify
    add_properly_foreign_key :subscriptions, :updater_id, :users, :nullify
    add_properly_foreign_key :subscriptions, :address_id, :entity_addresses, :nullify
    add_properly_foreign_key :subscriptions, :nature_id, :subscription_natures, :notnull_restrict
    change_column_null :subscriptions, :nature_id, false
    add_properly_foreign_key :subscriptions, :parent_id, :subscriptions, :nullify
    add_properly_foreign_key :subscriptions, :sale_item_id, :sale_items, :nullify
    add_properly_foreign_key :subscriptions, :subscriber_id, :entities, :cascade
    change_column_null :subscriptions, :subscriber_id, false
    # SubscriptionNature
    add_properly_foreign_key :subscription_natures, :creator_id, :users, :nullify
    add_properly_foreign_key :subscription_natures, :updater_id, :users, :nullify
    # Supervision
    add_properly_foreign_key :supervisions, :creator_id, :users, :nullify
    add_properly_foreign_key :supervisions, :updater_id, :users, :nullify
    # SupervisionItem
    add_properly_foreign_key :supervision_items, :creator_id, :users, :nullify
    add_properly_foreign_key :supervision_items, :updater_id, :users, :nullify
    add_properly_foreign_key :supervision_items, :sensor_id, :sensors, :cascade
    add_properly_foreign_key :supervision_items, :supervision_id, :supervisions, :cascade
    # SynchronizationOperation
    add_properly_foreign_key :synchronization_operations, :creator_id, :users, :nullify
    add_properly_foreign_key :synchronization_operations, :updater_id, :users, :nullify
    add_properly_foreign_key :synchronization_operations, :notification_id, :notifications, :restrict
    # TargetDistribution
    add_properly_foreign_key :target_distributions, :creator_id, :users, :nullify
    add_properly_foreign_key :target_distributions, :updater_id, :users, :nullify
    add_properly_foreign_key :target_distributions, :activity_id, :activities, :cascade
    add_properly_foreign_key :target_distributions, :activity_production_id, :activity_productions, :cascade
    add_properly_foreign_key :target_distributions, :target_id, :products, :cascade
    # Task
    add_properly_foreign_key :tasks, :creator_id, :users, :nullify
    add_properly_foreign_key :tasks, :updater_id, :users, :nullify
    add_properly_foreign_key :tasks, :entity_id, :entities, :cascade
    add_properly_foreign_key :tasks, :sale_opportunity_id, :affairs, :nullify
    add_properly_foreign_key :tasks, :executor_id, :entities, :nullify
    # Tax
    add_properly_foreign_key :taxes, :creator_id, :users, :nullify
    add_properly_foreign_key :taxes, :updater_id, :users, :nullify
    add_properly_foreign_key :taxes, :collect_account_id, :accounts, :restrict
    add_properly_foreign_key :taxes, :deduction_account_id, :accounts, :restrict
    add_properly_foreign_key :taxes, :fixed_asset_collect_account_id, :accounts, :nullify
    add_properly_foreign_key :taxes, :fixed_asset_deduction_account_id, :accounts, :nullify
    add_properly_foreign_key :taxes, :intracommunity_payable_account_id, :accounts, :nullify
    # TaxDeclaration
    add_properly_foreign_key :tax_declarations, :creator_id, :users, :nullify
    add_properly_foreign_key :tax_declarations, :updater_id, :users, :nullify
    add_properly_foreign_key :tax_declarations, :financial_year_id, :financial_years, :cascade
    add_properly_foreign_key :tax_declarations, :journal_entry_id, :journal_entries, :restrict
    add_properly_foreign_key :tax_declarations, :responsible_id, :users, :nullify
    # TaxDeclarationItem
    add_properly_foreign_key :tax_declaration_items, :creator_id, :users, :nullify
    add_properly_foreign_key :tax_declaration_items, :updater_id, :users, :nullify
    add_properly_foreign_key :tax_declaration_items, :tax_id, :taxes, :cascade
    add_properly_foreign_key :tax_declaration_items, :tax_declaration_id, :tax_declarations, :cascade
    # TaxDeclarationItemPart
    add_properly_foreign_key :tax_declaration_item_parts, :creator_id, :users, :nullify
    add_properly_foreign_key :tax_declaration_item_parts, :updater_id, :users, :nullify
    # Team
    add_properly_foreign_key :teams, :creator_id, :users, :nullify
    add_properly_foreign_key :teams, :updater_id, :users, :nullify
    add_properly_foreign_key :teams, :parent_id, :teams, :nullify
    # Token
    add_properly_foreign_key :tokens, :creator_id, :users, :nullify
    add_properly_foreign_key :tokens, :updater_id, :users, :nullify
    # Tracking
    add_properly_foreign_key :trackings, :creator_id, :users, :nullify
    add_properly_foreign_key :trackings, :updater_id, :users, :nullify
    add_properly_foreign_key :trackings, :producer_id, :entities, :nullify
    add_properly_foreign_key :trackings, :product_id, :products, :nullify
    # User
    add_properly_foreign_key :users, :creator_id, :users, :nullify
    add_properly_foreign_key :users, :updater_id, :users, :nullify
    add_properly_foreign_key :users, :team_id, :teams, :nullify
    add_properly_foreign_key :users, :person_id, :entities, :nullify
    add_properly_foreign_key :users, :role_id, :roles, :nullify
    add_properly_foreign_key :users, :invited_by_id, :users, :nullify
    # Version
    add_properly_foreign_key :versions, :creator_id, :users, :nullify
    # Worker
    # Zone
  end

  def add_properly_foreign_key(table, column, to_table, mode)
    reversible do |d|
      d.up do
        if mode == :nullify || mode == :restrict
          execute "UPDATE #{table} SET #{column} = NULL WHERE #{column} IS NOT NULL AND #{column} NOT IN (SELECT id FROM #{to_table})"
        elsif mode == :cascade || mode == :notnull_restrict
          execute "DELETE FROM #{table} WHERE #{column} IS NULL OR (#{column} IS NOT NULL AND #{column} NOT IN (SELECT id FROM #{to_table}))"
        elsif mode == :null_cascade
          execute "DELETE FROM #{table} WHERE #{column} IS NOT NULL AND #{column} NOT IN (SELECT id FROM #{to_table})"
        end
      end
    end
    add_foreign_key table, to_table, column: column, on_update: :cascade, on_delete: mode.to_s.gsub(/^(notnull|null)\_/, '').to_sym
  end
end
