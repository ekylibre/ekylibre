class Backend::Cells::RevenuesByProductNatureCellsController < Backend::Cells::BaseController
  def show
    @stopped_at = Date.today.end_of_month
    @started_at = @stopped_at.beginning_of_month << 11
  end
end
