module Backend
  module InterventionsHelper

    def add_tasks(interventions, block)

      tasks = []

      interventions.each do |intervention|
        can_select = true
        activities = intervention.activities

        cultivations = []
        intervention.targets_list.each do |target|
          cultivations << { icon: "land-parcels", text: target }
        end

        cultivations << { icon: "user", text: intervention.doers.count }

        colors = []
        activities.each do |activity|
          colors << activity.color
        end

        intervention_datas = Hash.new
        intervention_datas[:id] = intervention.id
        intervention_datas[:name] = intervention.name

        tasks << block.task([{text: intervention.name}], cultivations, [], can_select, colors,
          params: {:class => "task--not-updated", :data => {:intervention => intervention_datas.to_json}})
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
