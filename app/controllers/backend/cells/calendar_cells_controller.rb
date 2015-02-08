class Backend::Cells::CalendarCellsController < Backend::Cells::BaseController

  def show
    year  = params[:year]  || Date.today.year
    month = params[:month] || Date.today.month
    started_at = Time.new(year.to_i, month.to_i, 1)
    @events = Event.between(started_at, started_at.end_of_month).includes(participations: [:participant])
    if request.xhr? and params[:year] and params[:month]
      render partial: "month"
    end
  end

end
