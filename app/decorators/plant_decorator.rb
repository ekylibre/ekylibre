class PlantDecorator < Draper::Decorator
  delegate_all

  def harvested_area
    unit_name ||= :hectare

    plant_population = object.initial_population

    sum_working_zone_area = object
                              .interventions
                              .where(procedure_name: :harvesting)
                              .map{ |intervention| intervention.targets.with_working_zone }
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

  def net_volume_available(dimension, unit_name)
    return nil if last_inspection.nil?

    unit_name ||= :items_count
    net_volume = available_area.to_d * last_inspection.marketable_yield(dimension).to_d

    net_volume.in(unit_name)
  end

  def human_net_volume_available(dimension, unit_name)
    return nil if last_inspection.nil?
    unit_name ||= :items_count

    net_volume_available(dimension, unit_name)
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

  def last_inspection_disease_percentage(user, unit_name)
    inspection_points_percentage(user, :disease, unit_name)
  end

  def last_inspection_deformity_percentage(user, unit_name)
    inspection_points_percentage(user, :deformity, unit_name)
  end

  def last_inspection
    object
      .inspections
      .order(sampled_at: :desc)
      .limit(1)
      .first
  end

  def items_count_unit
    last_inspection.user_quantity_unit(:items_count)
  end

  def net_mass_unit
    last_inspection.user_quantity_unit(:net_mass)
  end

  private

  def inspection_points_percentage(user, category, unit_name)
    return nil if last_inspection.nil?

    last_inspection
      .points_percentage(dimension(user), category)
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
