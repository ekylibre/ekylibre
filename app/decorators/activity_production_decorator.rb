class ActivityProductionDecorator < Draper::Decorator
  delegate_all

  def production_costs
    production_global_costs = global_costs

    {
      global_costs: human_costs(production_global_costs),
      cultivated_hectare_costs: human_cultivated_hectare_costs(production_global_costs.clone),
      working_hectare_costs: human_working_hectare_costs
    }
  end

  def global_costs
    calcul_global_costs
  end

  def human_global_costs
    human_costs(global_costs)
  end

  def cultivated_hectare_costs(costs)
    divider_costs(costs, object.net_surface_area.in(:hectare).round(2).to_d)
    total_costs(costs)

    costs
  end

  def human_cultivated_hectare_costs(costs)
    human_costs(cultivated_hectare_costs(costs))
  end

  def working_hectare_costs
    costs = calcul_global_costs(with_working_zone_area: true)
    total_costs(costs)

    costs
  end

  def human_working_hectare_costs
    human_costs(working_hectare_costs)
  end

  def working_zone_area
    interventions = decorated_interventions
    working_zone = 0.in(:hectare)

    interventions.each do |intervention|
      working_zone += intervention_working_zone_area(intervention)
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


  def calcul_global_costs(with_working_zone_area: false)
    interventions = decorated_interventions
    costs = new_costs_hash
    working_zone_area = 0.in(:hectare)

    interventions.each do |intervention|
      global_costs = intervention.global_costs

      calcul_with_surface_area(intervention, global_costs) if intervention.many_targets?
      sum_costs(costs, intervention.global_costs)

      working_zone_area += intervention_working_zone_area(intervention) if with_working_zone_area
    end

    calcul_with_working_zone_area(costs, working_zone_area) if with_working_zone_area
    total_costs(costs)
    costs
  end

  def total_costs(costs)
    costs = costs.except!(:total) if costs.key?(:total)

    costs[:total] = costs.values.sum
  end

  def multiply_costs(costs, multiplier)
    costs.each { |key, value| costs[key] = value * multiplier }
  end

  def divider_costs(costs, divider)
    costs.each { |key, value| costs[key] = value / divider }
  end

  def sum_costs(plant_costs, costs)
    plant_costs.each { |key, value| plant_costs[key] = plant_costs[key] + costs[key] }
  end

  def human_costs(costs)
    costs.each { |key, value| costs[key] = costs[key].to_f.round(2) }
  end

  def new_costs_hash
    { total: 0, inputs: 0, doers: 0, tools: 0, receptions: 0 }
  end

  def decorated_interventions
    production_interventions = object
                                 .interventions_of_nature('record')

    InterventionDecorator.decorate_collection(production_interventions)
  end

  def calcul_with_surface_area(intervention, costs)
    products = intervention
                 .targets
                 .of_activity_production(object)
                 .map(&:product)

    products.each do |product|
      sum_surface_area = product.net_surface_area.to_d / intervention.sum_targets_net_surface_area.to_d

      multiply_costs(costs, sum_surface_area)
    end
  end

  def intervention_working_zone_area(intervention)
    return intervention.working_zone_area unless intervention.many_targets?

    intervention.sum_activity_production_working_zone_area(object)
  end

  def calcul_with_working_zone_area(costs, working_zone_area)
    working_zone_area = working_zone_area
                          .in(:hectare)
                          .round(2)
                          .to_f

    divider_costs(costs, working_zone_area)
  end
end
