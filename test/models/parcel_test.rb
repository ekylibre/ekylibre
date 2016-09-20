# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: parcels
#
#  accounted_at                 :datetime
#  address_id                   :integer
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  currency                     :string
#  custom_fields                :jsonb
#  delivery_id                  :integer
#  delivery_mode                :string
#  given_at                     :datetime
#  id                           :integer          not null, primary key
#  in_preparation_at            :datetime
#  journal_entry_id             :integer
#  lock_version                 :integer          default(0), not null
#  nature                       :string           not null
#  number                       :string           not null
#  ordered_at                   :datetime
#  planned_at                   :datetime         not null
#  position                     :integer
#  prepared_at                  :datetime
#  purchase_id                  :integer
#  recipient_id                 :integer
#  reference_number             :string
#  remain_owner                 :boolean          default(FALSE), not null
#  sale_id                      :integer
#  sender_id                    :integer
#  separated_stock              :boolean
#  state                        :string           not null
#  storage_id                   :integer
#  transporter_id               :integer
#  undelivered_invoice_entry_id :integer
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  with_delivery                :boolean          default(FALSE), not null
#

require 'test_helper'

class ParcelTest < ActiveSupport::TestCase
  test_model_actions
  test 'ship giving a transporter' do
    Parcel.ship(Parcel.all, transporter_id: entities(:entities_001).id)
  end

  test 'ship without transporter' do
    assert_raise StandardError do
      Parcel.ship(Parcel.all)
    end
  end

  test 'prevent empty items' do
    item = parcel_items(:parcel_items_001).attributes.slice('product_id', 'population', 'shape')
    parcel = Parcel.new items_attributes: { '123456789' => { 'product_id' => '', '_destroy' => 'false' }, '852' => item }
    # parcel.items.map(&:net_mass)
  end

  test 'incoming items with separated stock' do
    variant = product_nature_variants(:product_nature_variants_009)
    pre_num_of_products = variant.products.count

    parcel_attributes = {
      nature: :incoming,
      delivery_mode: :third,
      address: entity_addresses(:entity_addresses_016),
      sender: entities(:entities_001),
      storage: products(:building_divisions_003),
      separated_stock: true
    }

    parcel_items_attributes = {
      population: 20,
      variant: variant
    }

    p = Parcel.create!(parcel_attributes)

    p.items.create!(parcel_items_attributes)

    p.order!
    p.prepare!
    p.check!
    p.give!

    variant.reload
    post_num_of_products = variant.products.count

    # Should have created a new product.
    assert_equal(pre_num_of_products + 1, post_num_of_products, <<-PRODUCT_NOT_IN_STOCK)

    \tCurrently in stock :
    \t - First product:
    \t\t#{variant.products.first.name}
    \t - Last product:
    \t\t#{variant.products.last.name}
    \t - All products :
    #{variant.products.map(&:name).reduce('') { |a, s| a + "\t\t" + s.inspect + "\n" }}

    \tNew products that should be in it :
    #{p.items.map(&:product).map(&:name).reduce('') { |a, s| a + "\t\t" + s.inspect + "\n" }}
    PRODUCT_NOT_IN_STOCK

    # The newly created product should have the population specified in the parcel.
    assert_equal(variant.products.order(:id).last.population, p.items.first.population, <<-WRONG_POPULATION)

    \tLast item in stock's population :
    \t\t#{variant.products.last.population}
    \tPopulation that was in the parcel :
    \t\t#{p.items.first.population}
    WRONG_POPULATION
  end

  test 'incoming items with grouped stock' do
    variant = product_nature_variants(:product_nature_variants_048)
    # Making sure we have someone to group up with.
    product = variant.products.first
    storage = product.localizations.last.container

    pre_stock = variant.products.first.population
    pre_num_of_products = variant.products.count

    parcel_attributes = {
      nature: :incoming,
      delivery_mode: :third,
      address: entity_addresses(:entity_addresses_016),
      sender: entities(:entities_001),
      storage: storage,
      separated_stock: false
    }

    parcel_items_attributes = {
      population: 20,
      variant: variant
    }

    p = Parcel.create!(parcel_attributes)

    p.items.create!(parcel_items_attributes)

    p.order!
    p.prepare!
    p.check!
    p.give!

    variant.reload
    post_stock = p.items.first.product.population
    post_num_of_products = variant.products.count

    # Should have grouped up and as such incremented the existing product population.
    assert_equal(pre_stock + 20, post_stock, <<-WRONG_POPULATION)

    \tCurrently in stock :
    \t - All products : \t(Expected: #{pre_stock + 20} - Actual: #{post_stock})
    #{variant.products.reduce('') { |a, p| a + "\t\t" + p.name.inspect + ":\t" + p.population.to_s + "\n" }}

    \tProducts that should have gotten in through the Parcel :
    #{p.items.map(&:product).reduce('') { |a, p| a + "\t\t" + p.name.inspect + ":\t" + p.population.to_s + "\n" }}
    WRONG_POPULATION

    # Should've grouped up and as such not incremented the number of products.
    assert_equal(pre_num_of_products, post_num_of_products, <<-TOO_MANY_PRODUCTS)

    \tCurrently in stock :
    \t - Product it should have merged with:
    \t\t#{product}
    \t - Product in the parcel:
    \t\t#{p.items.first.product}
    \t - All products :
    #{variant.products.map(&:name).reduce('') { |a, s| a + "\t\t" + s.inspect + "\n" }}
    TOO_MANY_PRODUCTS
  end

  test 'outgoing parcels' do
    product = products(:matters_017)

    parcel_attributes = {
      nature: :outgoing,
      address: entity_addresses(:entity_addresses_016),
      recipient: entities(:entities_001),
      delivery_mode: :third
    }

    parcel_items_attributes = {
      population: product.population,
      source_product: product
    }

    p = Parcel.create!(parcel_attributes)

    p.items.create!(parcel_items_attributes)

    p.order!
    p.prepare!
    p.check!
    p.give!

    # Should've sent all of them
    assert_equal(0, product.population, <<-POPULATION_NOT_NULL)

    \tCurrent product population (should be 0) :
    \t\t#{product.population}
    POPULATION_NOT_NULL
  end

  test 'unitary items in parcels' do
    # Unitary items in incoming should always be handled like non-grouped items.

    variant = product_nature_variants(:product_nature_variants_005)
    pre_num_of_products = variant.products.count

    parcel_attributes = {
      nature: :incoming,
      delivery_mode: :third,
      address: entity_addresses(:entity_addresses_016),
      sender: entities(:entities_001),
      storage: products(:building_divisions_003)
    }

    parcel_items_attributes = {
      population: 1,
      variant: variant,
      product_name: 'Moo',
      product_identification_number: 'Cow-wow'
    }

    p = Parcel.create!(parcel_attributes)

    p.items.create!(parcel_items_attributes)

    p.order!
    p.prepare!
    p.check!
    p.give!

    variant.reload
    post_num_of_products = variant.products.count

    # Should have created a new product cause we never group unitary items.
    assert_equal(pre_num_of_products + 1, post_num_of_products, <<-PRODUCT_NOT_IN_STOCK)

    \tCurrently in stock :
    \t - First product:
    \t\t#{variant.products.first.name}
    \t - Last product:
    \t\t#{variant.products.last.name}
    \t - All products :
    #{variant.products.map(&:name).reduce('') { |a, s| a + "\t\t" + s.inspect + "\n" }}

    \tNew products that should be in it :
    #{p.items.map(&:product).map(&:name).reduce('') { |a, s| a + "\t\t" + s.inspect + "\n" }}
    PRODUCT_NOT_IN_STOCK

    # The newly created product should have the population specified in the parcel.
    assert_equal(variant.products.order(:created_at).last.population, p.items.first.population, <<-WRONG_POPULATION)

    \tLast item in stock's population :
    \t\t#{variant.products.order(:created_at).last.population}
    \tPopulation that was in the parcel :
    \t\t#{p.items.first.population}
    WRONG_POPULATION
  end
end
