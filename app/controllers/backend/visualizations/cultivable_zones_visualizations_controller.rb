module Backend
  module Visualizations
    class CultivableZonesVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        main_serie = CultivableZone.find_each.map do |p|
          cz_shape = p.shape
          next if cz_shape.nil? || cz_shape.area.zero?

          popup_content = []

          # for all
          popup_content << {
            label: Onoma::Indicator[:net_surface_area].human_name,
            value: p.human_shape_area
          }

          popup_content << {
            label: CultivableZone.human_attribute_name(:owner),
            value: p.owner&.full_name
          }

          popup_content << {
            label: CultivableZone.human_attribute_name(:farmer),
            value: p.farmer&.full_name
          }

          popup_content << render_to_string(partial: 'popup', locals: { cz: p })

          serie = {
            name: p.name,
            shape: cz_shape,
            farmer: (p.farmer.present? ? p.farmer.full_name : Entity.of_company.full_name),
            owner: (p.owner.present? ? p.owner.full_name : Entity.of_company.full_name),
            popup: { header: true, content: popup_content }
          }
        end

        config = view_context.configure_visualization do |v|
          v.serie :main, main_serie
          v.categories :farmer, :main
          v.categories :owner, :main
        end

        respond_with config
      end
    end
  end
end
