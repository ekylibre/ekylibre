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
# == Table: contract_items
#
#  contract_id        :integer          not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  pretax_amount      :decimal(19, 4)   default(0.0), not null
#  quantity           :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount :decimal(19, 4)   not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer          not null
#

class ContractItem < Ekylibre::Record::Base
  belongs_to :contract, inverse_of: :items
  belongs_to :variant, class_name: 'ProductNatureVariant', inverse_of: :contract_items
  has_one :product_nature_category, through: :variant, source: :category
  has_many :purchases, through: :contract
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :pretax_amount, :quantity, :unit_pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :contract, :variant, presence: true
  # ]VALIDATORS]
  validates :quantity, exclusion: { in: [0], message: :invalid }

  delegate :currency, to: :contract
  sums :contract, :items, :pretax_amount

  # return all contract items  between two dates
  scope :between, lambda { |started_on, stopped_on|
    where(contract_id: Purchase.invoiced_between(started_on, stopped_on).select(:contract_id))
  }

  # return all contract items for the consider product_nature_category
  scope :of_product_nature_category, lambda { |product_nature_category|
    where(variant_id: ProductNatureVariant.of_categories(product_nature_category))
  }

  before_validation do
    self.quantity ||= 0
  end
end
