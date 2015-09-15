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
# == Table: parcels
#
#  address_id        :integer
#  created_at        :datetime         not null
#  creator_id        :integer
#  delivery_id       :integer
#  delivery_mode     :string
#  given_at          :datetime
#  id                :integer          not null, primary key
#  in_preparation_at :datetime
#  lock_version      :integer          default(0), not null
#  nature            :string           not null
#  net_mass          :decimal(19, 4)
#  number            :string           not null
#  ordered_at        :datetime
#  planned_at        :datetime
#  position          :integer
#  prepared_at       :datetime
#  purchase_id       :integer
#  recipient_id      :integer
#  reference_number  :string
#  remain_owner      :boolean          default(FALSE), not null
#  sale_id           :integer
#  sender_id         :integer
#  state             :string           not null
#  storage_id        :integer
#  transporter_id    :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#

require 'test_helper'

class ParcelTest < ActiveSupport::TestCase
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
    parcel.items.map(&:net_mass)
  end

  test 'incoming items' do
    assert_raise ActiveRecord::RecordInvalid do
      Parcel.create!
    end
    assert_raise ActiveRecord::RecordInvalid do
      Parcel.create!(nature: :incoming)
    end

    storage = products(:building_divisions_003)
    parcel = Parcel.create!(nature: :incoming, sender: entities(:entities_016), storage: storage)

    source_product = products(:matters_007)
    parcel.items.create!(source_product: source_product)
    parcel.order!
    parcel.prepare!
    parcel.check!
    assert_raise StateMachine::InvalidTransition do
      parcel.give!
    end

    delivery = Delivery.create!(parcel_ids: [parcel.id])

    parcel.reload
    product = parcel.items.first.product
    assert_equal source_product, product

    delivery.order!
    delivery.prepare!
    delivery.check!
    delivery.start!
    delivery.reload
    delivery.finish!
    product.reload
    assert_equal storage, product.current_localization.container
    assert_equal :own, product.current_enjoyment.nature.to_sym, 'All enjoyments: ' + product.enjoyments.order(:started_at).collect { |e| "#{e.started_at.l}: #{e.nature} (#{e.enjoyer_id})" }.join(', ')
    assert_equal :own, product.current_ownership.nature.to_sym, 'All ownerships: ' + product.ownerships.order(:started_at).collect { |e| "#{e.started_at.l}: #{e.nature} (#{e.owner_id})" }.join(', ')
  end

  test 'parted outgoing items' do
    assert_raise ActiveRecord::RecordInvalid do
      Parcel.create!
    end
    assert_raise ActiveRecord::RecordInvalid do
      Parcel.create!(nature: :outgoing)
    end

    storage = products(:building_divisions_003)
    parcel = Parcel.create!(nature: :outgoing, recipient: entities(:entities_016), address: entity_addresses(:entity_addresses_016), remain_owner: true)

    source_product = products(:matters_007)
    old_ownership_nature = source_product.current_ownership.nature.to_sym
    parcel.items.create!(source_product: source_product, parted: true, population: 15)
    parcel.order!
    parcel.prepare!
    parcel.check!
    item = parcel.items.first
    assert_equal 15, item.product.population
    assert_raise StateMachine::InvalidTransition do
      parcel.give!
    end

    delivery = Delivery.create!(parcel_ids: [parcel.id])

    parcel.reload
    product = item.product
    assert_not_equal source_product, product
    assert_equal source_product.variant, product.variant

    delivery.order!
    delivery.prepare!
    delivery.check!
    delivery.start!
    delivery.reload
    delivery.finish!
    product.reload
    assert_equal :exterior, product.current_localization.nature.to_sym, 'All localizations: ' + product.localizations.order(:started_at).collect { |e| "#{e.started_at.l}: #{e.nature} (#{e.container_id})" }.join(', ')
    assert_equal :other, product.current_enjoyment.nature.to_sym, 'All enjoyments: ' + product.enjoyments.order(:started_at).collect { |e| "#{e.started_at.l}: #{e.nature} (#{e.enjoyer_id})" }.join(', ')
    assert_equal old_ownership_nature, product.current_ownership.nature.to_sym, 'All ownerships: ' + product.ownerships.order(:started_at).collect { |e| "#{e.started_at.l}: #{e.nature} (#{e.owner_id})" }.join(', ')
  end
end
