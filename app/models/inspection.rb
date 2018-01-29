# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: inspections
#
#  activity_id                    :integer          not null
#  comment                        :text
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  forecast_harvest_week          :integer
#  id                             :integer          not null, primary key
#  implanter_application_width    :decimal(19, 4)
#  implanter_rows_number          :integer
#  implanter_working_width        :decimal(19, 4)
#  lock_version                   :integer          default(0), not null
#  number                         :string           not null
#  product_id                     :integer          not null
#  product_net_surface_area_unit  :string
#  product_net_surface_area_value :decimal(19, 4)
#  sampled_at                     :datetime         not null
#  sampling_distance              :decimal(19, 4)
#  updated_at                     :datetime         not null
#  updater_id                     :integer
#

class Inspection < Ekylibre::Record::Base
  belongs_to :activity
  belongs_to :product
  has_many :calibrations, class_name: 'InspectionCalibration',
                          inverse_of: :inspection, dependent: :destroy
  has_many :points, class_name: 'InspectionPoint',
                    inverse_of: :inspection, dependent: :destroy
  has_many :scales, through: :activity, source: :inspection_calibration_scales
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :comment, length: { maximum: 500_000 }, allow_blank: true
  validates :forecast_harvest_week, :implanter_rows_number, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :implanter_application_width, :implanter_working_width, :product_net_surface_area_value, :sampling_distance, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :number, presence: true, length: { maximum: 500 }
  validates :product_net_surface_area_unit, length: { maximum: 500 }, allow_blank: true
  validates :sampled_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :activity, :product, presence: true
  # ]VALIDATORS]
  validates :implanter_rows_number, :product_net_surface_area_value, :implanter_application_width, :sampling_distance, numericality: { greater_than: 0 }, allow_blank: false
  validates :implanter_rows_number, :product_net_surface_area_value, :implanter_application_width, :sampling_distance, presence: true
  validates :forecast_harvest_week, length: { maximum: 2 }

  composed_of :product_net_surface_area, class_name: 'Measure',
                                         mapping: [%w[product_net_surface_area_value to_d], %w[product_net_surface_area_unit unit]]

  acts_as_numbered :number

  accepts_nested_attributes_for :points, allow_destroy: true
  accepts_nested_attributes_for :calibrations, allow_destroy: true

  delegate :measure_grading_net_mass,
           :measure_grading_items_count,
           :measure_grading_sizes,
           :grading_net_mass_unit,
           :measure_something?,
           to: :activity

  scope :of_products, lambda { |*products|
    products.flatten!
    where(product_id: products.map(&:id))
  }

  before_validation do
    if implanter_application_width && implanter_rows_number && implanter_rows_number.nonzero?
      self.implanter_working_width = implanter_application_width / implanter_rows_number
    end
  end

  # ORDERING
  def siblings
    product.inspections
  end

  # return the order of the grading relative to product
  def position
    siblings.reorder(:sampled_at).pluck(:id).index(id) + 1
  end
  # CALCULATIONS

  ### CALIBRATIONS
  def quantity(dimension, scale = nil)
    calibration_values(dimension, :quantity_in_unit, scale)
  end

  def quantity_yield(dimension, scale = nil)
    calibration_values(dimension, :quantity_yield, scale)
  end

  def marketable_quantity(dimension, scale = nil)
    calibration_values(dimension, :marketable_quantity, scale, true)
  end

  def marketable_yield(dimension, scale = nil)
    calibration_values(dimension, :marketable_yield, scale, true)
  end

  def projected_total(dimension, scale = nil)
    calibration_values(dimension, :projected_total, scale)
  end

  def unmarketable_rate(dimension)
    total = quantity(dimension)
    total.to_d.nonzero? && (points_unmarketable_sum(dimension) / total)
  end

  ### POINTS
  def points_sum(dimension, category = nil)
    sum_column_on(points_of_category(category), dimension)
  end

  def points_unmarketable_sum(dimension)
    sum_column_on(points.unmarketable, dimension)
  end

  def points_of_category(category = nil)
    return points if category.blank?
    points.of_category(category)
  end

  def points_total(dimension, category = nil)
    sum_on_points :projected_total,
                  from: category,
                  with: dimension
  end

  def points_yield(dimension, category = nil)
    sum_on_points :quantity_yield,
                  from: category,
                  with: dimension
  end

  def points_percentage(dimension, category = nil)
    sum_on_points :percentage,
                  round: false,
                  from: category,
                  with: dimension
  end

  # BASIC VALUES

  ### AREAS
  def total_area(unit: nil)
    unit ||= default_area_unit
    product_net_surface_area.to_d(unit)
  end

  def sample_area(unit: nil)
    unit ||= default_area_unit
    sampling_area.to_d(unit)
  end

  def product_net_surface_area
    return nil if product_net_surface_area_value.blank? ||
                  product_net_surface_area_unit.blank?
    product_net_surface_area_value.in(product_net_surface_area_unit)
  end

  def sampling_area
    (sampling_length.to_d(:meter) * implanter_working_width).in(:square_meter)
  end

  def sampling_length
    (sampling_distance || 0).in(:meter)
  end

  ### MEASURE
  def measure_grading(dimension)
    send :"measure_grading_#{dimension}" # Delegated to activity
  end

  # PREDICATES
  def quantity_statable?(dimension)
    product_net_surface_area && measure_grading(dimension)
  end

  def quantity_measured?(dimension)
    measure_grading(dimension) && quantity(dimension).to_f.nonzero?
  end

  def any_quantity?
    %i[net_mass items_count].any? { |dim| quantity_measured?(dim) }
  end

  # CODE HELPERS

  def column_for(dimension)
    :"#{dimension}_value"
  end

  def unknown_dimension(dimension)
    raise "Unknown dimension #{dimension.inspect}"
  end

  # UNITS
  def quantity_unit(dimension)
    return Nomen::Unit.find(default_quantity_unit(dimension)) if dimension.to_sym == :items_count
    return grading_net_mass_unit                              if dimension.to_sym == :net_mass
  end

  def quantity_per_area_unit(dimension)
    possible_unit = "#{quantity_unit(dimension).name}_per_#{product_net_surface_area.unit}"
    return possible_unit if Nomen::Unit.find(possible_unit)
    default_per_area_unit(dimension)
  end

  def user_quantity_unit(dimension)
    return :thousand  if dimension.to_sym == :items_count
    return :ton       if dimension.to_sym == :net_mass
    unknown_dimension(dimension)
  end

  def user_per_area_unit(dimension)
    return :thousand_per_hectare      if dimension.to_sym == :items_count
    return :ton_per_hectare           if dimension.to_sym == :net_mass
    unknown_dimension(dimension)
  end

  def default_per_area_unit(dimension)
    return :unity_per_square_meter     if dimension.to_sym == :items_count
    return :kilogram_per_square_meter  if dimension.to_sym == :net_mass
    unknown_dimension(dimension)
  end

  def default_quantity_unit(dimension)
    return :unity     if dimension.to_sym == :items_count
    return :kilogram  if dimension.to_sym == :net_mass
    unknown_dimension(dimension)
  end

  def default_area_unit
    :square_meter
  end

  protected

  # CODE FACTORING

  def mappable(method, dimension)
    ->(point_or_calib) { point_or_calib.send(method, dimension) }
  end

  # Returns the sum of measurements on a scale if one is provided or the average
  # of measurements across all scales if none is.
  def calibration_values(dimension, method_name, scale = nil, marketable = false)
    on_scales = [scale]
    on_scales = scales if scale.nil?
    return 0 if on_scales.empty?
    sum_per_calib = on_scales.map do |s|
      calib = calibrations.of_scale(s)
      calib = calib.marketable if marketable
      calib.map(&mappable(method_name, dimension)).compact.sum
    end
    sum_per_calib.compact.reject(&:zero?).sum / sum_per_calib.size
  end

  def sum_on_points(method, from: nil, with: nil, round: false)
    sum = points_of_category(from)
          .map(&mappable(method, with))
          .sum
    round ? sum.round(round) : sum
  end

  def sum_column_on(points, dimension)
    column = column_for(dimension)
    points.sum(column).in quantity_unit(dimension)
  end
end
