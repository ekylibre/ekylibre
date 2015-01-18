# -*- coding: utf-8 -*-
class Backend::Cells::ExpensesByProductNatureCategoryCellsController < Backend::CellsController

  def show
    @stopped_at = Date.today.end_of_month
    @started_at = @stopped_at.beginning_of_month << 11
  end

end
