class ActivityDecorator < Draper::Decorator
  delegate_all

  def production_costs
    {
      global_costs: human_global_costs,
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

  def global_costs
    calcul_global_costs
  end

  def human_global_costs
    human_costs(global_costs)
  end


  private

  def sum_costs(activity_costs, costs)
    activity_costs.each { |key, value| activity_costs[key] = activity_costs[key] + costs[key] }
  end

  def human_costs(costs)
    costs.each { |key, value| costs[key] = costs[key].to_f.round(2) }
  end

  def decorated_activity_productions
    ActivityProductionDecorator.decorate_collection(object.productions)
  end

  def calcul_global_costs
    costs = { total: 0, inputs: 0, doers: 0, tools: 0, receptions: 0 }
    activity_productions = decorated_activity_productions

    activity_productions.each do |activity_production|
      activity_production_costs = activity_production.global_costs

      sum_costs(costs, activity_production_costs)
    end

    costs
  end
end