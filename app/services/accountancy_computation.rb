class AccountancyComputation

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


end
