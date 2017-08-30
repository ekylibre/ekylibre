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
#  amount              :decimal(19, 4)   not null
#  average_cost_amount :decimal(19, 4)   not null
#  computed_at         :datetime         not null
#  created_at          :datetime         not null
#  creator_id          :integer
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#  variant_id          :integer          not null
#

class ProductNatureVariantValuing < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :amount, :average_cost_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :computed_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :variant, presence: true
  # ]VALIDATORS]
  belongs_to :variant, class_name: 'ProductNatureVariant'

  validates :average_cost_amount, :amount, presence: true
  validates :average_cost_amount, :amount, numericality: true
  # some logical, verification in process
  def self.calculate_first_entrance(unit_price_amount, new_quantity, action_quantity, variant_id)
    amount = action_quantity * unit_price_amount
    average_cost_amount = amount / new_quantity
    product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, average_cost_amount: average_cost_amount, variant_id: variant_id, computed_at: Time.now)
    product_nature_variant_valuing.save
    # update, needed to stay up to date with variant
    product_nature_variant_valuing.update_variant(variant_id, product_nature_variant_valuing.id)
    product_nature_variant_valuing
  end

  def self.calculate_output(unit_price_amount, new_quantity, action_quantity, variant_id)
    old_product_nature_variant_valuing = ProductNatureVariantValuing.where(variant: variant_id).last
    old_amount = old_product_nature_variant_valuing.amount
    amount = old_amount + action_quantity * unit_price_amount
    average_cost_amount = amount / new_quantity
    product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, average_cost_amount: average_cost_amount, variant_id: variant_id, computed_at: Time.now)
    product_nature_variant_valuing.save
    # update, needed to stay up to date with variant
    product_nature_variant_valuing.update_variant(variant_id, product_nature_variant_valuing.id)
    product_nature_variant_valuing
  end

  def self.calculate_input(new_quantity, action_quantity, variant_id)
    old_product_nature_variant_valuing = ProductNatureVariantValuing.where(variant: variant_id).last
    if old_product_nature_variant_valuing.nil?
      old_amount = 0
      old_average_cost_amount = 0
    else
      old_amount = old_product_nature_variant_valuing.amount
      old_average_cost_amount = old_product_nature_variant_valuing.average_cost_amount
    end
    amount = old_amount - action_quantity * old_average_cost_amount
    average_cost_amount = amount / new_quantity
    product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, average_cost_amount: average_cost_amount, variant_id: variant_id, computed_at: Time.now)
    product_nature_variant_valuing.save
    # update, needed to stay up to date with variant
    product_nature_variant_valuing.update_variant(variant_id, product_nature_variant_valuing.id)
    product_nature_variant_valuing
  end

  def self.calculate_inventory(quantity_entry, variant_id)
    old_product_nature_variant_valuing = ProductNatureVariantValuing.where(variant: variant_id).last
    if old_product_nature_variant_valuing.nil?
      old_average_cost_amount = 0
    else
      old_average_cost_amount = old_product_nature_variant_valuing.average_cost_amount
    end
    amount = quantity_entry * old_average_cost_amount
    average_cost_amount = amount / quantity_entry
    product_nature_variant_valuing = ProductNatureVariantValuing.new(amount: amount, average_cost_amount: average_cost_amount, variant_id: variant_id, computed_at: Time.now)
    product_nature_variant_valuing.save
    # update, needed to stay up to date with variant
    product_nature_variant_valuing.update_variant(variant_id, product_nature_variant_valuing.id)
    product_nature_variant_valuing
  end

  def self.rollback_valuing(variant_id)
    valuing = ProductNatureVariantValuing.where(variant_id: variant_id)
    valuing = valuing.last(2).first
    if valuing.nil?

    else
      valuing.reload
      valuing.update_variant(variant_id, valuing.id).reload
      valuing.reload
      val = ProductNatureVariantValuing.where(variant_id: variant_id)
      val = val.last
      val.reload
      val.destroy
    end
  end

  def update_variant(variant_id, valuing_id)
    variant = ProductNatureVariant.find(variant_id)
    new_info = {}
    new_info[:valuing_id] = valuing_id
    variant.update(new_info)
    variant
  end
end
