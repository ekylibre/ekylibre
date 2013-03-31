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
# == Table: product_price_templates
#
#  active                            :boolean          default(TRUE), not null
#  amounts_scale                     :integer          default(2), not null
#  assignment_amount                 :decimal(19, 4)
#  assignment_pretax_amount          :decimal(19, 4)
#  by_default                        :boolean          default(TRUE)
#  created_at                        :datetime         not null
#  creator_id                        :integer
#  currency                          :string(3)
#  id                                :integer          not null, primary key
#  listing_id                        :integer
#  lock_version                      :integer          default(0), not null
#  pretax_amount_calculation_formula :text
#  pretax_amount_generation          :string(32)
#  product_nature_id                 :integer          not null
#  started_at                        :datetime
#  stopped_at                        :datetime
#  supplier_id                       :integer
#  tax_id                            :integer          not null
#  updated_at                        :datetime         not null
#  updater_id                        :integer
#


require 'test_helper'

class ProductPriceTemplateTest < ActiveSupport::TestCase

  # Test if the historic is preserved on updates
  test "update" do
    template = product_price_templates(:product_price_templates_001)
    count = ProductPriceTemplate.count
    assert !count.zero?

    # Update
    id, pretax_amount = template.id, template.pretax_amount
    template.pretax_amount = pretax_amount + 50
    saved = template.update
    assert saved, "Template must be saved (#{template.errors.inspect})"
    assert_equal count + 1, ProductPriceTemplate.count
    assert template.stopped_at.nil?
    old_template = nil
    assert_nothing_raised do
      old_template = ProductPriceTemplate.find(id)
    end
    assert_equal pretax_amount, old_template.pretax_amount
    assert_nothing_raised do
      saved.reload
    end
    assert_not_equal id, saved.id, "Old ID and new ID must be different"
  end

  # Test if the historic is preserved on destructions
  test "destruction" do
    template = product_price_templates(:product_price_templates_003)
    count = ProductPriceTemplate.count
    assert !count.zero?

    # Destroy
    template.pretax_amount = 158.20
    assert template.save
    assert_equal count + 1, ProductPriceTemplate.count
    assert template.stopped_at.nil?
    id = template.id
    assert template.destroy
    assert_equal count + 1, ProductPriceTemplate.count
    assert_nothing_raised do
      ProductPriceTemplate.find(id)
    end
    assert_nothing_raised do
      template.reload
    end
    assert !template.stopped_at.nil?, "ProductPriceTemplate stopped_at must be updated if template is deleted"
  end
end
