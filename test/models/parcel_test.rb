# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  accounted_at                         :datetime
#  address_id                           :integer
#  contract_id                          :integer
#  created_at                           :datetime         not null
#  creator_id                           :integer
#  currency                             :string
#  custom_fields                        :jsonb
#  delivery_id                          :integer
#  delivery_mode                        :string
#  given_at                             :datetime
#  id                                   :integer          not null, primary key
#  in_preparation_at                    :datetime
#  intervention_id                      :integer
#  journal_entry_id                     :integer
#  late_delivery                        :boolean
#  lock_version                         :integer          default(0), not null
#  nature                               :string           not null
#  number                               :string           not null
#  ordered_at                           :datetime
#  planned_at                           :datetime         not null
#  position                             :integer
#  prepared_at                          :datetime
#  pretax_amount                        :decimal(19, 4)   default(0.0), not null
#  purchase_id                          :integer
#  recipient_id                         :integer
#  reconciliation_state                 :string
#  reference_number                     :string
#  remain_owner                         :boolean          default(FALSE), not null
#  responsible_id                       :integer
#  sale_id                              :integer
#  sender_id                            :integer
#  separated_stock                      :boolean
#  state                                :string           not null
#  storage_id                           :integer
#  transporter_id                       :integer
#  type                                 :string
#  undelivered_invoice_journal_entry_id :integer
#  updated_at                           :datetime         not null
#  updater_id                           :integer
#  with_delivery                        :boolean          default(FALSE), not null
#

require 'test_helper'

