module Backend
  module Visualizations
    class StockContainerMapCellsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        config = {}
        data = []

        transcode_icon = { 'Variants::EquipmentVariant': :tractor,
                          'Variants::Articles::SeedAndPlantArticle': :"seedling-solid",
                          'Variants::Articles::FertilizerArticle': :fertilization,
                          'Variants::Articles::FarmProductArticle': :wheat,
                          'Variants::Articles::PlantMedicineArticle': :"chemical-product",
                          'Variants::AnimalVariant': :cow,
                          'Variants::ArticleVariant': :matter,
                          'Variants::ServiceVariant': :"users-cog" }

        visualization_face = params[:visualization]
        campaigns = params[:campaigns]

        BuildingDivision.all.each do |building_division|
          if building_division.shape
            popup_lines = []
            bottom_line = ''
            # net_surface_area
            popup_lines << {
              label: Onoma::Indicator[:net_surface_area].human_name,
              value: building_division.human_shape_area
            }
            # occupation percentage
            popup_lines << {
              label: :occupation_percentage.tl,
              value: building_division.occupation_percentage
            }

            popup_lines << view_context.link_to(:show.tl, { controller: "/backend/building_divisions", action: :show, id: building_division.id }, class: 'btn btn-default')
            products = Product.contained_by(building_division)
            if products.any?
              popup_lines << { label: :contained_products.tl }
              bottom_line += "<table><tr><th>Type</th><th>Qt</th></tr>"
              products.group_by { |p| p.variant.type }.each do |variant_type, products|
                puts variant_type.inspect.red
                icon = transcode_icon[variant_type.to_sym]&.to_s
                if icon
                  bottom_line += "<tr><td><i class='icon icon-#{icon}' style='color: green;'></i></td>"
                else
                  bottom_line += "<tr><td><i class='icon icon-question' style='color: orange;'></i></td>"
                end
                bottom_line += "<td>#{products.map(&:population).compact.sum.round_l}</td></tr>"
              end
              bottom_line += "</table>"
            end
            popup_lines << ("<div style='display: flex; justify-content: space-between'>" + bottom_line + '</div>').html_safe
            header_content = "<span class='product-name'>#{building_division.name} - #{building_division.work_number}</span>".html_safe
            item = {
                      name:       building_division.name,
                      nature:     building_division.nature_name,
                      shape:      building_division.shape,
                      occupation_percentage:      building_division.occupation_percentage,
                      popup: { header: header_content, content: popup_lines }
                    }
            data << item
          end
        end

        config = view_context.configure_visualization do |v|
          v.serie :main, data
          v.choropleth :occupation_percentage, :main, stop_color: "#F10000", start_color: "#FFFFFF", opacity: 0.5
        end

        respond_with config
      end

    end
  end
end
