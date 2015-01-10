# -*- coding: utf-8 -*-
class Backend::Cells::StockContainerMapCellsController < Backend::CellsController

  def show
    @variety = params[:variety] || :product
  end

end
