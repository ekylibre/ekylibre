module Backend
  class MapBackgroundsController < Backend::BaseController
    manage_restfully

    respond_to :json, only: [:toggle_enabled, :toggle_by_default]

    def index
      @map_backgrounds = MapBackground.order('by_default DESC, enabled DESC, name')
    end

    def load
      MapBackground.load_defaults
      redirect_to params[:redirect] || { action: :index }
    end

    def toggle_enabled
      return unless m = MapBackground.find_by_id(params[:id])
      m.update(enabled: !m.enabled)
      head :no_content
    end

    def toggle_by_default
      return unless m = MapBackground.find_by_id(params[:id])
      m.update(by_default: !m.by_default)
      head :no_content
    end
  end
end
