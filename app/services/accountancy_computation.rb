class AccountancyComputation

  # see short balance for items active / passive definition

  PCGA_ACTIVE_LINES = %i[unsubcribed_capital incorporeal_assets_total_net corporeal_assets_total_net
                    alive_corporeal_assets_total_net financial_assets_total_net
                    long_cycle_alive_products_total_net short_cycle_alive_products_total_net
                    stocks_supply_net stocks_total_products_net
                    entities_advance_giveables
                    entities_client_total entities_state_receivables entities_associate_receivables_net
                    entities_other_receivables_net entities_investment_security_net
                    entities_reserve entities_advance_charges entities_assets_gaps].freeze

  PCG82_ACTIVE_LINES = %i[unsubcribed_capital incorporeal_assets_total_net corporeal_assets_total_net financial_assets_total_net
                    raw_matters_total_net stocks_supply_products_total_net stocks_supply_services_total_net
                    stocks_middle_products_total_net stocks_end_products_total_net
                    entities_advance_giveables
                    entities_client_total entities_state_receivables entities_associate_receivables_net
                    entities_other_receivables_net entities_investment_security_net
                    entities_reserve entities_advance_charges entities_assets_gaps].freeze

  PASSIVE_LINES = %i[capitals_values capitals_emissions reevaluation_gaps capitals_liability_reserves
                     capitals_anew_reports capitals_profit_or_loss capitals_investment_subsidies
                     capitals_risk_and_charges_provisions_total debts_loans_total others_debts_advance_receivables
                     others_debts_supplier_receivables others_debts_state_debts debts_associate_total
                     others_debts_social_debts others_debts_total debts_cashe_debts_total
                     others_debts_advance_products others_debts_liabilities_gaps].freeze

  def initialize(year, nature = :profit_and_loss_statement)
    @year = year
    @currency = @year.currency
    @started_on = @year.started_on
    @stopped_on = @year.stopped_on
    @document = nature
  end

  # get the equation to compute from accountancy abacus
  def get_mandatory_line_calculation(document = @document, line = nil)
    data = load_accountancy_reference_file
    if data && document && data[document.to_s] && line
      data[document.to_s][line]
    end
  end

  def sum_entry_items_by_line(document = @document, line = nil, options = {})
    # remove closure entries
    options[:unwanted_journal_nature] ||= [:closure] if (document == :balance_sheet || document == :short_balance_sheet)
    options[:unwanted_journal_nature] ||= %i[result closure]

    equation = get_mandatory_line_calculation(document, line) if line
    equation ? @year.sum_entry_items(equation, options) : 0
  end

  # see short balance sheet in YML files for items active / passive definition
  def active_balance_sheet_amount
    ac = Account.accounting_system
    if ac == 'fr_pcga'
      PCGA_ACTIVE_LINES.reduce(0) { |sum, line| sum + sum_entry_items_by_line(:short_balance_sheet, line) }
    elsif ac == 'fr_pcg82'
      PCG82_ACTIVE_LINES.reduce(0) { |sum, line| sum + sum_entry_items_by_line(:short_balance_sheet, line) }
    end
  end

  def passive_balance_sheet_amount
    PASSIVE_LINES.reduce(0) { |sum, line| sum + sum_entry_items_by_line(:short_balance_sheet, line) }
  end

  # load config file depends on accounting_system
  def load_accountancy_reference_file
    ac = Account.accounting_system
    source = Rails.root.join('config', "accountancy_mandatory_documents_#{ac.to_s}.yml")
    data = YAML.load_file(source).deep_symbolize_keys.stringify_keys if source.file?
  end

end
