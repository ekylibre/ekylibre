module Backend
  module InspectionsHelper
    def data_series(dimension, method, dataset)
      dataset
        .map do |calibration|
          result = calibration.send(method, dimension)
          unit = calibration.user_per_area_unit(dimension) if %i[surface_area_density mass_area_density].include? result.dimension
          unit = calibration.user_quantity_unit(dimension) if %i[none mass].include? result.dimension

          result = result.to_d(unit).to_s.to_f.round(2)
          next if result.zero?
          if block_given?
            yield(calibration.name, result)
          else
            { name: calibration.name, data: [[calibration.name, result]] }
          end
        end
        .compact
    end

    def data_to_details_hash(inspection)
      details = {}

      # SCALES
      inspection.scales.order(:id).each do |scale|
        ### INIT
        columns = Hash.new { Hash.new [] }

        name = InspectionCalibration.human_attribute_name(:name)
        columns[name] = { body: [], total: [], colspan: 3 }

        quantity = {}
        %i[items_count net_mass].each do |dimension|
          next unless inspection.measure_grading(dimension)
          quantity[dimension] = InspectionCalibration.human_attribute_name(dimension)
          columns[quantity[dimension]] = { body: [], total: [], colspan: 1 }
        end

        grading_sizes = {}
        if inspection.measure_grading_sizes
          grading_sizes[:min] = InspectionCalibration.human_attribute_name(:minimal_size)
          grading_sizes[:max] = InspectionCalibration.human_attribute_name(:maximal_size)
          columns[grading_sizes[:min]] = { body: [], total: [], colspan: 1 }
          columns[grading_sizes[:max]] = { body: [], total: [], colspan: 1 }
        end

        statable = {}
        %i[items_count net_mass].each do |dimension|
          statable[dimension] = {}
          next unless inspection.quantity_statable?(dimension)
          statable[dimension][:total] = Inspection.human_attribute_name("gross_#{dimension}")
          statable[dimension][:yield] = { title: Inspection.human_attribute_name("gross_#{dimension}_yield"), unicity: dimension }
          statable[dimension][:market] = { title: InspectionCalibration.human_attribute_name("marketable_#{dimension}"), unicity: dimension }
          columns[statable[dimension][:total]] = { body: [], total: [], colspan: 1 }
          columns[statable[dimension][:yield]] = { body: [], total: [], colspan: 1 }
          columns[statable[dimension][:market]] = { body: [], total: [], colspan: 1 }
        end
        #########

        ### BODY
        inspection.calibrations.of_scale(scale).reorder(:id).each do |calibration|
          %i[items_count net_mass].each do |dimension|
            columns[quantity[dimension]][:body] << decimal_cell(calibration.quantity_in_unit(dimension).round(2).l(precision: 2))
            columns[statable[dimension][:total]][:body] << decimal_cell(calibration.projected_total(dimension).round(2).l(precision: 2))
            columns[statable[dimension][:yield]][:body] << decimal_cell(calibration.quantity_yield(dimension).round(2).l(precision: 2))
            columns[statable[dimension][:market]][:body] << decimal_cell(calibration.marketable? ? calibration.marketable_quantity(dimension).round(2).l(precision: 2) : nil)
          end

          columns[name][:body] << { tag: :td, content: calibration.nature_name }
          columns[grading_sizes[:min]][:body] << decimal_cell(calibration.extremum_size(:min).round(2).l(precision: 2))
          columns[grading_sizes[:max]][:body] << decimal_cell(calibration.extremum_size(:max).round(2).l(precision: 2))
        end
        #########

        ### TOTALS
        %i[items_count net_mass].each do |dimension|
          columns[quantity[dimension]][:total] << total_decimal_cell(inspection.quantity(dimension, scale).round(2).l(precision: 2))
          columns[statable[dimension][:total]][:total] << total_decimal_cell(inspection.projected_total(dimension, scale).round(2).l(precision: 2))
          columns[statable[dimension][:yield]][:total] << total_decimal_cell(inspection.quantity_yield(dimension).round(2).l(precision: 2))
          columns[statable[dimension][:market]][:total] << total_decimal_cell(inspection.marketable_quantity(dimension).round(2).l(precision: 2))
        end

        columns[name][:total] << { tag: :th, content: :totals.tl }
        columns[grading_sizes[:min]][:total] << total_decimal_cell(nil)
        columns[grading_sizes[:max]][:total] << total_decimal_cell(nil)
        #########

        details[scale.size_indicator.human_name] = columns
      end
      #########

      # POINTS
      if inspection.points.any?
        ### INIT
        columns = Hash.new { Hash.new { [] } }

        name = InspectionPoint.human_attribute_name(:name)
        columns[name] = { body: [], subtotal: [], total: [], colspan: 3 }

        quantity = {}
        %i[items_count net_mass].each do |dimension|
          next unless inspection.measure_grading(dimension)
          quantity[dimension] = InspectionPoint.human_attribute_name(dimension)
          columns[quantity[dimension]] = { body: [], subtotal: [], total: [], colspan: 1 }
        end

        grading_sizes = {}
        if inspection.measure_grading_sizes
          grading_sizes[:min] = InspectionPoint.human_attribute_name(:minimal_size)
          grading_sizes[:max] = InspectionPoint.human_attribute_name(:maximal_size)
          columns[grading_sizes[:min]] = { body: [], subtotal: [], total: [], colspan: 1 }
          columns[grading_sizes[:max]] = { body: [], subtotal: [], total: [], colspan: 1 }
        end

        statable = {}
        %i[items_count net_mass].each do |dimension|
          statable[dimension] = {}
          next unless inspection.quantity_statable?(dimension)
          statable[dimension][:total]   = Inspection.human_attribute_name("gross_#{dimension}")
          statable[dimension][:yield]   = { title: Inspection.human_attribute_name("gross_#{dimension}_yield"), unicity: dimension }
          statable[dimension][:market]  = { title: InspectionPoint.human_attribute_name("gross_#{dimension}_percentage"), unicity: dimension }
          columns[statable[dimension][:total]]  = { body: [], subtotal: [], total: [], colspan: 1 }
          columns[statable[dimension][:yield]]  = { body: [], subtotal: [], total: [], colspan: 1 }
          columns[statable[dimension][:market]] = { body: [], subtotal: [], total: [], colspan: 1 }
        end
        #########

        ### BODY
        inspection.points.joins(:nature).order('category, name').each do |point|
          %i[items_count net_mass].each do |dimension|
            columns[quantity[dimension]][:body] << decimal_cell(point.quantity_in_unit(dimension).round(2).l(precision: 2))
            columns[statable[dimension][:total]][:body] << decimal_cell(point.projected_total(dimension).round(2).l(precision: 2))
            columns[statable[dimension][:yield]][:body] << decimal_cell(point.quantity_yield(dimension).round(2).l(precision: 2))
            columns[statable[dimension][:market]][:body] << decimal_cell(point.percentage(dimension).round(2).l(precision: 2) + '%')
          end

          columns[name][:body] << { tag: :td, content: point.nature_name }
          columns[grading_sizes[:min]][:body] << decimal_cell(point.extremum_size(:min).round(2).l(precision: 2))
          columns[grading_sizes[:max]][:body] << decimal_cell(point.extremum_size(:max).round(2).l(precision: 2))
        end
        #########

        ### SUBTOTAL
        ActivityInspectionPointNature.unmarketable_categories.each do |category|
          %i[items_count net_mass].each do |dimension|
            columns[quantity[dimension]][:subtotal] << total_decimal_cell(inspection.points_sum(dimension, category).round(2).l(precision: 2))
            columns[statable[dimension][:total]][:subtotal] << total_decimal_cell(inspection.points_total(dimension, category).round(2).l(precision: 2))
            columns[statable[dimension][:yield]][:subtotal] << total_decimal_cell(inspection.points_yield(dimension, category).round(2).l(precision: 2))
            columns[statable[dimension][:market]][:subtotal] << total_decimal_cell(inspection.points_percentage(dimension, category).round(2).l(precision: 2) + '%')
          end

          columns[name][:subtotal] << { tag: :th, content: "enumerize.activity_inspection_point_nature.category.#{category}".t }
          columns[grading_sizes[:min]][:subtotal] << total_decimal_cell(nil)
          columns[grading_sizes[:max]][:subtotal] << total_decimal_cell(nil)
        end
        #########

        ### TOTAL
        %i[items_count net_mass].each do |dimension|
          columns[quantity[dimension]][:total] << total_decimal_cell(inspection.points_sum(dimension).round(2).l(precision: 2))
          columns[statable[dimension][:total]][:total] << total_decimal_cell(inspection.points_total(dimension).round(2).l(precision: 2))
          columns[statable[dimension][:yield]][:total] << total_decimal_cell(inspection.points_yield(dimension).round(2).l(precision: 2))
          columns[statable[dimension][:market]][:total] << total_decimal_cell(inspection.points_percentage(dimension).round(2).l(precision: 2) + '%')
        end

        columns[name][:total] << { tag: :th, content: :totals.tl }
        columns[grading_sizes[:min]][:total] << total_decimal_cell(nil)
        columns[grading_sizes[:max]][:total] << total_decimal_cell(nil)
        #########

        details[Inspection.human_attribute_name(:points)] = columns
      end

      details
    end

    def hash_to_inspection_details(hash)
      content_tag :table do
        html = []
        html << content_tag(:thead, nil)
        hash.each do |title, table|
          html << content_tag(:tr, class: :title) do
            title_colspan = table.map { |_title, contents| contents[:colspan] }.sum
            content_tag :th, title.is_a?(Hash) ? title[:title] : title, colspan: title_colspan
          end

          html << content_tag(:tr) do
            cols = table.keys.map do |subtitle|
              content_tag :th, subtitle.is_a?(Hash) ? subtitle[:title] : subtitle
            end
            safe_join(cols)
          end

          %i[body subtotal total].each do |part|
            html += table.values.map { |content| content[part] }.compact.transpose.map do |row|
              content_tag :tr, class: part do
                cols = row.map do |col|
                  content_tag col[:tag], col[:content] || '&ndash;'.html_safe, class: col[:class]
                end
                safe_join(cols)
              end
            end
          end
        end
        safe_join(html)
      end
    end

    private

    def decimal_cell(value)
      { tag: :td, class: :decimal, content: value }
    end

    def total_decimal_cell(value)
      { tag: :th, class: :decimal, content: value }
    end
  end
end
