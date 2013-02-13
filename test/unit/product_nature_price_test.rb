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
# == Table: product_nature_prices
#
#  active            :boolean          default(TRUE), not null
#  amount            :decimal(19, 4)   not null
#  by_default        :boolean          default(TRUE)
#  category_id       :integer          
#  created_at        :datetime         not null
#  creator_id        :integer          
#  currency          :string(3)        
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  pretax_amount     :decimal(19, 4)   not null
#  product_nature_id :integer          not null
#  started_at        :datetime         
#  stopped_at        :datetime         
#  supplier_id       :integer          
#  tax_id            :integer          not null
#  updated_at        :datetime         not null
#  updater_id        :integer          
#


require 'test_helper'

class ProductNaturePriceTest < ActiveSupport::TestCase

  # Test if the historic is preserved on updates
  def test_update
    price = prices(:prices_001)
    count = Price.count
    assert !count.zero?

    # Update
    id, pretax_amount = price.id, price.pretax_amount
    price.pretax_amount = pretax_amount + 50
    saved = price.update
    assert saved, "Price must be saved (#{price.errors.inspect})"
    assert_equal count + 1, Price.count
    assert price.stopped_at.nil?
    old_price = nil
    assert_nothing_raised do
      old_price = Price.find(id)
    end
    assert_equal pretax_amount, old_price.pretax_amount
    assert_nothing_raised do
      saved.reload
    end
    assert_not_equal id, saved.id, "Old ID and new ID must be different"
  end

  # Test if the historic is preserved on destructions
  def test_destroy
    price = prices(:prices_003)
    count = Price.count
    assert !count.zero?

    # Destroy
    price.pretax_amount = 158.20
    assert price.save
    assert_equal count + 1, Price.count
    assert price.stopped_at.nil?
    id = price.id
    assert price.destroy
    assert_equal count + 1, Price.count
    assert_nothing_raised do
      Price.find(id)
    end
    assert_nothing_raised do
      price.reload
    end
    assert !price.stopped_at.nil?, "Price stopped_at must be updated if price is deleted"
  end
end
