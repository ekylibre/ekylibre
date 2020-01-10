class PlantDecorator < ProductDecorator
  delegate_all

  ####################################
  #                                  #
  #         PRODUCTION COSTS         #
  #                                  #
  ####################################

  def production_costs
    {
      global_costs: human_global_costs,
      cultivated_hectare_costs: human_cultivated_hectare_costs,
      working_hectare_costs: human_working_hectare_costs
    }
  end

  def global_costs
    calcul_global_costs
  end

  def human_global_costs
    human_costs(global_costs)
  end

  def cultivated_hectare_costs
    costs = global_costs
    divider_costs(costs, object.net_surface_area.to_d)
    total_costs(costs)

    costs
  end

  def human_cultivated_hectare_costs
    human_costs(cultivated_hectare_costs)
  end

  def working_hectare_costs
    costs = calcul_global_costs(with_working_zone_area: true)
    total_costs(costs)

    costs
  end

  def human_working_hectare_costs
    human_costs(working_hectare_costs)
  end

  ####################################
  #                                  #
  #           INSPECTIONS            #
  #                                  #
  ####################################

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

  def working_zone_area
    interventions = decorated_interventions
    working_zone = 0.in(:hectare)

    interventions.map do |intervention|
      intervention_working_zone = intervention_working_zone_area(intervention)
      working_zone += intervention_working_zone.in(:hectare)
    end

    working_zone
  end

  def human_working_zone_area
    working_zone_area
      .in(:hectare)
      .round(3)
      .l
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

  def calcul_global_costs(with_working_zone_area: false)
    costs = { inputs: 0, doers: 0, tools: 0, receptions: 0 }
    interventions = decorated_interventions
    working_zone_area = 0.in(:hectare)

    interventions.map do |intervention|
      global_costs = intervention.global_costs

      calcul_with_surface_area(intervention, global_costs) if intervention.many_targets?
      working_zone_area += intervention_working_zone_area(intervention).in(:hectare).round(2) if with_working_zone_area

      sum_costs(costs, global_costs)
    end

    calcul_with_working_zone_area(costs, working_zone_area) if with_working_zone_area
    total_costs(costs)
    costs
  end

  def decorated_interventions
    InterventionDecorator.decorate_collection(object.interventions)
  end

  def sum_costs(plant_costs, costs)
    plant_costs.each { |key, _value| plant_costs[key] = plant_costs[key] + costs[key] }
  end

  def human_costs(costs)
    costs.each { |key, _value| costs[key] = costs[key].to_i }
  end

  def multiply_costs(costs, multiplier)
    costs.each { |key, value| costs[key] = value * multiplier }
  end

  def divider_costs(costs, divider)
    costs.each { |key, value| costs[key] = value / divider }
  end

  def total_costs(costs)
    costs = costs.except!(:total) if costs.key?(:total)

    costs[:total] = costs.values.sum
  end

  def calcul_with_surface_area(intervention, costs)
    product = nil
    product = intervention.outputs.of_actor(object).first.product if intervention.procedure.of_category?(:planting)
    product = intervention.targets.of_actor(object).first.product unless intervention.procedure.of_category?(:planting)

    sum_surface_area = product.net_surface_area.to_d / intervention.sum_targets_working_zone_area.to_d

    multiply_costs(costs, sum_surface_area)
  end

  def intervention_working_zone_area(intervention)
    return intervention.working_zone_area unless intervention.many_targets?

    product = nil
    product = intervention.outputs.of_actor(object).first.product if intervention.procedure.of_category?(:planting)
    product = intervention.targets.of_actor(object).first.product unless intervention.procedure.of_category?(:planting)

    return intervention.sum_products_working_zone_area(product) unless intervention.planting?
    intervention.sum_outputs_working_zone_area_of_product(product) if intervention.planting?
  end

  def calcul_with_working_zone_area(costs, working_zone_area)
    working_zone_area = working_zone_area
                        .in(:hectare)
                        .round(2)
                        .to_f

    divider_costs(costs, working_zone_area)
  end
end
