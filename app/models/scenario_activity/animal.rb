# frozen_string_literal: true

class ScenarioActivity < ApplicationRecord
  class Animal < ApplicationRecord
    self.table_name = "planning_scenario_activity_animals"
    belongs_to :scenario_activity, class_name: 'ScenarioActivity', foreign_key: :planning_scenario_activity_id
    belongs_to :technical_itinerary, class_name: 'TechnicalItinerary'

    validates :technical_itinerary, :population, :planned_at, presence: true

    scope :of_scenario, lambda { |scenario|
      includes(:scenario_activity)
      .where(planning_scenario_activities: { planning_scenario_id: scenario })
    }

    def generate_daily_charges
      default_generation(planned_at, population)
      @daily_charges
    end

    def animal_name
      index = scenario_activity.animals.find_index(self) + 1
      "#{:animal.tl} #{index}"
    end

    # get budget for activity campaing and technical_itinerary if exist
    def budget
      ActivityBudget.find_by(activity: scenario_activity.activity, campaign: scenario_activity.scenario.campaign, technical_itinerary: technical_itinerary)
    end

    # use existing budget but compute with area in current scenario instead of real activity_production area
    def expenses_amount
      amount = 0.0
      if budget
        budget.expenses.each do |item|
          if item.per_working_unit?
            amount += item.unit_amount * item.quantity * area.round(2) * item.year_repetition
          else
            amount += item.global_amount
          end
        end
      end
      (amount / area).round(2)
    end

    # use existing budget but compute with area in current scenario instead of real activity_production area
    def revenues_amount
      amount = 0.0
      if budget
        budget.revenues.each do |item|
          if item.per_working_unit?
            amount += item.unit_amount * item.quantity * area.round(2) * item.year_repetition
          else
            amount += item.global_amount
          end
        end
      end
      (amount / area).round(2)
    end

    def raw_margin
      revenues_amount - expenses_amount
    end

    def global_margin
      (raw_margin * area).round(2)
    end

    private

      def default_generation(started_at, population)
        started_at = started_at
        date = started_at
        @daily_charges = []
        technical_itinerary.itinerary_templates.includes(intervention_template: :product_parameters).order(:position).each do |template|
          date += template.day_between_intervention
          template.intervention_template.product_parameters.each do |product_parameter|
            daily_charge = product_parameter.daily_charges.build(
              reference_date: date,
              product_type: product_parameter.procedure['type'],
              product_general_type: product_parameter.find_general_product_type,
              quantity: template.intervention_template.quantity_of_parameter(product_parameter, population),
              animal_population: population,
              activity: technical_itinerary.activity
            )
            @daily_charges << daily_charge
          end
        end
      end
  end
end
