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
# == Table: plant_countings
#
#  average_value                :decimal(19, 4)
#  comment                      :text
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  id                           :integer          not null, primary key
#  lock_version                 :integer          default(0), not null
#  nature                       :string
#  number                       :string
#  plant_density_abacus_id      :integer          not null
#  plant_density_abacus_item_id :integer          not null
#  plant_id                     :integer          not null
#  read_at                      :datetime
#  rows_count_value             :integer
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  working_width_value          :decimal(19, 4)
#

class PlantCounting < Ekylibre::Record::Base
  belongs_to :plant
  belongs_to :plant_density_abacus
  belongs_to :plant_density_abacus_item
  has_one :activity, through: :plant_density_abacus
  has_many :items, class_name: 'PlantCountingItem', dependent: :delete_all, inverse_of: :plant_counting
  enumerize :nature, in: %i[sowing germination]

  validates :nature, presence: true
  validates :rows_count_value, numericality: { greater_than: 0 }, allow_blank: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :average_value, :working_width_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :comment, length: { maximum: 500_000 }, allow_blank: true
  validates :number, length: { maximum: 500 }, allow_blank: true
  validates :read_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :rows_count_value, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :plant, :plant_density_abacus, :plant_density_abacus_item, presence: true
  # ]VALIDATORS]
  acts_as_numbered

  delegate :sower, :last_sowing, to: :plant, prefix: true
  delegate :germination_percentage, :sampling_length_unit, :seeding_density_unit, to: :plant_density_abacus
  delegate :seeding_density_value, :plants_count, to: :plant_density_abacus_item
  accepts_nested_attributes_for :items

  before_validation do
    if plant_density_abacus_item
      self.plant_density_abacus = plant_density_abacus_item.plant_density_abacus
    end

    self.average_value ||= 0.0
  end

  def status
    values_expected? ? :go : :stop
  end

  def values_expected?(threshold = 23.0)
    return false if average_value.blank?

    pct_threshold = threshold / 100.0
    qt_threshold = pct_threshold * expected_plants_count

    (-qt_threshold..qt_threshold).cover? (average_value - expected_plants_count)
  end

  def sampling_area
    (sampling_length.to_d(:meter) * implanter_working_width.to_d(:meter)).in(:square_meter)
  end

  def expected_seeding_density
    case nature
    when /sowing/      then seeding_density_value
    when /germination/ then seeding_density_value * germination_percentage / 100
    end
  end

  def expected_plants_count
    case nature
    when /sowing/      then plants_count
    when /germination/ then plants_count * germination_percentage / 100
    end
  end

  def measured_seeding_density
    density = average_value * 10_000 / (implanter_working_width.to_d(:meter) * sampling_length.to_d(:meter))
    density.in :unity_per_hectare
  end

  def density_computable?
    (working_width_value.present? && rows_count_value.present?) ||
      plant_sower.present? &&
        plant_sower.product.variant.has_indicator?(:application_width) &&
        plant_sower.product.variant.application_width(at: plant_last_sowing && plant_last_sowing.stopped_at).nonzero? &&
        plant_sower.product.variant.has_indicator?(:rows_count) &&
        plant_sower.product.variant.rows_count(at: plant_last_sowing && plant_last_sowing.stopped_at).nonzero?
  end

  def implanter_working_width
    raise 'Cannot fetch indicators because we have neither sower nor in-table data.' unless working_width_value || plant_sower.present?
    width = (working_width_value && working_width_value.in(:meter)) || indicator_working_width
    width / rows_count
  end

  def indicator_working_width
    return nil if plant_sower.blank?
    plant_sower.product.variant.application_width(at: plant_last_sowing && plant_last_sowing.stopped_at)
  end

  def rows_count
    raise 'Cannot fetch indicators because we have neither sower nor in-table data.' unless rows_count_value || plant_sower.present?
    rows_count_value || indicator_rows_count
  end

  def indicator_rows_count
    return nil if plant_sower.blank?
    plant_sower.product.variant.rows_count(at: plant_last_sowing && plant_last_sowing.stopped_at)
  end

  def sampling_length
    1.in sampling_length_unit
  end
end