class ParcelTest < ActiveSupport::TestCase
  test_model_actions

  setup do
    @variant = ProductNatureVariant.import_from_nomenclature(:carrot)
    @entity = Entity.create!(last_name: 'Parcel test')
    @address = @entity.addresses.create!(canal: 'mail', mail_line_1: 'Yolo', mail_line_2: 'Another test')

    @building_division_variant = ProductNatureVariant.import_from_nomenclature(:building_division)
    @storage = BuildingDivision.create!(
      variant: @building_division_variant,
      name: 'Parcel Test Stockage',
      initial_shape: Charta.new_geometry('SRID=4326;MULTIPOLYGON(((-0.813218951225281 45.5985699786537,-0.813113003969193 45.5985455816635,-0.81300538033247 45.5987766488858,-0.813106298446655 45.5987876744046,-0.813218951225281 45.5985699786537)))')
    )
    Preference.set!('permanent_stock_inventory', true)
  end

  test 'ship giving a transporter' do
    new_parcel
    assert_nothing_raised { Parcel.ship(Parcel.all, transporter_id: @entity.id) }
  end

  test 'ship without transporter' do
    new_parcel
    assert_raise { Parcel.ship(Parcel.all) }
  end

  # ???? TODO: Figure what that test was supposed to be
  test 'prevent empty items' do
    item = parcel_items(:parcel_items_001).attributes.slice('product_id', 'population', 'shape')
    Parcel.new items_attributes: { '123456789' => { 'product_id' => '', '_destroy' => 'false' }, '852' => item }
    # parcel.items.map(&:net_mass)
  end

  test 'incoming items with separated stock' do
    @variant.products.create!(
      initial_container: @storage,
      initial_population: 50
    )
    parcel = new_parcel
    parcel.give!
    @variant.reload

    assert_equal 2, @variant.products.count
    assert_equal 20, @variant.products.order(:created_at).last.population
  end

  test 'incoming items with grouped stock' do
    @variant.products.create!(
      initial_container: @storage,
      initial_population: 50
    )
    parcel = new_parcel(separated: false)
    parcel.give!

    @variant.reload

    assert_equal 1, @variant.products.count
    assert_equal 50 + 20, @variant.products.order(:created_at).first.population
  end

  test 'outgoing parcels' do
    product = @variant.products.create!(initial_population: 30)
    to_send = [{
      population: product.population,
      source_product: product
    }]

    parcel = new_parcel(nature: :outgoing, items_attributes: to_send)
    parcel.give!

    assert_equal 0, product.population
  end

  # bookkeep on incoming
  test 'bookeep incoming items with separated stock' do
    @variant.products.create!(
      initial_container: @storage,
      initial_population: 50
    )

    # must have permanent_stock_inventory preference
    assert_equal true, Preference.value('permanent_stock_inventory')

    # must have stock_account on variant
    assert_operator 0, :<, @variant.stock_account_id
    assert_operator 0, :<, @variant.stock_movement_account_id

    parcel = new_parcel
    parcel.give!
    @variant.reload

    a_ids = parcel.journal_entry.items.pluck(:account_id)

    sm = Account.where(id: a_ids).where("number LIKE '6%'").first
    sm ||= Account.where(id: a_ids).where("number LIKE '7%'").first
    jei_sm = parcel.journal_entry.items.where(account_id: sm.id).first

    s = Account.where(id: a_ids).where("number LIKE '3%'").first
    jei_s = parcel.journal_entry.items.where(account_id: s.id).first

    # must have 0 on credit to S ACCOUNT (3%)
    assert_equal 0, jei_s.credit.to_i
    assert_equal 0, jei_s.real_credit.to_i

    # must have GTZ on debit to S ACCOUNT (3%)
    assert_operator 0, :<, jei_s.debit.to_i
    assert_operator 0, :<, jei_s.real_debit.to_i

    # must have 0 on débit to SM ACCOUNT (6%)
    assert_equal 0, jei_sm.debit.to_i
    assert_equal 0, jei_sm.real_debit.to_i

    # must have GTZ on credit to SM ACCOUNT (6%)
    assert_operator 0, :<, jei_sm.credit.to_i
    assert_operator 0, :<, jei_sm.real_credit.to_i

    # jei_s variant must be defined
    assert_not jei_s.variant.nil?
    assert_equal jei_s.variant, @variant

    # jei_sm variant must be defined
    assert_not jei_sm.variant.nil?
    assert_equal jei_sm.variant, @variant
  end

  # bookkeep on outgoing
  test 'bookeep outgoing parcels' do
    product = @variant.products.create!(initial_population: 30)
    to_send = [{
      population: product.population,
      source_product: product,
      unit_pretax_stock_amount: 15
    }]

    parcel = new_parcel(nature: :outgoing, items_attributes: to_send)
    parcel.give!

    a_ids = parcel.journal_entry.items.pluck(:account_id)

    sm = Account.where(id: a_ids).where("number LIKE '6%'").first
    sm ||= Account.where(id: a_ids).where("number LIKE '7%'").first
    jei_sm = parcel.journal_entry.items.where(account_id: sm.id).first

    s = Account.where(id: a_ids).where("number LIKE '3%'").first
    jei_s = parcel.journal_entry.items.where(account_id: s.id).first

    # must have 0 on credit to SM ACCOUNT (6%)
    assert_equal 0, jei_sm.credit.to_i
    assert_equal 0, jei_sm.real_credit.to_i
    # must have GTZ on debit to SM ACCOUNT (6%)
    assert_operator 0, :<, jei_sm.debit.to_i
    assert_operator 0, :<, jei_sm.real_debit.to_i

    # must have 0 on débit to S ACCOUNT (3%)
    assert_equal 0, jei_s.debit.to_i
    assert_equal 0, jei_s.real_debit.to_i
    # must have GTZ on credit to S ACCOUNT (3%)
    assert_operator 0, :<, jei_s.credit.to_i
    assert_operator 0, :<, jei_s.real_credit.to_i
  end

  test 'unitary items in parcels' do
    unitary_variant = ProductNatureVariant.import_from_nomenclature(:female_adult_cow, true)
    unitary_variant.products.create!(
      initial_container: @storage,
      initial_population: 1
    )
    to_send = [{
      population: 1,
      variant: unitary_variant,
      product_name: 'Moo',
      product_identification_number: 'Cow-wow'
    }]

    parcel = new_parcel(items_attributes: to_send, separated: false)
    parcel.give!
    unitary_variant.reload

    assert_equal 2, unitary_variant.products.count
    assert_equal 1, unitary_variant.products.order(:created_at).last.population
  end

  private

  def new_parcel(nature: :incoming, delivery_mode: :third, address: nil, entity: nil, storage: nil, separated: true, items_attributes: nil)
    attributes = {
      nature: nature,
      delivery_mode: delivery_mode,
      address: address || @address,
      sender: entity || @entity,
      recipient: entity || @entity,
      storage: storage || @storage,
      separated_stock: separated
    }

    items_attributes ||= [{
      population: 20,
      unit_pretax_stock_amount: 15,
      variant: @variant
    }]

    p = Parcel.create!(attributes)
    items_attributes.each do
      p.items.create!(items_attributes)
    end

    p
  end
end
