# -*- coding: utf-8 -*-
class Backend::Cells::ElapsedInterventionsTimesByActivitiesCellsController < Backend::Cells::BaseController

  def show
    @campaign = Campaign.order(harvest_year: :desc).first
  end

end
