# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: sale_items
#
#  account_id           :integer
#  amount               :decimal(19, 4)   default(0.0), not null
#  annotation           :text
#  created_at           :datetime         not null
#  creator_id           :integer
#  credited_item_id     :integer
#  currency             :string           not null
#  id                   :integer          not null, primary key
#  label                :text
#  lock_version         :integer          default(0), not null
#  position             :integer
#  pretax_amount        :decimal(19, 4)   default(0.0), not null
#  quantity             :decimal(19, 4)   default(1.0), not null
#  reduction_percentage :decimal(19, 4)   default(0.0), not null
#  reference_value      :string           not null
#  sale_id              :integer          not null
#  tax_id               :integer
#  unit_amount          :decimal(19, 4)   default(0.0), not null
#  unit_pretax_amount   :decimal(19, 4)
#  updated_at           :datetime         not null
#  updater_id           :integer
#  variant_id           :integer          not null
#

class SaleCreditItem < SaleItem
  belongs_to :sale_credit, foreign_key: :sale_id, inverse_of: :items
  serialize :quantity, NegativeNumeric
  serialize :amount, NegativeNumeric
  serialize :pretax_amount, NegativeNumeric

  sums :sale_credit, :items, :pretax_amount, :amount, negate: true

  # validate do
  #   if self.credited_item
  #     maximum_quantity = self.quantity - self.credited_item.quantity - self.credited_item.credited_quantity
  #     if self.credited_item.quantity > 0
  #       errors.add(:quantity, :less_than, count: 0) if self.quantity > 0
  #       errors.add(:quantity, :greater_than, count: maximum_quantity) if self.quantity < maximum_quantity
  #     else # if self.credited_item.quantity < 0
  #       errors.add(:quantity, :greater_than, count: 0) if self.quantity < 0
  #       errors.add(:quantity, :less_than, count: maximum_quantity) if self.quantity > maximum_quantity
  #     end
  #   end
  # end

  def compute_amounts
    Calculus::TaxedAmounts::Credit.new(self).compute
  end

end
