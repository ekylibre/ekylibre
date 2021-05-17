# frozen_string_literal: true

class ActivityProductionDecorator < Draper::Decorator
  delegate_all

  def plants?
    object
      .products
      .select { |product| product.is_a?(Plant) }
      .any?
  end

  def production_costs(current_campaign)
    {
      global_costs: human_global_costs(current_campaign),
      cultivated_hectare_costs: human_cultivated_hectare_costs(current_campaign),
      working_hectare_costs: human_working_hectare_costs(current_campaign)
    }
  end

  def global_costs(current_campaign)
    @global_costs ||= ActivityProductions::CostsCalculation.new.compute_costs(self, current_campaign)
  end

  def human_global_costs(current_campaign)
    human_costs(global_costs(current_campaign))
  end

  def cultivated_hectare_costs(current_campaign)
    if @cultivated_hectare_costs.nil?
      costs = global_costs(current_campaign).clone
      divider_costs(costs, object.net_surface_area.in(:hectare).round(2).to_d)
      total_costs(costs)
    end

    @cultivated_hectare_costs ||= costs
  end

  def human_cultivated_hectare_costs(current_campaign)
    human_costs(cultivated_hectare_costs(current_campaign))
  end

  def working_hectare_costs(current_campaign)
    @working_hectare_costs ||= divider_costs(global_costs(current_campaign).clone, working_zone_area(current_campaign).to_f)
  end

  def human_working_hectare_costs(current_campaign)
    human_costs(working_hectare_costs(current_campaign))
  end

  def working_zone_area(current_campaign)
    @working_zone_area ||= ActivityProductions::WorkingZoneAreaCalculation.new.compute_working_zone_area(self, current_campaign)
  end

  def human_working_zone_area(current_campaign)
    working_zone_area(current_campaign)
      .in(:hectare)
      .round(2)
      .l(precision: 2)
  end

  private

    def total_costs(costs)
      costs = costs.except!(:total) if costs.key?(:total)

      costs[:total] = costs.values.sum
    end

    def divider_costs(costs, divider)
      costs.each { |key, value| costs[key] = value / divider unless divider.zero? }
    end

    def human_costs(costs)
      costs.each { |key, _value| costs[key] = costs[key].to_i }
    end
end
