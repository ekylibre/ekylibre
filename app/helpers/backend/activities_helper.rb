module Backend
  module ActivitiesHelper
    def support_series(activity)
      activity
        .productions
        .of_campaign(current_campaign)
        .includes(:cultivable_zone)
        .find_each
        .map do |production|
          next unless production.support_shape
          {
            name:         production.name,
            shape:        production.support_shape,
            shape_color:  activity.color,
            grain_yield:  production.grains_yield.to_s.to_f.round(2)
          }
        end
        .compact
    end

    def inspection_series(dimension, inspections)
      Plant.where(id: inspections.select(:product_id)).includes(:nature).map do |plant|
        next unless plant.shape

        in_qual               = inspection_quality(dimension, plant)
        quality_evolutions    = in_qual.map { |_cat, data| data[:evolution] }
        disease_percentage    = Maybe(in_qual)[:disease][:percentage].or_nil
        deformity_percentage  = Maybe(in_qual)[:deformity][:percentage].or_nil

        popup_content = []
        popup_content << { label: Plant.human_attribute_name(:net_surface_area), value: plant.net_surface_area.round(3).l }
        popup_content << render('popup', plant: plant, calibrations: popup_calibrations(dimension, plant), inspection_qualities_evolutions: quality_evolutions)

        {
          name:       plant.name,
          shape:      plant.shape,
          disease_percentage: disease_percentage,
          deformity_percentage: deformity_percentage,
          ready_to_harvest: (plant.ready_to_harvest? ? :ready.tl : :not_ready.tl),
          popup: { header: true, content: popup_content }
        }
      end
    end

    def caliber_series(dimension, scale, inspections)
      grouped = inspections
                .joins(:calibrations)
                .merge(InspectionCalibration.of_scale(scale))
                .joins(:product)
                .where('products.dead_at IS NULL OR products.dead_at > ?', Time.zone.now)
                .group(:product_id, :id)
                .reorder('')
                .to_a
                .reject { |inspection| inspection.product.decorate.available_area.to_f == 0 }

      last_inspections = inspections
                         .where(product_id: grouped.map(&:product_id),
                                sampled_at: grouped.map(&:sampled_at).max)

      series_data = scale.natures.map do |nature|
        last_calibrations = InspectionCalibration.where(id:
                             InspectionCalibration.of_scale(scale)
                                                  .where(inspection_id: last_inspections,
                                                         nature_id: nature.id)
                                                  .group(:inspection_id)
                                                  .reorder('')
                                                  .select('MIN(inspection_calibrations.id)'))

        data = last_calibrations.includes(:inspection).map do |last_calibration|
          inspection = last_calibration.inspection
          [
            last_calibration.decorate.net_stock(dimension),
            last_calibration.marketable_yield(dimension).to_d(inspection.user_per_area_unit(dimension))
          ]
        end

        last_quantities = data.map(&:first).compact
        last_yields     = data.map(&:last).compact

        yield_value = last_yields.blank? ? 0 : (last_yields.sum / last_yields.count)

        [
          { name: nature.name,
            data: [[nature.name,
                    last_quantities.sum.to_s.to_f.round(2)]] },
          { name: nature.name,
            data: [[nature.name,
                    yield_value.to_s.to_f.round(2)]] }
        ]
      end

      {
        stock: series_data.map(&:first),
        yield: series_data.map(&:last)
      }
    end

    def spline_series(dimension, inspections)
      spline_cat = spline_categories(inspections)
      ActivityInspectionPointNature.unmarketable_categories.map do |category|
        spline_data = spline_cat.map do |sample_time|
          values = inspections
                   .reorder(:sampled_at)
                   .where('sampled_at <= ?', sample_time)
                   .group_by(&:product_id)
                   .select { |plant, _| Plant.at(sample_time).where('dead_at > ? OR dead_at IS NULL', sample_time).pluck(:id).include? plant }
                   .values
                   .compact
                   .map do |insps_per_plant|
                     insps_per_plant
                       .map do |insp|
                         insp.points_percentage(dimension, category)
                       end
                       .last
                   end

          [sample_time.l, (values.blank? ? 0 : (values.sum / values.count)).to_f.round(2)]
        end

        { name: category.tl, data: spline_data }
      end
    end

    def spline_categories(inspections)
      inspections
        .pluck(:sampled_at)
        .concat(inspections.joins(:product).pluck(:'products.dead_at'))
        .compact
        .uniq
        .sort
    end

    def chart_style(title, symbol)
      bar_chart_options = {
        x_axis: { categories: [''] },
        y_axis: {
          reversed_stacks: false,
          stack_labels: { enabled: true }
        },
        legend: true,
        plot_options: {
          column: { stacking: 'normal', data_labels: { enabled: true } }
        }
      }

      bar_chart_options.deep_merge(
        title: { text: title },
        y_axis: {
          title: { text: symbol.to_s },
          tooltip: { point_format: "{point.y: 1f} #{symbol}" }
        }
      )
    end

    private

    def inspection_quality(dimension, plant)
      inspections   = plant.inspections.reorder(sampled_at: :desc).limit(2)
      last_i        = inspections.first
      before_last_i = inspections.second
      unit          = last_i.quantity_unit(dimension)
      ActivityInspectionPointNature
        .unmarketable_categories
        .map do |category|
          data = category_percentage_and_evolution(dimension, category, last_i, before_last_i)
          next unless data
          next [category, data] unless data[:evolution]
          data[:evolution] = {
            label: "#{category}_percentage_evolution".tl,
            value: data[:evolution].round(0)
                                   .in(unit)
                                   .l
          }
          [category, data]
        end
        .compact
        .to_h
    end

    def category_percentage_and_evolution(dimension, category, old_i, new_i)
      return unless new_i && old_i
      new_percentage = new_i.points_percentage(dimension, category)
      old_percentage = old_i.points_percentage(dimension, category)
      evolution = (new_percentage - old_percentage) if old_percentage.to_d.nonzero?
      {
        percentage: new_percentage,
        evolution: evolution
      }
    end

    def popup_calibrations(dimension, plant, round = 2)
      last_i  = plant.inspections.reorder(:sampled_at).last
      unit    = last_i.quantity_unit(dimension)

      last_i
        .scales
        .map do |scale|
          dataset = last_i.calibrations.includes(nature: :scale).of_scale(scale).reorder(:id)
          dataset.map do |calibration|
            {
              label: calibration.name,
              value: Maybe(calibration.marketable_quantity(dimension))
                .or_else(0)
                .convert(unit)
                .round(round)
                .l(precision: 0)
            }
          end
        end
        .flatten
    end
  end
end
