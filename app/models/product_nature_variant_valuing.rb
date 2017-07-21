# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: product_nature_variant_valuings
#
#  average_cost_amount       :decimal          not null
#  amount                    :decimal          not null
#  created_at                :datetime         not null
#  id                        :integer          not null, primary key
#  updated_at                :datetime         not null
#  variant_id                :integer          not null
#


class ProductNatureVariantValuing < ActiveRecord::Base
  belongs_to :variant, class_name: 'ProductNatureVariant'

  validates :average_cost_amount, presence: true
  validates :amount, presence: true

  def initialize(pu, quantity_action, variant_id)
    @pu = pu
    @quantity_action = quantity_action
    @variant = ProductNatureVariant.find(variant_id)

# belongs_to :stock_account, class_name: 'Account'
    @old_quantity = @variant.stock_account.last

    @old_product_nature_variant_valuing = ProductNatureVariantValuing.where(variant: @variant)
    @old_amount = @old_product_nature_variant_valuing.amount
    @old_cump = @old_product_nature_variant_valuing.cump
  end
# some logical, verification in process
  def calculate_output
    quantity_new = @variant.stock_account.last + @quantity_action
    amount = @old_amount + @quantity_action * @pu
    cump = amount / quantity_new

    @product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, cump: cump, variant_id: @variant.id)
    @product_nature_variant_valuing.save
  end

  def calculate_input
    quantity_new = old_quantity - quantity_action
    amount = @old_amount - quantity_action * @old_cump
    cump = amount / quantity_new

    @product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, cump: cump, variant_id: @variant_id)
    @product_nature_variant_valuing.save
  end

  def calculate_inventory
    quantity_actual = @old_quantity
    amount = quantity_actual * @old_cump
    cump = amount / quantity_actual

    @product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, cump: cump, variant_id: @variant_id)
    @product_nature_variant_valuing.save
  end

end
