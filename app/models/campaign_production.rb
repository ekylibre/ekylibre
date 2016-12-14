# A CampaignProduction is a the same as an ActivityProduction for annual
# production but it represents the "year" of campaign or perennial productions.
class CampaignProduction
  attr_reader :campaign, :activity_production

  delegate :activity, to: :activity_production

  def self.of(campaign)
    campaign.activity_productions.map do |p|
      new(campaign, p)
    end
  end

  def initialize(campaign, activity_production)
    @campaign = campaign
    @activity_production = activity_production
  end

  def started_on
    @started_on ||= @activity_production.started_on_for(@campaign)
  end

  def stopped_on
    @stopped_on ||= @activity_production.stopped_on_for(@campaign)
  end

  # Compute cost amount in global currency for the current campaign production
  # Cost is the sum of all
  def cost_amount; end
end
