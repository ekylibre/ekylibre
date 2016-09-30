module Backend
  module InterventionsHelper
    def add_taskboard_tasks(interventions, column)
      interventions.each do |intervention|
        can_select = intervention.state != :validated
        colors = []
        task_datas = []
        text_icon = nil

        text_icon = 'check' if intervention.completely_filled?

        if intervention.targets.any?
          intervention.targets.find_each do |target|
            product = target.product

            next unless product

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

        if doers_count > 0

          doers_text = intervention.doers[0].product.name
          doers_text << ' +' + (doers_count - 1).to_s if doers_count > 1

          task_datas << { icon: 'user', text: doers_text, class: 'doers' }
        end

        intervention_datas = { id: intervention.id, name: intervention.name }

        column.task([{ text: intervention_datas[:name], icon: text_icon, icon_class: 'completely_filled' }],
                    task_datas, [], can_select, colors,
                    params: { class: '', data: { intervention: intervention_datas.to_json } })
      end
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
  end
end
