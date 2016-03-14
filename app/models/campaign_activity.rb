# A CampaignActivity design mainly a couple Campaign-Activity so it's not really
# an Activity. This model permits to manipulate the couple and compute results
# at its level
class CampaignActivity
  def initialize(campaign, activity)
    @campaign = campaign
    @activity = activity
  end

  # Returns list of CampaignProduction of current CampaignActivity
  def productions
    @productions ||= @campaign.activity_productions.where(activity: @activity)
                              .map { |p| CampaignProduction.new(@campaign, p) }
  end

  # Compute cost amount
  def cost_amount
    productions.map(&:cost_amount).sum
  end
end
