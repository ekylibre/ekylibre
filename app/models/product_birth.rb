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
#  producer_id     :integer
#  product_id      :integer          not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#

class ProductBirth < Ekylibre::Record::Base
  include Taskable
  belongs_to :product
  belongs_to :producer, class_name: "Product"
  enumerize :nature, in: [:division, :creation], predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :originator_type, allow_nil: true, maximum: 255
  validates_presence_of :nature, :product
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values

  before_update do
    if self.product_id != old_record.product_id
      old_record.product.update_attribute(:born_at, nil)
    end
  end

  before_save do
    if self.product
      if self.stopped_at != self.product.born_at
        self.product.update_attribute(:born_at, self.stopped_at)
      end
    end
  end

  after_save do
    if self.division?
      # Duplicate individual indicator data
      for indicator in producer.variant.indicators_related_to(:individual)
        product.is_measured!(indicator.name, producer.indicator(indicator.name, self.started_at), at: self.stopped_at, originator: self)
      end
      # Add whole indicator data
      for indicator in producer.variant.indicators_related_to(:whole)
        producer_datum = producer.indicator(indicator.name, self.started_at)
        product_datum_value = self.send(indicator.name)
        product.is_measured!(indicator.name, product_datum_value, at: self.stopped_at, originator: self)
        producer.is_measured!(indicator.name, producer_datum.value - product_datum_value, at: self.stopped_at, originator: self)
      end
    end

  end

  before_destroy do
    old_record.product.update_attribute(:born_at, nil)
  end
end
