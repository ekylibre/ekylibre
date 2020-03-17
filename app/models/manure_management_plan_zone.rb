# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: manure_management_plan_zones
#
#  absorbed_nitrogen_at_opening                    :decimal(19, 4)
#  activity_production_id                          :integer          not null
#  administrative_area                             :string
#  computation_method                              :string           not null
#  created_at                                      :datetime         not null
#  creator_id                                      :integer
#  cultivation_variety                             :string
#  expected_yield                                  :decimal(19, 4)
#  humus_mineralization                            :decimal(19, 4)
#  id                                              :integer          not null, primary key
#  intermediate_cultivation_residue_mineralization :decimal(19, 4)
#  irrigation_water_nitrogen                       :decimal(19, 4)
#  lock_version                                    :integer          default(0), not null
#  maximum_nitrogen_input                          :decimal(19, 4)
#  meadow_humus_mineralization                     :decimal(19, 4)
#  mineral_nitrogen_at_opening                     :decimal(19, 4)
#  nitrogen_at_closing                             :decimal(19, 4)
#  nitrogen_input                                  :decimal(19, 4)
#  nitrogen_need                                   :decimal(19, 4)
#  organic_fertilizer_mineral_fraction             :decimal(19, 4)
#  plan_id                                         :integer          not null
#  previous_cultivation_residue_mineralization     :decimal(19, 4)
#  soil_nature                                     :string
#  soil_production                                 :decimal(19, 4)
#  updated_at                                      :datetime         not null
#  updater_id                                      :integer
#
class ManureManagementPlanZone < Ekylibre::Record::Base
  belongs_to :plan, class_name: 'ManureManagementPlan', inverse_of: :zones
  belongs_to :activity_production
  has_one :activity, through: :activity_production
  has_one :campaign, through: :plan
  has_one :support, through: :activity_production
  has_one :cultivable_zone, through: :activity_production, source: :support
  refers_to :soil_nature
  refers_to :cultivation_variety, class_name: 'Variety'
  refers_to :administrative_area
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :absorbed_nitrogen_at_opening, :expected_yield, :humus_mineralization, :intermediate_cultivation_residue_mineralization, :irrigation_water_nitrogen, :maximum_nitrogen_input, :meadow_humus_mineralization, :mineral_nitrogen_at_opening, :nitrogen_at_closing, :nitrogen_input, :nitrogen_need, :organic_fertilizer_mineral_fraction, :previous_cultivation_residue_mineralization, :soil_production, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :computation_method, presence: true, length: { maximum: 500 }
  validates :activity_production, :plan, presence: true
  # ]VALIDATORS]

  delegate :locked?, :opened_at, to: :plan
  delegate :name, to: :cultivable_zone

  scope :selecteds, -> { joins(:plan).merge(ManureManagementPlan.selecteds) }

  protect do
    locked?
  end

  def estimate_expected_yield
    if computation_method
      self.expected_yield = Calculus::ManureManagementPlan.estimate_expected_yield(parameters).to_f(plan.mass_density_unit)
    end
  end

  def compute
    for name, value in Calculus::ManureManagementPlan.compute(parameters)
      if %w[absorbed_nitrogen_at_opening expected_yield humus_mineralization intermediate_cultivation_residue_mineralization irrigation_water_nitrogen maximum_nitrogen_input meadow_humus_mineralization mineral_nitrogen_at_opening nitrogen_at_closing nitrogen_input nitrogen_need organic_fertilizer_mineral_fraction previous_cultivation_residue_mineralization soil_production].include?(name.to_s)
        send("#{name}=", value.to_f(:kilogram_per_hectare))
      end
    end
    save!
  end

  def parameters
    hash = {
      available_water_capacity: available_water_capacity,
      opened_at: opened_at,
      support: activity_production
    }
    if activity_production.usage
      hash[:production_usage] = Nomen::ProductionUsage[activity_production.usage]
    end
    if computation_method && Calculus::ManureManagementPlan.method_exist?(computation_method.to_sym)
      hash[:method] = computation_method.to_sym
    else
      Rails.logger.warn "Method #{computation_method} doesn't exist. Use default method instead."
      hash[:method] = :external
    end
    if administrative_area
      hash[:administrative_area] = Nomen::AdministrativeArea[administrative_area]
    end
    hash[:variety] = Nomen::Variety[cultivation_variety] if cultivation_variety
    hash[:soil_nature] = Nomen::SoilNature[soil_nature] if soil_nature
    if expected_yield
      hash[:expected_yield] = expected_yield.in(plan.mass_density_unit)
    end
    hash
  end

  # TODO: Compute available from parcels or CZ ?
  def available_water_capacity
    0.0.in_liter_per_hectare
  end

  # To have human_name in report
  def soil_nature_name
    unless soil_nature && item = Nomen::SoilNature[soil_nature].human_name
      return nil
    end
    item
  end

  def cultivation_variety_name
    unless cultivation_variety && item = Nomen::Variety[cultivation_variety].human_name
      return nil
    end
    item
  end
end
