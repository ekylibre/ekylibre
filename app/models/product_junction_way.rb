# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: product_junction_ways
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  junction_id  :integer          not null
#  lock_version :integer          default(0), not null
#  nature       :string(255)      not null
#  population   :decimal(19, 4)
#  road_id      :integer          not null
#  role         :string(255)      not null
#  shape        :spatial({:srid=>
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ProductJunctionWay < Ekylibre::Record::Base
  attr_readonly :nature
  belongs_to :junction, class_name: "ProductJunction", inverse_of: :ways
  belongs_to :road, inverse_of: :junction_ways, class_name: "Product"
  enumerize :nature, in: [:start, :continuity, :finish], predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_length_of :nature, :role, allow_nil: true, maximum: 255
  validates_presence_of :junction, :nature, :road, :role
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values

  delegate :started_at, :stopped_at, to: :junction

  # DO NOT USE NESTED ATTRIBUTES LIKE THAT
  # accepts_nested_attributes_for :junction

  before_validation do
    if self.nature.blank?
      if self.junction and self.role
        self.nature = self.junction.class.send("#{self.role}_options")[:nature]
      end
    end
  end

  before_update do
    unless self.continuity?
      if self.road_id != old_record.road_id
        old_record.road.update_column(touch_column, nil)
      end
    end
  end

  after_save do
    unless self.continuity?
      if self.road and self.stopped_at != self.road.send(touch_column)
        self.road.update_column(touch_column, self.stopped_at)
      end
      if self.start?
        # Sets frozen and given indicators
        for reading in self.road.variant.readings
          self.road.read!(reading.indicator_name, reading.value, at: self.stopped_at, force: true)
        end
        for indicator in self.road.whole_indicators_list - self.road.frozen_indicators_list
          if self.send(indicator)
            self.road.read!(indicator, self.send(indicator), at: self.stopped_at, force: true)
          end
        end
      end
      # if self.finish?
      #   self.road.read!(:population, 0, at: self.stopped_at)
      # end
    end
  end

  before_destroy do
    unless self.continuity?
      old_record.road.update_attribute(touch_column, nil)
      # old_record.road.readings.where(indicator: "population", read_at: old_record.stopped_at).destroy_all
      # if self.start? and self.population
      #   old_record.road.readings.where(indicator: "population").where("read_at > ?", old_record.stopped_at).update_all("population = population - ?", self.population)
      # end
    end
  end

  def touch_column
    (self.start? ? :born_at : self.finish? ? :dead_at : nil)
  end

end
