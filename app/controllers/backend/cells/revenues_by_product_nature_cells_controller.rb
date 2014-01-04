# -*- coding: utf-8 -*-
class Backend::Cells::RevenuesByProductNatureCellsController < Backend::CellsController

  def show
    @stopped_on = Date.today.end_of_month
    @started_on = @stopped_on.beginning_of_month << 11
  end

end
