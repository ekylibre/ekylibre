class Backend::Cells::EventsCellsController < Backend::CellsController

  def show
    mode = (params[:mode] || :all).to_s.gsub('_', '-')
    @events = Event.without_restriction_for(current_user)
    @events = @events.with_participant(current_user) if mode =~ /\bmy\b/
    if mode =~ /\bfuture\b/
      today = Date.today
      @events = @events.where("COALESCE(CAST(started_at AS DATE), ?) >= ?", today, today)
    elsif mode =~ /\blast\b/
      today = Date.today
      @events = @events.where("COALESCE(CAST(stopped_at AS DATE), ?) <= ?", today, today)
    end
    count = params[:count].to_i
    count = 5 unless 0 < count and count <= 50
    @events = @events.limit(count)
  end

end
