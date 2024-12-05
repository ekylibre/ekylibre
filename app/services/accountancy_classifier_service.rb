# frozen_string_literal: true

class AccountancyClassifierService
  attr_reader :log_result

  def self.classify_from_data(*args)
    new(*args).classify_from_data
  end

  def self.call(*args)
    new(*args).classify_from_ia
  end

  def initialize(journal_entry_item_ids: )
    @jei = JournalEntryItem.where(id: journal_entry_item_ids).where("activity_budget_id IS NULL").reorder(:printed_on)
    @log_result = {}
  end

  def classify_from_data
    @jei.each do |item|
      similar_items = JournalEntryItem.where("account_id = ? AND activity_budget_id IS NOT NULL AND similarity(LOWER(unaccent(name)), LOWER(unaccent(?))) >= 0.8", item.account_id, item.name).reorder(:printed_on)
      if similar_items.present?
        reference_item = similar_items.last
        item.update!(activity_budget_id: reference_item.activity_budget_id)
      end
    end
  end

  def classify_from_ia
    # filter because maybe already classify from data in the same instanciation
    not_classify_jei = @jei.where("activity_budget_id IS NULL")
    # build data to send to Mistral
    data = not_classify_jei.map{|i| "#{i.id.to_s} - #{i.name + ' ' + i.account.name}"}.join('|')
    # call Mistral Ner service (::Ner)
    activity_list = Activity.all.pluck(:name).to_sentence
    c = Clients::Mistral::Ner.new
    result = c.extract_accountancy_metadata(data, :accountancy_classification, activity_list)
    puts result.inspect.yellow
    # return result[:error] if result[:error].present?
    @log_result[:items_classified] = 0
    not_classify_jei.each do |entry_item|
      matching_item = result.find { |item| item[:id] == entry_item.id.to_s }
      next unless matching_item.present?

      puts entry_item.name.inspect.yellow
      puts matching_item.inspect.red
      if matching_item[:classification].present? && matching_item[:classification] != "nil"
        act = Activity.find_by(name: matching_item[:classification])
        next unless act

        puts act.inspect.green
        # if month before production stopped_on
        # harvest_year = printed_on.year
        if (entry_item.printed_on.month < act.production_stopped_on.month)
          campaign = Campaign.find_or_create_by(harvest_year: entry_item.printed_on.year)
        # if month after or equal production stopped_on
        # harvest_year = printed_on.year + 1
        elsif (entry_item.printed_on.month >= act.production_stopped_on.month)
          campaign = Campaign.find_or_create_by!(harvest_year: entry_item.printed_on.year + 1)
        end
        activity_budget = ActivityBudget.find_or_create_by!(campaign: campaign, activity: act)
        # check production date to set good campaign according to account printed_on
        # set activity budget to bs_item
        entry_item.update!(activity_budget_id: activity_budget.id)
        @log_result[:items_classified] += 1
      end
    end
    @log_result
  end
end
