class AccountancyComputation

  # see short balance for items active / passive definition

  ACTIVE_LINES = %i[unsubcribed_capital incorporeal_assets_total_net corporeal_assets_total_net
                    alive_corporeal_assets_total_net financial_assets_total_net
                    long_cycle_alive_products_total_net short_cycle_alive_products_total_net
                    stocks_supply_net stocks_total_products_net entities_advance_giveables
                    entities_client_total_net entities_state_receivables entities_associate_receivables_net
                    entities_other_receivables_net entities_investment_security_net entities_reserve
                    entities_advance_charges entities_assets_gaps].freeze

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
