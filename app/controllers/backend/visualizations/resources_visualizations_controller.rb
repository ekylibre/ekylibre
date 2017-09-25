module Backend
  module Visualizations
    class ResourcesVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show

        resource_model = params[:resource_name].classify.constantize
        controller = "/backend/#{resource_model.model_name.plural}"

        label_method = params.delete(:label_method) || :name
        shape_method = params.delete(:shape_method) || :shape
        popup = params.delete(:popup)
        params[:id] ||= resource_model.model_name.human

        data = resource_model.find_each.collect do |record|
          if popup.respond_to?(:call)
            feature = popup.call(record)
          elsif popup.is_a?(String)
            feature = render_to_string popup, object: record, resource: record
          else
            area_unit = params[:area_unit] || :hectare
            content = []
            content << { label: Nomen::Indicator.find(:net_surface_area).human_name,
                         value: record.net_surface_area.in(area_unit).round(3).l }
            content << view_context.content_tag(:div, class: 'btn-group') do
              view_context.link_to(:show.tl, { controller: controller, action: :show, id: record.id }, class: 'btn btn-default') +
                  view_context.link_to(:edit.tl, { controller: controller, action: :edit, id: record.id }, class: 'btn btn-default')
            end
            feature = { popup: { content: content, header: true } }
          end
          feature[:name] ||= record.send(label_method)
          feature[:shape] ||= record.send(shape_method)
          feature
        end


        layer_options = {}
        layer_options[:fill_color] = params[:color] if params[:color]

        config = view_context.configure_visualization do |v|
          v.serie :main, data

          v.simple params[:id] || :items, :main, layer_options
        end

        respond_with config
      end
    end
  end
end