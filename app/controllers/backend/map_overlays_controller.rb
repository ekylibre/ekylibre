module Backend
  class MapOverlaysController < Backend::MapLayersController

    def index
      redirect_to backend_map_layers_path
    end
  end
end
