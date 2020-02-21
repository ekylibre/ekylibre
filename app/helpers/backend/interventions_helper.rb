module Backend
  module InterventionsHelper
    include ChartsHelper

    def add_taskboard_tasks(interventions, column)
      interventions.each do |intervention|
        column.task(*taskboard_task(intervention))
      end
    end

    def compare_with_planned(params)
      result = params.compare_with_planned
      image_path = if result
        'interventions/calendar-v.svg'
      else
        'interventions/calendar-!.svg'
      end
      image_tag(image_path, class: 'calendar-img')
    end

    def next_state
      intervention = @interventions.present? ? @interventions.first : @intervention
      next_state = if intervention.nature == :request
        'in_progress'
      else
        case intervention.state
          when 'in_progress' then 'done'
          when 'done' then 'validated'
        end
      end
      Intervention.state.options.find { |_, v| v == next_state } if next_state
    end

    def taskboard_task(intervention)
      can_select = intervention.state != :validated
      colors = []
      task_datas = []

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

          task_datas << { icon: icon, text: displayed_name, style: "background-color: #{activity_color}; color: #{contrasted_color(activity_color)}", category: 'parameters' }
        end
      end

      doers_count = intervention.doers.count

      if doers_count > 0 && !intervention.doers[0].product.nil?

        doers_text = intervention.doers[0].product.name
        doers_text << ' +' + (doers_count - 1).to_s if doers_count > 1

        task_datas << { icon: 'user', text: doers_text, class: 'doers', category: 'parameters' }
      end

      if user_preference_value(User::PREFERENCE_SHOW_COMPARE_REALISED_PLANNED) && intervention.record?
        compare_planned_and_realised = intervention.compare_planned_and_realised
        if compare_planned_and_realised == :no_request
          task_datas << { image: 'interventions/calendar-no.svg', class: 'task-calendar no-request', category: 'indicators', position_number: 1 }
        elsif compare_planned_and_realised
          task_datas << { image: 'interventions/calendar-v.svg', class: 'task-calendar similar', category: 'indicators', position_number: 1 }
        else
          task_datas << { image: 'interventions/calendar-!.svg', class: 'task-calendar not-similar', category: 'indicators', position_number: 1 }
        end
      end

      task_datas << { icon: 'mobile', class: 'provided-by-zero', category: 'indicators', position_number: 0 } if intervention.is_provided_by?(vendor: 'Ekylibre', name: 'zero')

      intervention_datas = { id: intervention.id, name: intervention.name }

      request_intervention_id = ''
      request_intervention_id = intervention.request_intervention_id unless intervention.request_intervention_id.nil?

      [[{ text: intervention_datas[:name] }],
       task_datas, [], can_select, colors,
       params: { class: '', data: { intervention: intervention_datas.to_json, request_intervention_id: request_intervention_id } }]
    end

    def add_detail_to_modal_block(title, detail, product_parameter = nil, options)
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
          concat(content_tag(:div, nil, class: 'name-details') do
            concat(content_tag(:h4, title, class: 'data-title'))
            concat(content_tag(:p, detail))
          end)
          if product_parameter.present?
            computation = calculate_cost_amount_computation(product_parameter)
            concat(content_tag(:div, nil, class: 'working-time') do
              concat(content_tag(:i, nil, class: 'picto picto-timelapse'))
              concat(content_tag(:span, human_duration(computation.quantity * 3600), class: 'quantity'))
            end)
          end
        end

        html.join.html_safe
      end
    end

    # This method has the same use as the `add_detail_to_modal_block` method but with less informations
    def add_small_details_to_modal_block(title, product_parameter)
      html = []

      computation = calculate_cost_amount_computation(product_parameter)

      html << content_tag(:div, nil, class: 'details', data: { product_id: product_parameter.product.id, type: product_parameter.type, duration: computation.quantity }) do
        concat(content_tag(:h4, title))
        concat(content_tag(:div, nil, class: 'working-time') do
          concat(content_tag(:i, nil, class: 'picto picto-timelapse'))
          concat(content_tag(:span, human_duration(computation.quantity * 3600), class: 'quantity'))
        end)
      end
      html.join.html_safe
    end

    def calculate_cost_amount_computation(product_parameter)
      if product_parameter.product.is_a?(Worker)
        computation = product_parameter.cost_amount_computation
      elsif product_parameter.product.try(:tractor?)
        if product_parameter.participation.present? || product_parameter.intervention&.doers&.map(&:participation).compact.present?
          computation = product_parameter.cost_amount_computation(natures: %i[travel intervention])
        else
          computation = product_parameter.cost_amount_computation(natures: %i[intervention])
        end
      else
        computation = product_parameter.cost_amount_computation(natures: %i[intervention])
      end
      computation
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
