# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: product_births
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  nature          :string(255)      not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string(255)
#  population      :decimal(19, 4)
#  producer_id     :integer
#  product_id      :integer          not null
#  shape           :spatial({:srid=>
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#

class ProductBirth < Ekylibre::Record::Base
  include Taskable
  belongs_to :product, inverse_of: :birth
  belongs_to :producer, class_name: "Product"
  enumerize :nature, in: [:division, :creation], predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_length_of :nature, :originator_type, allow_nil: true, maximum: 255
  validates_presence_of :nature, :product
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values

  before_update do
    if self.product_id != old_record.product_id
      old_record.product.update_column(:born_at, nil)
    end
  end

  after_save do
    if self.product
      if self.stopped_at != self.product.born_at
        self.product.update_column(:born_at, self.stopped_at)
      end
    end
  end

  after_save do
    if self.division?
      # Duplicate individual indicator data
      for indicator_name in producer.individual_indicators_list
        if datum = producer.indicator_datum(indicator_name, at: self.started_at)
          product.is_measured!(indicator_name, datum.value, at: self.stopped_at, originator: self)
        end
      end
      # Add whole indicator data
      for indicator_name in producer.whole_indicators_list
        producer_datum_value = producer.send(indicator_name, at: self.started_at)
        product_datum_value = self.send(indicator_name)
        if producer_datum_value and product_datum_value
          product.is_measured!(indicator_name,  product_datum_value, at: self.stopped_at, originator: self)
          producer.is_measured!(indicator_name, producer_datum_value - product_datum_value, at: self.stopped_at, originator: self)
        else
          if producer_datum_value.nil? and product_datum_value.nil?
            puts "Cannot divide empty #{indicator_name.to_s.pluralize} between producer ##{producer.id} and produced ##{product.id}."
          else
            raise "Need to divide #{indicator_name} but no way to do it properly\n" +
              {producer: producer_datum_value, produced: product_datum_value}.collect{|k,v| "#{k}: #{v.inspect}"}.join("\n")
          end
        end
      end
    elsif self.creation?
      if self.producer
        # Nothing to do
      else
        for indicator_name in self.product.whole_indicators_list
          product.is_measured!(indicator_name, self.send(indicator_name), at: self.stopped_at, originator: self)
        end    
      end
    end
  end

  before_destroy do
    old_record.product.update_attribute(:born_at, nil)
  end
end
