# -*- coding: utf-8 -*-
class Backend::Cells::ElapsedInterventionsTimesByActivitiesCellsController < Backend::CellsController

  def show
    @campaign = Campaign.order(:name).last
  end

end
