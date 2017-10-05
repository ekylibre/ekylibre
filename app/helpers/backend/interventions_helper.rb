module Backend
  module InterventionsHelper
    include ChartsHelper

    def add_taskboard_tasks(interventions, column)
      interventions.each do |intervention|
        column.task(*taskboard_task(intervention))
      end
    end

    def taskboard_task(intervention)
      can_select = intervention.state != :validated
      colors = []
      task_datas = []
      text_icon = nil

      text_icon = 'check' if intervention.completely_filled?

      if intervention.targets.any?
        intervention.targets.find_each do |target|
          product = target.product

          next unless product

          activity_color = target.product.activity.color if product.activity

          if (activity_production = ActivityProduction.find_by(support: product))
            activity_color = activity_production.activity.color
            if activity_production.cultivable_zone
              displayed_name = activity_production.cultivable_zone.work_number
            end
          end

          activity_color ||= '#777777'
          displayed_name ||= product.work_number.blank? ? product.name : product.work_number

          icon = if product.is_a?(LandParcel) || product.is_a?(Plant)
                   'land-parcels'
                 elsif product.is_a?(Animal) || product.is_a?(AnimalGroup)
                   'cow'
                 elsif product.is_a?(Equipment) || product.is_a?(EquipmentFleet)
                   'tractor'
                end

          task_datas << { icon: icon, text: displayed_name, style: "background-color: #{activity_color}; color: #{contrasted_color(activity_color)}" }
        end
      end

      doers_count = intervention.doers.count

      if doers_count > 0 && !intervention.doers[0].product.nil?

        doers_text = intervention.doers[0].product.name
        doers_text << ' +' + (doers_count - 1).to_s if doers_count > 1

        task_datas << { icon: 'user', text: doers_text, class: 'doers' }
      end

      intervention_datas = { id: intervention.id, name: intervention.name }

      request_intervention_id = ''
      request_intervention_id = intervention.request_intervention_id unless intervention.request_intervention_id.nil?

      [[{ text: intervention_datas[:name], icon: text_icon, icon_class: 'completely_filled' }],
       task_datas, [], can_select, colors,
       params: { class: '', data: { intervention: intervention_datas.to_json, request_intervention_id: request_intervention_id } }]
    end

    def add_detail_to_modal_block(title, detail, options)
      html = []

      icon = options[:icon] || nil
      image = options[:image] || nil

      content_tag(:div, nil, class: 'data') do
        html << content_tag(:div, nil, class: 'picture') do
          picture = content_tag(:i, nil, class: "picto #{icon}") unless icon.nil?
          picture = image_tag(image, class: 'image') unless image.nil?

          picture
        end

        html << content_tag(:div, nil, class: 'details') do
          content_tag(:h4, title, class: 'data-title') +
            content_tag(:p, detail)
        end

        html.join.html_safe
      end
    end

    def new_geometry_collection(geometries)
      if geometries.is_a?(Array) && geometries.any?
        Charta.new_geometry("SRID=4326;GEOMETRYCOLLECTION(#{geometries.map { |geo| geo[:shape].to_wkt.split(';')[1] }.join(',')})") # .convert_to(:multi_polygon)
      else
        Charta.empty_geometry
      end
    end
    
    def add_working_period_cost(product_parameter, nature: nil)
      render partial: 'intervention_costs', locals: { product_parameter: product_parameter, nature: nature }
    end

    def add_total_working_period(product_parameter, natures: {})
      render partial: 'intervention_total_costs', locals: { product_parameter: product_parameter, natures: natures }
    end
  end
end
