class Backend::Cells::EventsCellsController < Backend::CellsController

  def show
    mode = (params[:mode] || :all).to_s.gsub('_', '-')
    @events = Event.without_restrictions_for(current_user)
    @events = @events.with_participant(current_user) if mode =~ /\bmy\b/
    now = Time.now
    if mode =~ /\bfuture\b/
      @events = @events.after(now).reorder(started_at: :desc)
    elsif mode =~ /\blast\b/
      @events = @events.before(now).reorder(started_at: :desc)
    end
    count = params[:count].to_i
    count = 5 unless 0 < count and count <= 50
    @events = @events.limit(count)
  end

end
