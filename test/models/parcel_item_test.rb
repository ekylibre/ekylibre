# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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
# == Table: parcel_items
#
#  analysis_id                   :integer
#  created_at                    :datetime         not null
#  creator_id                    :integer
#  currency                      :string
#  id                            :integer          not null, primary key
#  lock_version                  :integer          default(0), not null
#  parcel_id                     :integer          not null
#  parted                        :boolean          default(FALSE), not null
#  population                    :decimal(19, 4)
#  pretax_amount                 :decimal(19, 4)   default(0.0), not null
#  product_enjoyment_id          :integer
#  product_id                    :integer
#  product_identification_number :string
#  product_localization_id       :integer
#  product_movement_id           :integer
#  product_name                  :string
#  product_ownership_id          :integer
#  purchase_item_id              :integer
#  sale_item_id                  :integer
#  shape                         :geometry({:srid=>4326, :type=>"multi_polygon"})
#  source_product_id             :integer
#  source_product_movement_id    :integer
#  unit_pretax_amount            :decimal(19, 4)   default(0.0), not null
#  unit_pretax_stock_amount      :decimal(19, 4)   default(0.0), not null
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#  variant_id                    :integer
#
require 'test_helper'

class ParcelItemTest < ActiveSupport::TestCase
  test_model_actions

  test "give doesn't create the dependent records if there is an exception during the process" do
    product = create(:product)
    parcel_item = create(:parcel_item, product: product, product_identification_number: '12345678', product_name: 'Product name')
    ProductMovement.destroy_all
    ProductLocalization.destroy_all
    ProductEnjoyment.stub :create!, ->(*_args) { raise } do
      begin
        parcel_item.give
      rescue
      end
      assert_empty ProductMovement.all
      assert_empty ProductLocalization.all
    end
  end

  test 'parcel_item without population give take the population of the source_product population' do
    parcel_item = create(:outgoing_parcel_item)
    assert_equal 1, parcel_item.population
  end

  test 'parcel_item with population have the given population' do
    nature = create(:product_nature, population_counting: :decimal)
    variant = create(:product_nature_variant, nature: nature)
    product = create(:product, variant: variant)
    parcel_item = create(:outgoing_parcel_item, population: 12, source_product: product)
    assert_equal 12, parcel_item.population
  end
end
