module Backend
  class MapBackgroundsController < Backend::BaseController

    respond_to :json, only: [:toggle_enabled, :toggle_by_default]
    def index

      @map_backgrounds = MapBackground.order(enabled: :desc)

    end

    def new

    end

    def create

    end

    def update

    end

    def destroy

    end

    def load
      MapBackground.load_defaults
      redirect_to params[:redirect] || { action: :index }
    end

    def toggle_enabled
      return unless m = MapBackground.find(params[:id])
      m.update_attribute(:enabled, !m.enabled)
      respond_with m.to_json
    end
  end
end
