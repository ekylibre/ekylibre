# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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
# == Table: sales
#
#  accounted_at                             :datetime
#  address_id                               :integer
#  affair_id                                :integer
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  annotation                               :text
#  client_id                                :integer          not null
#  codes                                    :jsonb
#  conclusion                               :text
#  confirmed_at                             :datetime
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  credit                                   :boolean          default(FALSE), not null
#  credited_sale_id                         :integer
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer
#  description                              :text
#  downpayment_amount                       :decimal(19, 4)   default(0.0), not null
#  expiration_delay                         :string
#  expired_at                               :datetime
#  function_title                           :string
#  has_downpayment                          :boolean          default(FALSE), not null
#  id                                       :integer          not null, primary key
#  initial_number                           :string
#  introduction                             :text
#  invoice_address_id                       :integer
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer
#  letter_format                            :boolean          default(TRUE), not null
#  lock_version                             :integer          default(0), not null
#  nature_id                                :integer
#  number                                   :string           not null
#  payment_at                               :datetime
#  payment_delay                            :string           not null
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_journal_entry_id :integer
#  reference_number                         :string
#  responsible_id                           :integer
#  state                                    :string           not null
#  subject                                  :string
#  transporter_id                           :integer
#  undelivered_invoice_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#

require 'test_helper'

class SaleTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  setup do
    @variant = ProductNatureVariant.import_from_nomenclature(:carrot)
  end

  test 'rounds' do
    nature = SaleNature.find_or_create_by(currency: 'EUR')
    assert nature
    client = Entity.normal.first
    assert client
    sale = Sale.create!(nature: nature, client: client, invoiced_at: DateTime.new(2018, 1, 1))
    assert sale
    variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))
    # Standard case
    standard_vat = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45661'),
      deduction_account: Account.find_or_create_by_number('45671'),
      country: :fr
    )
    first_item = sale.items.create!(variant: variants.first, quantity: 4, unit_pretax_amount: 100, tax: standard_vat)
    assert first_item
    assert_equal 480, first_item.amount
    assert_equal 480, sale.amount
    # Limit case
    reduced_vat = Tax.create!(
      name: 'Reduced',
      amount: 5.5,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45662'),
      deduction_account: Account.find_or_create_by_number('45672'),
      country: :fr
    )
    second_item = sale.items.create!(variant: variants.second, quantity: 4, unit_pretax_amount: 3.791, tax: reduced_vat)
    assert second_item
    assert_equal 16, second_item.amount
    assert_equal 496, sale.amount

    assert sale.propose!
    assert sale.confirm!
    assert sale.invoice!

    sale.reload
    entry = sale.journal_entry

    assert entry.present?, 'Journal entry must be present after invoicing'

    assert_equal 5, entry.items.count
    assert 80.0, entry.items.find_by(account_id: standard_vat.collect_account_id).credit
    assert 400.0, entry.items.find_by(account_id: first_item.account_id).credit
    assert 0.84, entry.items.find_by(account_id: reduced_vat.collect_account_id).credit
    assert 15.16, entry.items.find_by(account_id: second_item.account_id).credit
    assert 496, entry.items.find_by(account_id: client.account(:client).id).debit
  end

  test 'unit pretax amount calculation based on total pretax amount' do
    nature = SaleNature.first
    assert nature
    sale = Sale.create!(nature: nature, client: Entity.normal.first)
    assert sale
    variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))
    tax = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('4566'),
      deduction_account: Account.find_or_create_by_number('4567'),
      country: :fr
    )
    # Calculates unit_pretax_amount based on pretax_amount
    item = sale.items.create!(variant: variants.first, quantity: 2, pretax_amount: 225, tax: tax, compute_from: 'pretax_amount')
    assert item
    assert_equal 112.50, item.unit_pretax_amount
    assert_equal 270, item.amount
  end

  test 'duplicatablity' do
    count = 0
    Sale.find_each do |sale|
      if sale.duplicatable?
        sale.duplicate
        count += 1
      end
    end
    assert count > 0, 'No sale has been duplicated for test'
  end

  test 'default_currency is nature\'s currency if currency is not specified' do
    Payslip.delete_all
    Catalog.delete_all
    SaleNature.delete_all
    OutgoingPayment.delete_all
    Entity.delete_all
    Sale.delete_all

    catalog = Catalog.create!(code: 'food', name: 'Noncontaminated produce')
    nature = SaleNature.create!(currency: 'EUR', name: 'Perishables', catalog: catalog, journal: Journal.find_by_nature('sales'))
    max = Entity.create!(first_name: 'Max', last_name: 'Rockatansky', nature: :contact)
    with = Sale.create!(client: max, nature: nature, currency: 'USD')
    without = Sale.create!(client: max, nature: nature)

    assert_equal 'USD', with.default_currency
    assert_equal 'EUR', without.default_currency
  end

  test 'affair_class points to correct class' do
    assert_equal SaleAffair, Sale.affair_class
  end

  test 'Test variant specified when bookkeep' do
    nature = SaleNature.first
    standard_vat = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45661'),
      deduction_account: Account.find_or_create_by_number('45671'),

      country: :fr
    )

    sale = Sale.create!(nature: nature, client: Entity.normal.first, state: :order, invoiced_at: DateTime.new(2018, 1, 1))
    sale.items.create!(variant: @variant, quantity: 4, unit_pretax_amount: 100, tax: standard_vat)
    sale.reload

    assert sale.invoice

    journal_entry_items = sale.journal_entry.items
    account_ids = journal_entry_items.pluck(:account_id)

    sale_account = Account.where(id: account_ids).where("number LIKE '7%'").first
    jei_s = journal_entry_items.where(account_id: sale_account.id).first

    # jei_s variant must be defined
    assert_not jei_s.variant.nil?
    assert_equal jei_s.variant, @variant
  end

  test 'Cannot create a sale during a financial year exchange' do
    FinancialYear.delete_all
    financial_year = create(:financial_year, started_on: Date.today.beginning_of_year, stopped_on: Date.today.end_of_year)
    exchange = FinancialYearExchange.create(financial_year: financial_year, stopped_on: Date.today - 2.day)
    assert create(:sale, invoiced_at: Date.today - 1.day)
    assert_raises ActiveRecord::RecordInvalid do
      create(:sale, invoiced_at: Date.today - 3.day)
    end
  end

  test 'A sale with state :order can have its invoice date changed' do
    sale = create :sale, amount: 5000, items: 1

    assert sale.propose
    assert sale.confirm

    assert sale.order?
    assert sale.update invoiced_at: Time.parse("2018-05-08T10-25-52Z")
  end

  test 'A sale with state :order can have its items changed' do
    # case direct sale on market for farmer like AMAP and ci
    nature = SaleNature.find_or_create_by(currency: 'EUR')
    assert nature

    client = Entity.normal.first
    assert client

    sale = Sale.create!(nature: nature, client: client, invoiced_at: DateTime.new(2018, 1, 1))
    assert sale

    standard_vat = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45661'),
      deduction_account: Account.find_or_create_by_number('45671'),
      country: :fr
    )
    item = sale.items.create!(variant: @variant, quantity: 4, unit_pretax_amount: 10, tax: standard_vat)

    assert sale.propose!
    assert sale.confirm!
    assert sale.order?
    assert_equal 48, sale.amount

    # sale order must have an draft entry updateable
    entry = sale.journal_entry
    assert 48, entry.items.find_by(account_id: client.account(:client).id).debit
    assert 40, entry.items.find_by(account_id: item.account_id).credit

    item.update(quantity: 8)
    assert sale.update invoiced_at: Time.parse("2018-05-08T10-25-52Z")

    sale.reload

    assert_equal 96, sale.amount
    assert sale.invoice!

    sale.reload

    # sale invoice must have an entry up to date
    assert 96, entry.items.find_by(account_id: client.account(:client).id).debit
    assert 80, entry.items.find_by(account_id: item.account_id).credit
  end
end
