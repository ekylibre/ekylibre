class Backend::Cells::WorkingSetsStocksCellsController < Backend::Cells::BaseController
  def show
    @working_set = params[:working_set] || :matters
    @working_set = @working_set.to_sym
    @indicator = Nomen::Indicator[params[:indicator] || :net_mass]
    @unit = (params[:unit] ? Nomen::Unit[params[:unit]] : @indicator.unit)
  end
end
