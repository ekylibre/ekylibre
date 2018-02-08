class PlantDecorator < Draper::Decorator
  delegate_all

  def calibrations_natures
    object
      .inspections
      .flatten
      .map(&:calibrations)
      .flatten
      .map(&:nature)
      .flatten
  end

  def last_inspection_calibration_quantity(calibration_nature, dimension)
    calibration = last_inspection
                  .calibrations
                  .find_by(nature: calibration_nature)

    calibration.decorate.real_quantity(dimension).to_f * available_area.to_f
  end

  def human_last_inspection_calibration_quantity(calibration_nature, dimension, unit_name)
    last_inspection_calibration_quantity(calibration_nature, dimension)
      .to_f
      .round(2)
      .in(unit_name)
      .l(precision: 2)
  end

  def last_inspection_calibration_percentage(calibration_nature, dimension)
    quantity = last_inspection_calibration_quantity(calibration_nature, dimension)
    total_quantity = last_inspection
                     .calibrations
                     .flatten
                     .map { |calibration| calibration.decorate.real_quantity(dimension).to_f * available_area.to_f }
                     .sum

    return 0 if total_quantity == 0

    quantity.to_f / total_quantity.to_f * 100
  end

  def human_last_inspection_calibration_percentage(calibration_nature, dimension)
    last_inspection_calibration_percentage(calibration_nature, dimension)
      .round(1)
      .to_s
      .concat(' %')
  end

  def harvested_area
    unit_name ||= :hectare

    plant_population = object.initial_population

    sum_working_zone_area = object
                            .interventions
                            .where(procedure_name: :harvesting)
                            .map { |intervention| intervention.targets.with_working_zone }
                            .flatten
                            .map(&:working_zone_area)
                            .sum

    return plant_population if sum_working_zone_area.in(unit_name) > plant_population.in(unit_name)

    sum_working_zone_area
  end

  def human_harvested_area(unit_name: nil)
    unit_name ||= :hectare

    harvested_area
      .in(unit_name)
      .round(2)
      .l(precision: 2)
  end

  def available_area
    unit_name ||= :hectare

    object.initial_population.in(unit_name) - harvested_area.in(unit_name)
  end

  def human_available_area(unit_name: nil)
    unit_name ||= :hectare

    available_area
      .in(unit_name)
      .round(2)
      .l(precision: 2)
  end

  def net_volume_available(dimension, unit_name_per_hectare)
    marketable_yield = last_inspection.marketable_yield(dimension).in(unit_name_per_hectare).to_f

    marketable_yield * available_area.to_f
  end

  def human_net_volume_available(dimension, unit_name, unit_name_per_hectare)
    return nil if last_inspection.nil?
    unit_name ||= :items_count

    net_volume_available(dimension, unit_name_per_hectare)
      .in(unit_name)
      .round(2)
      .l(precision: 2)
  end

  def last_inspection_id
    return nil if last_inspection.nil?

    last_inspection.id
  end

  def last_inspection_number
    return nil if last_inspection.nil?

    last_inspection.number
  end

  def last_inspection_forecast_harvest_week
    return nil if last_inspection.nil?

    last_inspection.forecast_harvest_week
  end

  def last_inspection_comment
    return nil if last_inspection.nil?

    last_inspection.comment
  end

  def last_inspection_disease_percentage(dimension, unit_name)
    inspection_points_percentage(dimension, :disease, unit_name)
  end

  def last_inspection_deformity_percentage(dimension, unit_name)
    inspection_points_percentage(dimension, :deformity, unit_name)
  end

  def last_inspection
    object
      .inspections
      .order(sampled_at: :desc)
      .limit(1)
      .first
  end

  def items_count_quantity_unit
    last_inspection.user_quantity_unit(:items_count)
  end

  def items_count_per_area_unit
    last_inspection.user_per_area_unit(:items_count)
  end

  def net_mass_quantity_unit
    last_inspection.user_quantity_unit(:net_mass)
  end

  def net_mass_per_area_unit
    last_inspection.user_per_area_unit(:net_mass)
  end

  private

  def inspection_points_percentage(dimension, category, unit_name)
    return nil if last_inspection.nil?

    last_inspection
      .points_percentage(dimension, category)
      .in(unit_name)
      .round(2)
      .l(precision: 2)
      .split(' ')
      .insert(1, '%')
      .join(' ')
  end

  def dimension(user)
    last_inspection
      .activity
      .unit_preference(user)
  end
end
