# -*- coding: utf-8 -*-
class Backend::Cells::RevenuesByProductNatureCellsController < Backend::CellsController

  def show
    @campaign = Campaign.order("name ASC").last
  end

end
