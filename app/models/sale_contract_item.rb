# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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
# == Table: sale_contract_items
#
#  created_at         :datetime         not null
#  creator_id         :integer
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  pretax_amount      :decimal(19, 4)   default(0.0), not null
#  quantity           :decimal(19, 4)   default(0.0), not null
#  quantity_unit      :string
#  sale_contract_id   :integer          not null
#  unit_pretax_amount :decimal(19, 4)   not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer          not null
#

class SaleContractItem < ApplicationRecord
  enumerize :quantity_unit, in: %i[hour day fixed], default: :hour, predicates: { prefix: true }
  belongs_to :sale_contract, inverse_of: :items
  belongs_to :variant, class_name: 'ProductNatureVariant', inverse_of: :contract_items
  has_one :product_nature_category, through: :variant, source: :category
  has_many :project_tasks, inverse_of: :sale_contract_item
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :pretax_amount, :quantity, :unit_pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :sale_contract, :variant, presence: true
  # ]VALIDATORS]

  delegate :currency, to: :sale_contract
  sums :sale_contract, :items, :pretax_amount

  # return all contract items for the consider product_nature_category
  scope :of_product_nature_category, lambda { |product_nature_category|
    where(variant_id: ProductNatureVariant.of_categories(product_nature_category))
  }

  before_validation do
    self.quantity ||= 0
  end

  validate do
    errors.add(:quantity, :invalid) if self.quantity.zero?
  end

  def name
    "#{variant.name} | #{quantity}"
  end

  def forecast_duration
    duration = 0.0
    project_tasks.each do |t|
      if t.forecast_duration > 0.0
        if t.forecast_duration_unit == :hour
          duration += t.forecast_duration
        elsif t.forecast_duration_unit == :day
          duration += (t.forecast_duration * 7)
        end
      end
    end
    duration.in(:hour).round(2).l
  end

  def real_duration
    duration = 0.0
    project_tasks.map(&:real_duration).compact.sum if project_tasks.any?
    duration.in(:hour).round(2).l
  end
end
