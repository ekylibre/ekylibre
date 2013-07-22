# -*- coding: utf-8 -*-
class Backend::DataView::ManureManagementPlansController < Backend::DataViewController

  def show
    campaign = Campaign.find_by_id(:params[campaign_id])
    campaign ||= Campaign.last
    respond_with ManureManagementPlan.new(campaign)
  end

end
