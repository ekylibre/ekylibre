# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
#  product_id   :integer          not null
#  role         :string(255)      not null
#  shape        :spatial({:srid=>
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ProductJunctionWay < Ekylibre::Record::Base
  attr_readonly :nature
  belongs_to :junction, class_name: "ProductJunction", inverse_of: :ways
  belongs_to :product, inverse_of: :junction_ways
  enumerize :nature, in: [:start, :continuity, :end], predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_length_of :nature, :role, allow_nil: true, maximum: 255
  validates_presence_of :junction, :nature, :product, :role
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values

  delegate :started_at, :stopped_at, to: :junction

  # accepts_nested_attributes_for :product

  before_validation do
    if self.nature.blank?
      if self.junction and self.role
        self.nature = self.junction.class.send("#{self.role}_options")[:nature]
      end
    end
  end


  before_update do
    unless self.continuity?
      if self.product_id != old_record.product_id
        old_record.product.update_column(touch_column, nil)
      end
    end
  end

  after_save do
    unless self.continuity?
      if self.product and self.stopped_at != self.product.send(touch_column)
        self.product.update_column(touch_column, self.stopped_at)
      end
      if self.end?
        self.product.is_measured!(:population, 0, at: self.stopped_at)
      end
    end
  end

  before_destroy do
    unless self.continuity?
      old_record.product.update_attribute(touch_column, nil)
      if self.end?
        old_record.product.indicator_data.where(indicator: "population", measured_at: old_record.stopped_at).destroy_all
      end
    end
  end

  def touch_column
    (self.start? ? :born_at : self.end? ? :dead_at : nil)
  end

end
