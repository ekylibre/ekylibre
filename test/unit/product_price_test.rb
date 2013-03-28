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
#  amount                  :decimal(19, 4)   not null
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string(255)      not null
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  pretax_amount           :decimal(19, 4)   not null
#  product_id              :integer          not null
#  product_nature_price_id :integer
#  started_at              :datetime
#  supplier_id             :integer          not null
#  tax_id                  :integer
#  updated_at              :datetime         not null
#  updater_id              :integer
#
require 'test_helper'

class ProductPriceTest < ActiveSupport::TestCase

  test "presence of fixtures" do
    # assert_equal 2, ProductPrice.count
  end

end
