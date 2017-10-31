module Backend
  module PlantsHelper
    def plants_map(options = {})
      html_options ||= {}
      html_options[:class] = 'map-fullwidth' if options.delete(:main)

      visualization({ box: { height: '100%' }, async_url: backend_visualizations_plants_visualizations_path }, html_options) do |v|
        v.control :zoom
        v.control :scale
        v.control :fullscreen
        v.control :layer_selector
        if Plant.last.shape_centroid.present?
          v.center Plant.first.shape_centroid
        end
      end
    end

    def plant_period_crit(*args)
      arg_value = args.shift
      name = arg_value[:name] || :period
      label_name = arg_value[:label]
      options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})

      # list of all options
      list = []
      list << ['', 'all']

      # Add year and month period
      first_date = Plant.order(name).first[name] || Time.now - 2.years
      period = (first_date.year..Time.now.year).map { |p| p }

      period.reverse_each do |year|
        full_year = Time.new(year)
        list << [year, "#{full_year.to_date}_#{full_year.end_of_year.to_date}"]
        date = period.index(year) == 0 ? first_date.beginning_of_month : full_year
        list2 = []
        while date < full_year.end_of_year && date < Time.zone.today
          list2 << [l(date.to_date, format: :month), "#{date.to_date}_#{date.end_of_month.to_date}"]
          date += 1.month
        end
        list += list2.reverse
      end
      configuration = if params[name].present? && params[name] != 'all' && params[name] == 'interval'
                        { custom: :interval }.merge(options)
                      else
                        {}
                      end
      configuration[:id] ||= name.to_s.gsub(/\W+/, '_').gsub(/(^_|_$)/, '')
      value ||= params[name] || options[:default]

      code = ''
      code << content_tag(:label, label_name || :period.tl, for: configuration[:id]) + ' '
      fy = FinancialYear.current
      params[name] = value ||= :all
      # params[:period] = value ||= :all # (fy ? fy.started_on.to_s + "_" + fy.stopped_on.to_s : :all)
      custom_id = "#{configuration[:id]}_#{configuration[:custom]}"
      toggle_method = "toggle#{custom_id.camelcase}"
      if configuration[:custom]
        params["#{name}_started_on"] = begin
                                params["#{name}_started_on"].to_date
                              rescue
                                (fy ? fy.started_on : Time.zone.today)
                              end
        params["#{name}_stoped_on"] = begin
                                params["#{name}_stopped_on"].to_date
                              rescue
                                (fy ? fy.stopped_on : Time.zone.today)
                              end
        params["#{name}_stoped_on"] = params["#{name}_started_on"] if params["#{name}_started_on"] > params["#{name}_stoped_on"]
        list.insert(0, [configuration[:custom].tl, configuration[:custom]])
      else
        params["#{name}_started_on"] = fy ? fy.started_on : Time.zone.today
        params["#{name}_stoped_on"] = fy ? fy.stopped_on : Time.zone.today
        list.insert(1, [:interval.tl, :interval])
      end
      if replacement = options.delete(:include_blank)
        list.insert(0, [(replacement.is_a?(Symbol) ? tl(replacement) : replacement.to_s), ''])
      end

      code << select_tag(name, options_for_select(list, value), :id => custom_id, 'data-show-value' => "##{configuration[:id]}_")

      # if configuration[:custom]
      code << ' ' << content_tag(:span, :manual_period.tl(start: date_field_tag("#{name}_started_on".to_sym, params["#{name}_started_on"], size: 10), finish: date_field_tag("#{name}_stopped_on".to_sym, params["#{name}_stoped_on"], size: 10)).html_safe, id: "#{configuration[:id]}_interval")
      # end

      code.html_safe
    end

    def plants_max_area
      # FIXME: SRID can't be set in hard way like that. Use preference map_measure_srs
      Plant.maximum('ST_Area(ST_Transform(ST_GeomFromEWKB(initial_shape), 2154))').to_f.in_square_meter
    end

    def area_range_slider_value(maximum, minimum = 0)
      params[:area].present? ? params[:area].split(',').map(&:to_i) : [minimum, maximum]
    end
  end
end
