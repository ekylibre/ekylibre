module Backend
  module Cells
    class EventsCellsController < Backend::Cells::BaseController
      def show
        mode = (params[:mode] || :all).to_s.tr('_', '-')
        @events = (mode =~ /\bmy\b/ ? Event.with_participant(current_user.person) : Event.without_restrictions_for(current_user.person))
        now = Time.zone.now
        if mode =~ /\bfuture\b/
          @events = @events.after(now).reorder(started_at: :asc)
        elsif mode =~ /\blast\b/
          @events = @events.before(now).reorder(started_at: :desc)
        end
        count = params[:count].to_i
        count = 5 unless 0 < count && count <= 50
        @events = @events.limit(count)
      end
    end
  end
end
