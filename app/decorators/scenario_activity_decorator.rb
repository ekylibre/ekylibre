# frozen_string_literal: true

class ScenarioActivityDecorator < Draper::Decorator
  delegate_all

  def total_area
    plots.sum(:area)
  end
end
