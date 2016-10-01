module Backend
  module ActivitiesHelper
    def support_series(activity)
      activity
        .productions
        .of_campaign(current_campaign)
        .find_each
        .map do |support|
          next unless support.support_shape
          {
            name:         support.name,
            shape:        support.support_shape,
            shape_color:  support.activity.color,
            grain_yield:  support.grains_yield.to_s.to_f.round(2)
          }
        end
        .compact
    end

    def inspection_series(dimension, inspections)
      plant_ids = inspections.pluck(:product_id).uniq
      Plant.where(id: plant_ids).map do |plant|
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
          popup: {header: true, content: popup_content}
        }
      end
    end

    def caliber_series(dimension, scale, inspections)
      series_data = scale.natures.map do |nature|
        data = inspections
               .reject { |i| i.calibrations.of_scale(scale).empty? }
               .group_by(&:product_id)
               .map(&:last)
               .map(&:last)
               .map do |last_inspection|
                 l = last_inspection.calibrations.of_scale(scale).where(nature_id: nature.id)
                 [
                   Maybe(l.first).marketable_quantity(dimension).to_d(last_inspection.quantity_unit(:dimension)).or_nil,
                   Maybe(l.first).marketable_yield(dimension).to_d(last_inspection.quantity_unit(:dimension)).or_nil
                 ]
               end

        last_calibrations       = data.map(&:first)
        last_calibrations_yield = data.map(&:last)

        [
          { name: nature.name, data: [last_calibrations.compact.sum.to_s.to_f.round(2)] },
          { name: nature.name, data: [(last_calibrations_yield.compact.sum / last_calibrations_yield.compact.count).to_s.to_f.round(2)] }
        ]
      end

      {
        stock: series_data.map(&:first),
        yield: series_data.map(&:last)
      }
    end

    def spline_series(dimension, inspections)
      # category level
      ActivityInspectionPointNature.unmarketable_categories.map do |category|
        spline_data = spline_categories(inspections).map do |sample_time|
          values = inspections
                   .reorder(:sampled_at)
                   .where('sampled_at <= ?', sample_time)
                   .group_by(&:product_id)
                   .select { |plant, _| Plant.at(sample_time).pluck(:id).include? plant }
                   .values
                   .compact
                   .map do |insps_per_plant|
                       sum = insps_per_plant
                             .map do |insp|
                               insp.points_percentage(dimension, category)
                             end
                             .sum
                       sum / insps_per_plant.length
                   end

          [sample_time.l, (values.sum / values.count).to_f.round(3)]
        end

        { data: spline_data }
      end
    end

    def spline_categories(inspections)
      inspections.reorder(:sampled_at).pluck(:sampled_at).uniq
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
          dataset = last_i.calibrations.of_scale(scale).reorder(:id)
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