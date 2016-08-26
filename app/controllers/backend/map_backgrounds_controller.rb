module Backend
  class MapBackgroundsController < Backend::BaseController
    manage_restfully

    respond_to :json, only: [:toggle, :star]

    def index
      @map_backgrounds = MapBackground.order('by_default DESC, enabled DESC, name')
    end

    def load
      MapBackground.load_defaults
      redirect_to params[:redirect] || { action: :index }
    end

    def toggle
      if m = MapBackground.find_by_id(params[:id])

        if !!m.enabled && MapBackground.availables.length == 1
          return head :forbidden
        end
        toggle = !m.enabled
        m.update(enabled: toggle)

        id = nil

        # if map background is disabling but is by default
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
      else
        head :forbidden
      end
    end

    def star
      return unless m = MapBackground.find_by_id(params[:id])
      m.update(by_default: !m.by_default)
      head :no_content
    end

    def destroy
      return unless m = MapBackground.find_by_id(params[:id])
      m.destroy
      head :no_content
    end
  end
end
