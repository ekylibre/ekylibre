# frozen_string_literal: true

class EconomicAccountancyComputation

  def initialize(campaign, activity = nil)
    @campaign = campaign
    if activity
      @activity = activity
      @activity_budget = ActivityBudget.find_by(campaign: @campaign, activity: @activity)
      @started_on = Date.new(@campaign.harvest_year + @activity.production_started_on_year, @activity.production_started_on.month, @activity.production_started_on.day)
      # production stopped_on + 1 year to include payment delay on price complements
      @stopped_on = Date.new(@campaign.harvest_year + @activity.production_stopped_on_year + 1, @activity.production_stopped_on.month, @activity.production_stopped_on.day)
    else
      @activity = nil
      @activity_budget = nil
      @started_on = Date.new(@campaign.harvest_year, 1, 1)
      @stopped_on = Date.new(@campaign.harvest_year, 12, 31)
    end
    @document = :economic_indicator
  end

  def sum_entry_items_by_line(line = nil, options = {})
    # remove closure entries
    options[:unwanted_journal_nature] ||= %i[result closure]
    options[:started_on] = @started_on
    options[:stopped_on] = @stopped_on
    if @activity_budget
      options[:activity_budget_id] = @activity_budget.id
    else
      options[:activity_budget_id] = 'only_nil'
    end

    equation = get_mandatory_line_calculation(line) if line
    equation ? Journal.sum_entry_items(equation, options) : 0
  end

  # get the equation to compute from accountancy abacus
  def get_mandatory_line_calculation(line = nil)
    data = load_accountancy_reference_file
    if data && @document && data[@document.to_s] && line
      data[@document.to_s][line]
    end
  end

  # load config file depends on accounting_system
  def load_accountancy_reference_file
    ac = Account.accounting_system
    source = Rails.root.join('config', "accountancy_mandatory_documents_#{ac.to_s}.yml")
    data = YAML.load_file(source).deep_symbolize_keys.stringify_keys if source.file?
  end
end
