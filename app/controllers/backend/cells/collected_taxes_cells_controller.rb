# -*- coding: utf-8 -*-
class Backend::Cells::CollectedTaxesCellsController < Backend::CellsController

  def show
    @financial_years = FinancialYear.find(1)
  end

end
