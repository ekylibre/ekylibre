class AccountancyComputation

  ACTIVE_LINES = %i[unsubcribed_capital incorporeal_assets_creation_costs incorporeal_assets_others incorporeal_assets_advances
                    corporeal_assets_land_parcels corporeal_assets_settlements corporeal_assets_enhancement corporeal_assets_buildings
                    corporeal_assets_equipments corporeal_assets_others corporeal_assets_in_progress corporeal_assets_advances
                    alive_corporeal_assets_adult_animals alive_corporeal_assets_young_animals alive_corporeal_assets_service_animals
                    alive_corporeal_assets_perennial_plants alive_corporeal_assets_others alive_corporeal_assets_in_progress alive_corporeal_assets_advances
                    financial_assets_participations financial_assets_participations_debts financial_assets_others long_cycle_alive_products_animals
                    long_cycle_alive_products_plant_advance long_cycle_alive_products_plant_in_ground long_cycle_alive_products_wine
                    long_cycle_alive_products_others short_cycle_alive_products_animals short_cycle_alive_products_plant_advance
                    short_cycle_alive_products_plant_in_ground short_cycle_alive_products_others stocks_supply stocks_end_products stocks_others_products
                    entities_advance_giveables entities_client_receivables entities_others_clients entities_state_receivables entities_associate_receivables
                    entities_other_receivables entities_investment_security entities_reserve entities_advance_charges entities_assets_gaps]

  PASSIVE_LINES = %i[capitals_values capitals_emissions reevaluation_gaps capitals_liability_reserves capitals_anew_reports capitals_profit_or_loss
                     capitals_investment_subsidies capitals_derogatory_depreciations capitals_mandatory_provisions capitals_risk_and_charges_provisions
                     debts_land_parcel_loans debts_others_loans debts_associate_locked_debts debts_cashe_debts debts_other_financial_debts
                     others_debts_advance_receivables others_debts_supplier_receivables others_debts_state_debts others_debts_social_debts
                     others_debts_associate_debts others_debts_fixed_asset_debts others_debts_others others_debts_advance_products
                     others_debts_liabilities_gaps]

  def initialize(year, nature = :profit_and_loss_statement)
    @year = year
    @currency = @year.currency
    @started_on = @year.started_on
    @stopped_on = @year.stopped_on
    @document = nature
  end

  # get the equation to compute from accountancy abacus
  def get_mandatory_line_calculation(document = @document, line = nil)
    ac = Account.accounting_system
    source = Rails.root.join('config', 'accoutancy_mandatory_documents.yml')
    data = YAML.load_file(source).deep_symbolize_keys.stringify_keys if source.file?
    if data && ac && document && line
      data[ac.to_s][document][line] if data[ac.to_s] && data[ac.to_s][document]
    end
  end

  def sum_entry_items_by_line(document = @document, line = nil, options = {})
    # remove closure entries
    options[:unwanted_journal_nature] ||= [:closure] if document == :balance_sheet
    options[:unwanted_journal_nature] ||= %i[result closure]

    equation = get_mandatory_line_calculation(document, line) if line
    equation ? @year.sum_entry_items(equation, options) : 0
  end

  def active_balance_sheet_amount
    ACTIVE_LINES.reduce(0) { |sum, line| sum + sum_entry_items_by_line(:balance_sheet, line) }
  end

  def passive_balance_sheet_amount
    PASSIVE_LINES.reduce(0) { |sum, line| sum + sum_entry_items_by_line(:balance_sheet, line) }
  end
end
