class ActivityProductionDecorator < Draper::Decorator
  delegate_all

  def production_costs
    global_costs = calcul_global_costs

    {
      global_costs: human_costs(global_costs),
      cultivated_hectare_costs: human_cultivated_hectare_costs(global_costs.clone),
      working_hectare_costs: human_working_hectare_costs(global_costs.clone)
    }
  end

  def human_global_costs
    human_costs(calcul_global_costs)
  end

  def cultivated_hectare_costs(global_costs)
    calcul_costs(global_costs, nil, object.support_shape_area)
  end

  def human_cultivated_hectare_costs(global_costs)
    human_costs(cultivated_hectare_costs(global_costs))
  end

  def working_hectare_costs(global_costs)
    calcul_costs(global_costs, nil, sum_interventions_working_zone_area)
  end

  def human_working_hectare_costs(global_costs)
    human_costs(working_hectare_costs(global_costs))
  end

  private

  def calcul_global_costs
    interventions = decorated_interventions
    costs = new_costs_hash

    interventions.each do |intervention|
      targets = intervention.targets
      intervention_products = targets.map(&:product).uniq
      products = PlantDecorator.decorate_collection(intervention_products)

      if products.count == 1
        sum_costs(costs, products.first.global_costs)
      else
        sum_many_products(costs, products, intervention)
      end
    end

    costs
  end

  def same_production?(product)
    object.id == product.activity_production.id
  end

  def human_costs(costs)
    costs.each do |key, value|
      costs[key] = costs[key].to_f.round(2)
    end
  end

  def sum_costs(costs, product_costs, multiplier = nil)
    costs.each do |key, value|
      cost_value = costs[key].to_d
      product_cost_value = product_costs[key].to_d

      costs[key] = cost_value + product_cost_value
    end
  end

  def calcul_costs(costs, multiplier = nil, divider = nil)
    costs.each do |key, value|
      cost_value = costs[key].to_d

      costs[key] = cost_value * multiplier.to_f unless multiplier.nil?
      costs[key] = cost_value / divider.to_f unless divider.nil?
    end
  end

  def sum_many_products(costs, products, intervention)
    intervention_costs = new_costs_hash
    sum_net_surface_area = 0.0

    products.each do |product|
      sum_net_surface_area += product.net_surface_area.to_d if same_production?(product)
      sum_costs(intervention_costs, product.global_costs)
    end

    multiplier = sum_net_surface_area / intervention.sum_targets_net_surface_area

    calcul_costs(intervention_costs, multiplier)
    sum_costs(costs, intervention_costs)
  end

  def sum_interventions_working_zone_area
    interventions = decorated_interventions

    working_zone_area = interventions.map do |intervention|
                          intervention.working_zone_area unless intervention.many_targets?

                          intervention.sum_activity_production_working_zone_area(object) if intervention.many_targets?
                        end

    working_zone_area
      .compact
      .sum
      .in(:hectare)
      .round(2)
      .to_f
  end

  def new_costs_hash
    { total: 0, inputs: 0, doers: 0, tools: 0, receptions: 0 }
  end

  def decorated_interventions
    production_interventions = object
                      .interventions_of_nature('record')

    InterventionDecorator.decorate_collection(production_interventions)
  end
end
