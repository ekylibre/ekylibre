module Backend
  class MapEditorShapesController < Backend::BaseController
    respond_to :json

    def index
      shapes = MapEditorManager.shapes started_at: params[:started_at], bounding_box: params[:bounds], layers: params[:layers]
      respond_with shapes
    end
  end
end
