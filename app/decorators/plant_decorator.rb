class PlantDecorator < Draper::Decorator
  delegate_all


  ####################################
  #                                  #
  #         PRODUCTION COSTS         #
  #                                  #
  ####################################

  def production_costs
    {
      global_costs: {
        total: human_total_global_costs,
        inputs: human_interventions_inputs_global_cost,
        doers: human_interventions_doers_global_cost,
        tools: human_interventions_tools_global_cost,
        receptions: human_interventions_receptions_global_cost
      },
      cultivated_hectare_costs: {
        total: human_total_cultivated_hectare_costs,
        inputs: human_interventions_inputs_cultivated_hectare_cost,
        doers: human_interventions_doers_cultivated_hectare_cost,
        tools: human_interventions_tools_cultivated_hectare_cost,
        receptions: human_interventions_receptions_cultivated_hectare_cost
      },
      working_hectare_costs: {
        total: human_total_working_hectare_costs,
        inputs: human_interventions_inputs_working_hectare_cost,
        doers: human_interventions_doers_working_hectare_cost,
        tools: human_interventions_tools_working_hectare_cost,
        receptions: human_interventions_receptions_working_hectare_cost
      }
    }
  end

  def global_costs
    {
      total: total_global_costs,
      inputs: interventions_inputs_global_cost,
      doers: interventions_doers_global_cost,
      tools: interventions_tools_global_cost,
      receptions: interventions_receptions_global_cost
    }
  end

  def total_global_costs
    total_costs(:global)
  end

  def human_total_global_costs
    human_total_costs(:global)
  end

  def total_cultivated_hectare_costs
    total_costs(:cultivated_hectare)
  end

  def human_total_cultivated_hectare_costs
    human_total_costs(:cultivated_hectare)
  end

  def total_working_hectare_costs
    total_costs(:working_hectare)
  end

  def human_total_working_hectare_costs
    human_total_costs(:working_hectare)
  end



  def interventions_inputs_global_cost
    intervention_parameters_global_cost(:inputs_cost)
  end

  def human_interventions_inputs_global_cost
    human_intervention_parameters_global_cost(:inputs_cost)
  end

  def interventions_inputs_cultivated_hectare_cost
    intervention_parameters_cultivated_hectare_cost(:inputs_cost)
  end

  def human_interventions_inputs_cultivated_hectare_cost
    human_intervention_parameters_cultivated_hectare_cost(:inputs_cost)
  end

  def interventions_inputs_working_hectare_cost
    intervention_parameters_working_hectare_cost(:inputs_cost)
  end

  def human_interventions_inputs_working_hectare_cost
    human_intervention_parameters_working_hectare_cost(:inputs_cost)
  end



  def interventions_doers_global_cost
    intervention_parameters_global_cost(:doers_cost)
  end

  def human_interventions_doers_global_cost
    human_intervention_parameters_global_cost(:doers_cost)
  end

  def interventions_doers_cultivated_hectare_cost
    intervention_parameters_cultivated_hectare_cost(:doers_cost)
  end

  def human_interventions_doers_cultivated_hectare_cost
    human_intervention_parameters_cultivated_hectare_cost(:doers_cost)
  end

  def interventions_doers_working_hectare_cost
    intervention_parameters_working_hectare_cost(:doers_cost)
  end

  def human_interventions_doers_working_hectare_cost
    human_intervention_parameters_working_hectare_cost(:doers_cost)
  end



  def interventions_tools_global_cost
    intervention_parameters_global_cost(:tools_cost)
  end

  def human_interventions_tools_global_cost
    human_intervention_parameters_global_cost(:tools_cost)
  end

  def interventions_tools_cultivated_hectare_cost
    intervention_parameters_cultivated_hectare_cost(:tools_cost)
  end

  def human_interventions_tools_cultivated_hectare_cost
    human_intervention_parameters_cultivated_hectare_cost(:tools_cost)
  end

  def interventions_tools_working_hectare_cost
    intervention_parameters_working_hectare_cost(:tools_cost)
  end

  def human_interventions_tools_working_hectare_cost
    human_intervention_parameters_working_hectare_cost(:tools_cost)
  end



  def interventions_receptions_global_cost
    intervention_parameters_global_cost(:receptions_cost)
  end

  def human_interventions_receptions_global_cost
    human_intervention_parameters_global_cost(:receptions_cost)
  end

  def interventions_receptions_cultivated_hectare_cost
    intervention_parameters_cultivated_hectare_cost(:receptions_cost)
  end

  def human_interventions_receptions_cultivated_hectare_cost
    human_intervention_parameters_cultivated_hectare_cost(:receptions_cost)
  end

  def interventions_receptions_working_hectare_cost
    intervention_parameters_working_hectare_cost(:receptions_cost)
  end

  def human_interventions_receptions_working_hectare_cost
    human_intervention_parameters_working_hectare_cost(:receptions_cost)
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

  def intervention_parameters_global_cost(method)
    interventions = decorated_interventions

    cost = interventions.map do |intervention|
             cost = intervention.send(method)

             if intervention.many_targets?
               sum_surface_area = object.net_surface_area.to_d / intervention.sum_targets_net_surface_area.to_d
               cost *= sum_surface_area
             end

             cost
           end

    cost
      .compact
      .sum
  end

  def human_intervention_parameters_global_cost(method)
    intervention_parameters_global_cost(method)
      .to_f
      .round(2)
  end

  def intervention_parameters_cultivated_hectare_cost(method)
    intervention_parameters_global_cost(method) / object.net_surface_area.to_d
  end

  def human_intervention_parameters_cultivated_hectare_cost(method)
    intervention_parameters_cultivated_hectare_cost(method)
      .to_f
      .round(2)
  end

  def intervention_parameters_working_hectare_cost(method)
    intervention_parameters_global_cost(method) / sum_interventions_working_zone_area.to_d
  end

  def human_intervention_parameters_working_hectare_cost(method)
    intervention_parameters_working_hectare_cost(method)
      .to_f
      .round(2)
  end

  def sum_interventions_working_zone_area
    interventions = decorated_interventions

    working_zone_area = interventions.map do |intervention|
                          intervention.working_zone_area unless intervention.many_targets?
                          intervention.targets.of_actor(object).first.working_zone_area if intervention.many_targets?
                        end

    working_zone_area
      .compact
      .sum
      .in(:hectare)
      .round(2)
      .to_f
  end

  def decorated_interventions
    InterventionDecorator.decorate_collection(object.interventions)
  end

  def total_costs(cost_type)
    return self.send("interventions_inputs_#{ cost_type }_cost") +
             self.send("interventions_doers_#{ cost_type }_cost") +
             self.send("interventions_tools_#{ cost_type }_cost") +
             self.send("interventions_receptions_#{ cost_type }_cost")
  end

  def human_total_costs(cost_type)
    total_costs(cost_type)
      .to_f
      .round(2)
  end
end
