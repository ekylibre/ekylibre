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
# == Table: ride_sets
#
#  area_smart           :float
#  area_with_overlap    :float
#  area_without_overlap :float
#  created_at           :datetime         not null
#  creator_id           :integer(4)
#  duration             :interval
#  gasoline             :float
#  id                   :integer(4)       not null, primary key
#  lock_version         :integer(4)       default(0), not null
#  nature               :string
#  number               :string
#  provider             :jsonb
#  road                 :decimal(19, 4)
#  shape                :geometry({:srid=>4326, :type=>"geometry"})
#  sleep_count          :integer(4)
#  sleep_duration       :interval
#  started_at           :datetime
#  stopped_at           :datetime
#  updated_at           :datetime         not null
#  updater_id           :integer(4)
#
class RideSet < ApplicationRecord
  include Attachable
  include Providable
  include HasInterval
  has_many :rides, dependent: :destroy
  has_many :crumbs, through: :rides
  has_many :equipments, class_name: 'RideSetEquipment', inverse_of: :ride_set, dependent: :destroy
  has_many :products, through: :equipments
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :area_smart, :area_with_overlap, :area_without_overlap, :gasoline, numericality: true, allow_blank: true
  validates :duration, :number, :sleep_duration, length: { maximum: 500 }, allow_blank: true
  validates :road, numericality: { greater_than: -10_000_000_000, less_than: 10_000_000_000 }, allow_blank: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(ride_set) { ride_set.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]

  # Shape represents a polygon with all the rides linked with a buffer
  has_geometry :shape

  has_interval :duration, :sleep_duration

  acts_as_numbered :number
  enumerize :nature, in: %i[road work]

  scope :between, lambda { |started_at, stopped_at|
    where(started_at: started_at..stopped_at)
  }

  %i[duration sleep_duration state].each do |col|
    define_method "decorated_#{col}" do
      decorate.send(col)
    end
  end

  def main_equipment
    equipments.of_nature('main')&.first&.name
  end

  def additional_tool_one
    tool_one = equipments.of_nature('additional')[0]
    tool_one.name if tool_one
  end

  def additional_tool_two
    tool_two = equipments.of_nature('additional')[1]
    tool_two.name if tool_two
  end

  def state
    return :converted if rides_affected?
    return :converted if rides_of_nature_work_affected?
    return :partially_converted if rides_of_nature_work_partially_affected?
    return :partially_converted if rides_of_nature_road_partially_affected?

    :to_convert
  end

  def rides_affected?
    rides = self.rides.map(&:state)
    rides.uniq.size <= 1 && rides.include?(:affected)
  end

  def rides_of_nature_work_affected?
    rides = self.rides.of_nature("work").map(&:state)
    rides.uniq.size <= 1 && rides.include?(:affected)
  end

  def rides_of_nature_work_partially_affected?
    rides = self.rides.of_nature("work").map(&:state)
    rides.uniq.size >= 2 && rides.include?(:affected)
  end

  def rides_of_nature_road_partially_affected?
    rides = self.rides.of_nature("road").map(&:state)
    rides.uniq.size >= 2
  end
end
