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

class ProductNatureVariantValuing < Ekylibre::Record::Base
  belongs_to :variant, class_name: 'ProductNatureVariant'

  # some logical, verification in process
  def self.calculate_first_entrance(unitary_price, quantity_action, variant_id)
    variant = ProductNatureVariant.find(variant_id)
    if variant.current_stock.zero?
      amount = quantity_action * unitary_price
      average_cost_amount = amount / quantity_action
    else
      quantity_new = variant.current_stock + quantity_action
      amount = quantity_action * unitary_price
      average_cost_amount = amount / quantity_new
    end
    product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, average_cost_amount: average_cost_amount, variant_id: variant_id)
    product_nature_variant_valuing.save
    variant = ProductNatureVariant.where(id: variant_id)
    new_info = {}
    new_info[:valuing_id] = product_nature_variant_valuing.id
    variant.last.update(new_info)
  end

  def self.calculate_output(unitary_price, quantity_new, quantity_action, variant_id)
    old_product_nature_variant_valuing = ProductNatureVariantValuing.where(variant: variant_id).last
    old_amount = old_product_nature_variant_valuing.amount
    amount = old_amount + quantity_action * unitary_price
    average_cost_amount = amount / quantity_new
    product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, average_cost_amount: average_cost_amount, variant_id: variant_id)
    product_nature_variant_valuing.save
    # update, if the variant are many products saved
    variant = ProductNatureVariant.where(id: variant_id)
    new_info = {}
    new_info[:valuing_id] = product_nature_variant_valuing.id

    variant.last.update(new_info)
  end

  def self.calculate_input(quantity_new, quantity_action, variant_id)
    old_product_nature_variant_valuing = ProductNatureVariantValuing.where(variant_id: variant_id).last
    old_amount = old_product_nature_variant_valuing.amount
    old_average_cost_amount = old_product_nature_variant_valuing.average_cost_amount

    amount = old_amount - quantity_action * old_average_cost_amount
    average_cost_amount = amount / quantity_new

    product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, average_cost_amount: average_cost_amount, variant_id: variant_id)
    product_nature_variant_valuing.save
  end

  def self.calculate_inventory(quantity_entry, variant_id)
    old_product_nature_variant_valuing = ProductNatureVariantValuing.where(variant_id: variant_id).last
    old_average_cost_amount = old_product_nature_variant_valuing.average_cost_amount

    amount = quantity_entry * old_average_cost_amount
    average_cost_amount = amount / quantity_entry

    product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, average_cost_amount: average_cost_amount, variant_id: variant_id)
    product_nature_variant_valuing.save
  end
end
