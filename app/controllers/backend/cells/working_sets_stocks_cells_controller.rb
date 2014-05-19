# -*- coding: utf-8 -*-
class Backend::Cells::WorkingSetsStocksCellsController < Backend::CellsController

  def show
    @working_set = params[:working_set] || :matters
    @working_set = @working_set.to_sym
    @indicator = Nomen::Indicators[params[:indicator] || :net_mass]
    @unit = (params[:unit] ? Nomen::Units[params[:unit]] : @indicator.unit)
  end

end
