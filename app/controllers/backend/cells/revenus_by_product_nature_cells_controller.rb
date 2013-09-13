# -*- coding: utf-8 -*-
class Backend::Cells::RevenusByProductNatureCellsController < Backend::CellsController

  def show
    @campaign = Campaign.order("name ASC").last
  end

end
