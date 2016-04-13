module Backend
  class MapBackgroundsController < Backend::BaseController

    def index

      @map_backgrounds = MapBackground.all

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
  end
end
