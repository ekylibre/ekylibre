# -*- coding: utf-8 -*-
class Backend::Cells::CurrentStocksByProductNatureCellsController < Backend::CellsController

  def show
    @variety = params[:variety] || :product
    @indicator = Nomen::Indicators[params[:indicator] || :net_mass]
    @unit = (params[:unit] ? Nomen::Units[params[:unit]] : @indicator.unit)
  end

end
