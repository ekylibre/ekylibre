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
# == Table: product_prices
#
#  amount        :decimal(19, 4)   not null
#  created_at    :datetime         not null
#  creator_id    :integer
#  currency      :string(255)      not null
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  pretax_amount :decimal(19, 4)   not null
#  product_id    :integer          not null
#  started_at    :datetime
#  stopped_at    :datetime
#  supplier_id   :integer          not null
#  tax_id        :integer
#  template_id   :integer          not null
#  updated_at    :datetime         not null
#  updater_id    :integer
#


# ProductPrice stores all the prices used in sales and purchases.
class ProductPrice < Ekylibre::Record::Base
  belongs_to :product
  belongs_to :template, :class_name => "ProductPriceTemplate"
  belongs_to :supplier, :class_name => "Entity"
  belongs_to :tax
  has_many :incoming_delivery_items, :foreign_key => :price_id
  has_many :outgoing_delivery_items, :foreign_key => :price_id
  has_many :purchase_items, :foreign_key => :price_id
  has_many :sale_items, :foreign_key => :price_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 255
  validates_presence_of :amount, :currency, :pretax_amount, :product, :supplier, :template
  #]VALIDATORS]
  validates_presence_of :started_at

  before_validation do
    self.started_at ||= Time.now
    if self.template
      self.supplier ||= self.template.supplier
    end
  end

  validate do
    if self.template
      if self.template.supplier_id != self.supplier_id
        errors.add(:supplier_id, :invalid)
      end
    end
  end

end
