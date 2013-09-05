# -*- coding: utf-8 -*-
class Backend::Cells::BankChartCellsController < Backend::CellsController

  def show
    @financial_years = FinancialYear.current
  end

end
