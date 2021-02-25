# frozen_string_literal: true

class ActivityDecorator < Draper::Decorator
  delegate_all

  def animal_family?
    object.family == :animal_farming
  end

  def production_costs(current_campaign)
    calcul_productions_costs(current_campaign)
  end

  def working_zone_area(current_campaign)
    Activities::WorkingZoneAreaCalculation.new.compute_working_zone_area(self, current_campaign)
  end

  def human_working_zone_area(current_campaign)
    working_zone_area(current_campaign)
      .in(:hectare)
      .round(3)
      .l
  end

  def net_surface_area(current_campaign)
    Activities::NetSurfaceAreaCalculation.new.compute_net_surface_area(self, current_campaign)
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
      costs.each { |key, value| costs[key] = value / divider unless divider.zero? }
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

    # TODO: Cache costs, net_surface_area, working_zone_area
    def calcul_productions_costs(current_campaign)
      global_costs = Activities::CostsCalculation.new.compute_costs(self, current_campaign)
      {
        global_costs: global_costs,
        cultivated_hectare_costs: human_costs(divider_costs(global_costs.clone, net_surface_area(current_campaign).to_d)),
        working_hectare_costs: human_costs(divider_costs(global_costs.clone, working_zone_area(current_campaign).to_d))
      }
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
