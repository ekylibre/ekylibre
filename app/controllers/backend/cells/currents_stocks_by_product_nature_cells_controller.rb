# -*- coding: utf-8 -*-
class Backend::Cells::CurrentsStocksByProductNatureCellsController < Backend::CellsController

  def show
    @variety = params[:variety] || :product
  end

end
