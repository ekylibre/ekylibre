module Backend::HorizontalTimelineHelper
  class HorizontalTimeline

    def initialize()
    end
  end

  #def horizontal_timeline(object, options = {}, &_block)
  def horizontal_timeline
    #if object
    #  line = HorizontalTimeline.new(object, options)
    #  yield line
    #  render partial: 'backend/shared/horizontal_timeline.html', locals: {}
    #end

    render partial: 'backend/shared/horizontal_timeline.html', locals: {}
  end
end
