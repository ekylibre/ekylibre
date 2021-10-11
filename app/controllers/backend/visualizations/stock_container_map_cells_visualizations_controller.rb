module Backend
  module Visualizations
    class StockContainerMapCellsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        config = {}
        data = []

        transcode_icon = { 'Variants::EquipmentVariant': :tractor,
                          'Variants::Articles::SeedAndPlantArticle': :matter,
                          'Variants::Articles::FertilizerArticle': :matter,
                          'Variants::Articles::PlantMedicineArticle': :beaker,
                          'Variants::AnimalVariant': :cow }

        visualization_face = params[:visualization]
        campaigns = params[:campaigns]

        BuildingDivision.all.each do |building_division|
          if building_division.shape
            popup_lines = []
            bottom_line = ''
            # net_surface_area
            popup_lines << {
              label: Onoma::Indicator[:net_surface_area].human_name,
              value: building_division.net_surface_area.to_d(:square_meter).round(2).l
            }
            popup_lines << view_context.link_to(:show.tl, { controller: "/backend/building_divisions", action: :show, id: building_division.id }, class: 'btn btn-default')
            products = Product.contained_by(building_division)
            if products.any?
              products.group_by { |p| p.variant.type }.each do |variant_type, _products|
                icon = transcode_icon[variant_type.to_sym]&.to_s
                if icon
                  bottom_line += "<i class='icon icon-#{icon}' style='color: green;'></i>"
                end
              end
            end
            popup_lines << ("<div style='display: flex; justify-content: space-between'>" + bottom_line + '</div>').html_safe
            header_content = "<span class='product-name'>#{building_division.name} - #{building_division.work_number}</span>".html_safe
            item = {
                      name:       building_division.name,
                      nature:     building_division.nature_name,
                      shape:      building_division.shape,
                      popup: { header: header_content, content: popup_lines }
                    }
            data << item
          end
        end

        config = view_context.configure_visualization do |v|
          v.serie :main, data
          v.simple :nature, :main, fill_color: '#33a2ff'
        end

        respond_with config
      end

    end
  end
end
