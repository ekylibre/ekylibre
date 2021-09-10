# frozen_string_literal: true

class ScenarioDecorator < Draper::Decorator
  delegate_all

  def activities_with_area
    scenario_activities.map do |scenario_activity|
      area = scenario_activity.decorate.total_area.in(:hectare).l(precision: 1)
      "#{scenario_activity.activity.name} (#{area})"
    end.join(', ')
  end

  def total_area
    activities_id = scenario_activities.pluck(:id)
    plots = ScenarioActivity::Plot.where(planning_scenario_activity_id: activities_id)
    plots.sum(:area)
  end
end
