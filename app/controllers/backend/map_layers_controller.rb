module Backend
  class MapLayersController < Backend::BaseController
    manage_restfully subclass_inheritance: true, redirect_to: :index

    respond_to :json, only: [:toggle, :star]

    def index
      @map_backgrounds = MapBackground.order('by_default DESC, enabled DESC, name')
      @map_overlays = MapOverlay.order('enabled DESC, name')
    end

    def load
      MapBackground.load_defaults
      MapOverlay.load_defaults
      redirect_to params[:redirect] || { action: :index }
    end

    def toggle
      return head :forbidden unless m = MapLayer.find_by(id: params[:id])

      # TODO: improve
      # Is a map background
      return head :forbidden if m.is_a?(MapBackground) && !!m.enabled && MapBackground.availables.length == 1

      toggle = !m.enabled
      m.update(enabled: toggle)

      id = nil

      # if map background is disabling but is by default
      # set the first available map background as default
      if !toggle && m.by_default
        mb = MapBackground.availables.first
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
      return unless m = MapBackground.find_by(id: params[:id])
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
