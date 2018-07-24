class ActivityDecorator < Draper::Decorator
  delegate_all

  def animal_family?
    object.family == :animal_farming
  end

  def production_costs(current_campaign)
    calcul_productions_costs(current_campaign)
  end

  def sum_interventions_working_zone_area
    InterventionTarget
      .of_interventions(object.interventions)
      .map(&:working_zone_area)
      .sum
      .in(:hectare)
      .round(2)
      .to_d
  end

  def working_zone_area(current_campaign)
    activity_productions = decorated_activity_productions(current_campaign)
    working_zone = 0.in(:hectare)

    activity_productions.each do |activity_production|
      working_zone += activity_production.working_zone_area
    end

    working_zone
  end

  def human_working_zone_area(current_campaign)
    working_zone_area(current_campaign)
      .in(:hectare)
      .round(3)
      .l
  end

  def net_surface_area(current_campaign)
    activity_productions = decorated_activity_productions(current_campaign)
    surface_area = 0.in(:hectare)

    activity_productions.each do |activity_production|
      surface_area += activity_production.net_surface_area
    end

    surface_area
  end

  def human_net_surface_area(current_campaign)
    net_surface_area(current_campaign)
      .in(:hectare)
      .round(3)
      .l
  end

  private

  def sum_costs(activity_costs, costs)
    activity_costs.each { |key, _value| activity_costs[key] = activity_costs[key] + costs[key] }
  end

  def multiply_costs(costs, multiplier)
    costs.each { |key, value| costs[key] = value * multiplier }
  end

  def divider_costs(costs, divider)
    costs.each { |key, value| costs[key] = value / divider unless value.zero? }
  end

  def human_costs(costs)
    costs.each { |key, _value| costs[key] = costs[key].to_i }
  end

  def decorated_activity_productions(current_campaign)
    activity_productions = object
                           .productions
                           .of_campaign(current_campaign)

    ActivityProductionDecorator.decorate_collection(activity_productions)
  end

  def calcul_productions_costs(current_campaign)
    costs = new_productions_costs_hash
    activity_productions = decorated_activity_productions(current_campaign)
    sum_surface_area = 0.in(:hectare)
    sum_parameters_cultivated_hectare = { total: 0, inputs: 0, doers: 0, tools: 0, receptions: 0 }

    activity_productions.each do |activity_production|
      activity_production_costs = activity_production.global_costs

      sum_costs(costs[:global_costs], activity_production_costs)
      human_costs(costs[:global_costs])

      sum_surface_area += activity_production.net_surface_area
      sum_costs(costs[:cultivated_hectare_costs], activity_production_costs)
    end

    divider_costs(costs[:cultivated_hectare_costs], calculated_surface_area(sum_surface_area))
    human_costs(costs[:cultivated_hectare_costs])

    sum_costs(costs[:working_hectare_costs], costs[:global_costs])
    divider_costs(costs[:working_hectare_costs], working_zone_area(current_campaign).to_d)
    human_costs(costs[:working_hectare_costs])

    costs
  end

  def sum_activities_productions_surface_area
    object
      .productions
      .map(&:net_surface_area)
      .sum
  end

  def new_productions_costs_hash
    {
      global_costs: {
        total: 0,
        inputs: 0,
        doers: 0,
        tools: 0,
        receptions: 0
      },
      cultivated_hectare_costs: {
        total: 0,
        inputs: 0,
        doers: 0,
        tools: 0,
        receptions: 0
      },
      working_hectare_costs: {
        total: 0,
        inputs: 0,
        doers: 0,
        tools: 0,
        receptions: 0
      }
    }
  end

  def calculated_surface_area(surface_area)
    surface_area
      .in(:hectare)
      .round(2)
      .to_d
  end
end
