module Backend
  module InterventionsHelper

    def add_tasks(interventions, block)

      tasks = []

      interventions.each do |intervention|

        can_select = true
        colors = []
        task_datas = []

        intervention.activity_productions.each do |activity_production|

          activity_color = activity_production.activity.color
          cultivable_zone = activity_production.cultivable_zone

          task_datas << { icon: "land-parcels", text: cultivable_zone.work_number, style: "background-color: #{activity_color};"}
        end


        if intervention.doers.count > 0

          doers_text = intervention.doers[0].product.name

          if intervention.doers.count > 1
            remaining_doers = intervention.doers.count - 1
            doers_text << " +" + remaining_doers.to_s
          end

          task_datas << { icon: "user", text: doers_text, class: "doers" }
        end


        intervention_datas = Hash.new
        intervention_datas[:id] = intervention.id
        intervention_datas[:name] = intervention.name

        tasks << block.task([{text: intervention.name}], task_datas, [], can_select, colors,
          params: {:class => "", :data => {:intervention => intervention_datas.to_json}})
      end

      tasks
    end

    def add_modal_data(title, detail, options)

      html = []

      icon = options[:icon] || nil
      image = options[:image] || nil

      content_tag(:div, nil, :class => "data") do

        html << content_tag(:div, nil, :class => "picture") do

          picture = content_tag(:i, nil, :class => "picto #{icon}") unless icon.nil?
          picture = image_tag(image, :class => "image") unless image.nil?

          picture
        end

        html << content_tag(:div, nil, :class => "details") do
          content_tag(:h4, title, :class => "data-title") +
          content_tag(:p, detail)
        end

        html.join.html_safe
      end
    end
  end
end
