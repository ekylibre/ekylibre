module Backend
  class MapBackgroundsController < Backend::BaseController

    def index

      # TMP
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

    def load_defaults
      MapBackground.import_all
      redirect_to params[:redirect] || { action: :index }
    end
  end
end
