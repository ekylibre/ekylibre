module Backend
  class MapEditorShapesController < Backend::BaseController
    respond_to :json

    def index
      bb = []

      params[:layers] ||= %i[land_parcels plants]
      params[:started_at] ||= DateTime.now

      shapes = MapEditorManager.shapes started_at: params[:started_at], bounding_box: bb, layers: params[:layers]
      respond_with shapes
    end
  end
end
