# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2022 Ekylibre SAS
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
# == Table: rides
#
#  area_smart           :float
#  area_with_overlap    :float
#  area_without_overlap :float
#  created_at           :datetime         not null
#  creator_id           :integer
#  cultivable_zone_id   :integer(8)
#  distance_km          :float
#  duration             :interval
#  equipment_name       :string
#  gasoline             :float
#  id                   :integer          not null, primary key
#  intervention_id      :integer
#  lock_version         :integer          default(0), not null
#  nature               :string
#  number               :string
#  product_id           :integer
#  provider             :jsonb
#  ride_set_id          :integer
#  shape                :geometry({:srid=>4326, :type=>"geometry"})
#  sleep_count          :integer
#  sleep_duration       :interval
#  started_at           :datetime
#  stopped_at           :datetime
#  updated_at           :datetime         not null
#  updater_id           :integer
#
class Ride < ApplicationRecord
  include Attachable
  include Providable
  include HasInterval
  belongs_to :equipment, class_name: 'Equipment', foreign_key: :product_id
  belongs_to :ride_set
  belongs_to :intervention
  has_many :crumbs, dependent: :destroy

  belongs_to :cultivable_zone

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :area_smart, :area_with_overlap, :area_without_overlap, :distance_km, :gasoline, numericality: true, allow_blank: true
  validates :converting_to_intervention, inclusion: { in: [true, false] }
  validates :number, length: { maximum: 500 }, allow_blank: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(ride) { ride.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :duration, :number, :sleep_duration, length: { maximum: 500 }, allow_blank: true

  has_interval :duration, :sleep_duration

  # Shape represents a linestring of all crumbs related to the ride
  has_geometry :shape, type: :line_string

  scope :of_nature, ->(nature_name) { where(nature: nature_name) }
  scope :with_state, ->(state) do
    if state == :affecting
      where(converting_to_intervention: true)
    else
      where("intervention_id IS #{state == :affected ? 'NOT NULL' : 'NULL'}")
    end
  end

  scope :linkable_to_intervention, -> {
    with_state(:unaffected).where(nature: :work)
  }

  acts_as_numbered :number
  enumerize :nature, in: %i[road work], scope: true

  def state
    return :affected if intervention_id.present?

    converting_to_intervention ? :affecting : :unaffected
  end

  def working_zone
    Rides::ComputeWorkingZone.call(rides: [self])
  end

  def main_equipment
    ride_set.equipments.of_nature('main')&.first&.name
  end

  def additional_tool_one
    tool_one = ride_set.equipments.of_nature('additional')[0]
    tool_one.name if tool_one
  end

  def additional_tool_two
    tool_two = ride_set.equipments.of_nature('additional')[1]
    tool_two.name if tool_two
  end

  %i[duration sleep_duration].each do |col|
    define_method "decorated_#{col}" do
      decorate.send(col)
    end
  end
end
