# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: planning_scenario_activity_plots
#
#  area                          :decimal(, )
#  batch_planting                :boolean          default(FALSE)
#  created_at                    :datetime         not null
#  creator_id                    :integer(4)
#  id                            :integer(4)       not null, primary key
#  number_of_batch               :integer(4)
#  planned_at                    :date
#  planning_scenario_activity_id :integer(4)
#  sowing_interval               :integer(4)
#  technical_itinerary_id        :integer(4)
#  updated_at                    :datetime         not null
#  updater_id                    :integer(4)
#

class ScenarioActivity < ApplicationRecord
  class Plot < ApplicationRecord
    self.table_name = "planning_scenario_activity_plots"
    belongs_to :scenario_activity, class_name: 'ScenarioActivity', foreign_key: :planning_scenario_activity_id
    belongs_to :technical_itinerary, class_name: 'TechnicalItinerary'
    has_one :batch, class_name: 'ActivityProductionBatch', dependent: :destroy, foreign_key: :planning_scenario_activity_plot_id

    accepts_nested_attributes_for :batch, allow_destroy: true
    validates :technical_itinerary, :area, :planned_at, presence: true

    before_validation do
      # remove batch if exist and if batch_planting is false
      if self.batch && !batch_planting?
        batch.destroy
      end
    end

    scope :of_scenario, lambda { |scenario|
      includes(:scenario_activity)
      .where(planning_scenario_activities: { planning_scenario_id: scenario })
    }

    def human_area
      area.in(:hectare).l(precision: 2)
    end

    def generate_daily_charges
      if batch_planting
        if batch.irregular_batch
          generate_daily_charges_irregular_batch
        else
          generate_daily_charges_regular_batch
        end
      else
        generate_daily_charges_no_batch
      end
      @daily_charges
    end

    def total_area
      return batch.irregular_batches.sum(:area) if batch_planting && batch.irregular_batch

      area
    end

    def parcel_name
      index = scenario_activity.plots.find_index(self) + 1
      "#{:plot.tl} #{index}"
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

      def generate_daily_charges_irregular_batch
        batch.irregular_batches.each do |irregular_batch|
          started_at = irregular_batch.estimated_sowing_date
          date = started_at
          default_generation(started_at, irregular_batch.area)
        end
      end

      def generate_daily_charges_regular_batch
        net_area = area / batch.number
        @daily_charges = []
        started_at = planned_at
        batch.number.times do |number|
          started_at += batch.day_interval.days unless number.zero?
          default_generation(started_at, net_area)
        end
      end

      def generate_daily_charges_no_batch
        default_generation(planned_at, area)
      end

      def default_generation(started_at, area)
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
              quantity: template.intervention_template.quantity_of_parameter(product_parameter, area),
              area: area,
              activity: technical_itinerary.activity
            )
            @daily_charges << daily_charge
          end
        end
      end
  end
end
