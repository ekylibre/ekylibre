module Backend
  class MapLayersController < Backend::BaseController
    manage_restfully except: :index, identifier: :name

    respond_to :json, only: %i[toggle star]

    def index
      @map_layers = MapLayer.order('nature, by_default DESC, enabled DESC, name')
      @bounds = CultivableZone.first ? CultivableZone.first.shape_centroid : [44.8423142, -0.5988415]
    end

    def load
      MapLayer.load_defaults
      redirect_to params[:redirect] || { action: :index }
    end

    def toggle
      return head :forbidden unless m = MapLayer.find_by(id: params[:id])
      return head :forbidden if m.background? && !!m.enabled && MapLayer.available_backgrounds.length == 1

      toggle = !m.enabled
      m.update(enabled: toggle)

      id = nil

      # if map background is disabling but is by default
      # set the first available map background as default
      if !toggle && m.by_default
        mb = MapLayer.available_backgrounds.first
        unless mb.nil?
          mb.update(by_default: true)
          id = mb.id
        end
      end

      respond_to do |format|
        format.json { render json: { new_default: id } }
      end
    end

    def star
      return unless m = MapLayer.backgrounds.find_by(id: params[:id])
      m.update(by_default: !m.by_default)
      head :no_content
    end

    def destroy
      m = MapLayer.find_by(id: params[:id])
      return head :forbidden if m.nil? || m.managed
      m.destroy
      head :no_content
    end
  end
end
