# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: product_gradings
#
#  activity_id                 :integer          not null
#  comment                     :text
#  created_at                  :datetime         not null
#  creator_id                  :integer
#  id                          :integer          not null, primary key
#  implanter_application_width :decimal(19, 4)
#  implanter_rows_number       :integer
#  implanter_working_width     :decimal(19, 4)
#  lock_version                :integer          default(0), not null
#  number                      :string           not null
#  product_id                  :integer          not null
#  sampled_at                  :datetime         not null
#  sampling_distance           :decimal(19, 4)
#  updated_at                  :datetime         not null
#  updater_id                  :integer
#

class ProductGrading < Ekylibre::Record::Base
  belongs_to :activity
  belongs_to :product
  has_many :checks, class_name: 'ProductGradingCheck', foreign_key: :product_grading_id, inverse_of: :product_grading, dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :sampled_at, allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years }
  validates_numericality_of :implanter_rows_number, allow_nil: true, only_integer: true
  validates_numericality_of :implanter_application_width, :implanter_working_width, :sampling_distance, allow_nil: true
  validates_presence_of :activity, :number, :product, :sampled_at
  # ]VALIDATORS]

  acts_as_numbered :number

  accepts_nested_attributes_for :checks, allow_destroy: true

  before_validation :set_implanter_values, on: :create

  before_validation do
    if implanter_rows_number && implanter_rows_number != 0
      self.implanter_working_width = implanter_application_width / implanter_rows_number
    end
  end

  def set_implanter_values
    # get sowing intervention of current plant
    intervention = Intervention.with_generic_cast(:output, product)

    intervention = nil

    if intervention
      # get abilities of each tool to grab sower or implanter
      intervention.first.tools.each do |tool|
        if tool.product.can('sow') || tool.product.can('implant')
          equipment = tool.product
        end
      end

      if equipment
        # get rows_count and application_width of sower or implanter
        rows_count = nil
        # rows_count = equipment.rows_count(self.sampled_at)
        application_width = equipment.application_width(sampled_at)
        # set rows_count to implanter_application_width
        self.implanter_rows_number ||= rows_count if rows_count
        self.implanter_application_width ||= application_width if application_width
      end

    end
  end

  # return the order of the grading relative to product
  def position
    a = product.gradings.reorder(:sampled_at).pluck(:id)
    a.each_with_index do |value, index|
      return index + 1 if id == value
    end
  end

  # return a measure of total net mass of all product grading checks of type :calibre
  def net_mass(unit = :kilogram)
    total = checks.of_nature(:calibre).map(&:net_mass_value).compact.sum
    total = total.in(unit) if unit
    total
  end

  # return total count of all product grading checks of type :calibre
  def item_count
    total = checks.of_nature(:calibre).map(&:items_count).compact.sum
    total
  end

  # return the current stock in ground
  # unit could be :ton or :thousand
  # n : number of product or net mass of product
  # m : sampling distance value in meter (see abacus)
  # c : coefficient (see abacus)
  # total : n * ( plant_surface_area / m ) * c
  def product_stock_in_ground(unit = :ton, surface_unit = :hectare)
    # area unit
    area_unit = unit.to_s + '_per_' + surface_unit.to_s

    # n
    n = if unit == :ton || unit == :kilogram
          net_mass.convert(unit)
        elsif unit == :unity
          item_count
        else
          net_mass.to_d(:ton)
        end

    # plant_surface_area
    if product && product.is_a?(Plant)
      plant_surface_area = product.net_surface_area.convert(surface_unit)
    end

    # m
    m = sampling_distance if sampling_distance

    # c
    c = 10_000 / implanter_working_width if implanter_working_width

    # total
    if n && c
      current_stock = n * (plant_surface_area.to_d / m) * c
      return current_stock.to_d.in(unit.to_sym)
    else
      return nil
    end
  end
end
