# -*- coding: utf-8 -*-
class Backend::Cells::CurrentStocksByProductNatureCellsController < Backend::CellsController

  def show
    @variety = params[:variety] || :product
    @mass_unit = params[:mass_unit] || :kilogram
  end

end
