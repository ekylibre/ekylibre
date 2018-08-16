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
# == Table: tax_declarations
#
#  accounted_at      :datetime
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string           not null
#  description       :text
#  financial_year_id :integer          not null
#  id                :integer          not null, primary key
#  invoiced_on       :date
#  journal_entry_id  :integer
#  lock_version      :integer          default(0), not null
#  mode              :string           not null
#  number            :string
#  reference_number  :string
#  responsible_id    :integer
#  started_on        :date             not null
#  state             :string
#  stopped_on        :date             not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#
require 'test_helper'

class TaxDeclarationTest < ActiveSupport::TestCase
  test 'compute declaration with journal entry items on debit' do
    #
    # Tax: 20%
    #
    # Purchase1 (on debit, deductible)
    #    HT 1500
    #   VAT 300
    #   TTC 1800
    #
    # Purchase2 (on debit, deductible)
    #    HT 400
    #   VAT  80
    #   TTC 480
    #
    # Sale1 (on debit, collected)
    #    HT 120
    #   VAT 24
    #   TTC 144
    #
    # ======>
    #
    # Deductible
    #   tax     380 (= 300 + 80)
    #   pretax 1900 (= 1500 + 400)
    # Collected
    #   tax     24
    #   pretax 120
    #
    # Global balance
    #   -356 (= 24 - 380)

    tax = taxes(:taxes_003)

    financial_year = financial_year_in_debit_mode
    started_on = financial_year.started_on
    stopped_on = started_on.end_of_month
    printed_on = started_on + 1.day

    purchases_account = create(:account, name: 'Purchases')
    suppliers_account = create(:account, name: 'Suppliers')
    clients_account = create(:account, name: 'Clients')
    revenues_account = create(:account, name: 'Revenues')
    vat_deductible_account = tax.deduction_account
    vat_collected_account = tax.collect_account

    purchase1 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       tax_payability: 'at_invoicing')
    purchase1_item = create(:purchase_item,
                            purchase: purchase1,
                            tax: tax)
    purchase1_entry = build(:journal_entry,
                            printed_on: printed_on,
                            real_credit: 1800.0,
                            real_debit: 1800.0)
    purchase1_entry.items = [
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: suppliers_account,
            real_credit: 1800.0),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: vat_deductible_account,
            real_debit: 300.0,
            real_pretax_amount: 1500.0,
            tax: tax,
            resource: purchase1_item),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: purchases_account,
            real_debit: 1500.0)
    ]
    assert purchase1_entry.save

    purchase2 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       tax_payability: 'at_invoicing')
    purchase2_item = create(:purchase_item,
                            purchase: purchase2,
                            tax: tax)
    purchase2_entry = build(:journal_entry,
                            printed_on: printed_on,
                            real_credit: 480.0,
                            real_debit: 480.0)
    purchase2_entry.items = [
      build(:journal_entry_item,
            entry: purchase2_entry,
            account: suppliers_account,
            real_credit: 480.0),
      build(:journal_entry_item,
            entry: purchase2_entry,
            account: vat_deductible_account,
            real_debit: 80.0,
            real_pretax_amount: 400.0,
            tax: tax,
            resource: purchase2_item),
      build(:journal_entry_item,
            entry: purchase2_entry,
            account: purchases_account,
            real_debit: 400.0)
    ]
    assert purchase2_entry.save

    sale1 = create(:sale, nature: sale_natures(:sale_natures_001))
    sale1_item = create(:sale_item, sale: sale1, tax: tax)
    sale1_entry = build(:journal_entry,
                        printed_on: printed_on,
                        real_credit: 144.0,
                        real_debit: 144.0)
    sale1_entry.items = [
      build(:journal_entry_item,
            entry: sale1_entry,
            account: clients_account,
            real_debit: 144.0),
      build(:journal_entry_item,
            entry: sale1_entry,
            account: vat_collected_account,
            real_credit: 24.0,
            real_pretax_amount: 120.0,
            tax: tax,
            resource: sale1_item),
      build(:journal_entry_item,
            entry: sale1_entry,
            account: revenues_account,
            real_credit: 120.0)
    ]
    assert sale1_entry.save

    subject = build(:tax_declaration, financial_year: financial_year, started_on: started_on, stopped_on: stopped_on)
    assert subject.save

    assert_equal 'debit', purchase1_entry.items.detect { |i| i.tax == tax }.reload.tax_declaration_mode
    assert_equal 'debit', purchase2_entry.items.detect { |i| i.tax == tax }.reload.tax_declaration_mode
    assert_equal 'debit', sale1_entry.items.detect { |i| i.tax == tax }.reload.tax_declaration_mode

    subject.items.detect { |item| item.tax == tax }.tap do |tax_item|
      assert_equal 380.0, tax_item.deductible_tax_amount
      assert_equal 1900.0, tax_item.deductible_pretax_amount
      assert_equal 24.0, tax_item.collected_tax_amount
      assert_equal 120.0, tax_item.collected_pretax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_tax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_pretax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_tax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_pretax_amount
      assert_equal -356.0, tax_item.balance_tax_amount
      assert_equal -1780.0, tax_item.balance_pretax_amount

      assert_equal 3, tax_item.parts.length
      tax_item.parts.detect { |part| part.journal_entry_item.entry == purchase1_entry }.tap do |p|
        assert p
        assert_equal vat_deductible_account, p.account
        assert_equal 300.0, p.tax_amount
        assert_equal 1500.0, p.pretax_amount
        assert_equal 300.0, p.total_tax_amount
        assert_equal 1500.0, p.total_pretax_amount
        assert_equal 'deductible', p.direction
      end
      tax_item.parts.detect { |part| part.journal_entry_item.entry == purchase2_entry }.tap do |p|
        assert p
        assert_equal vat_deductible_account, p.account
        assert_equal 80.0, p.tax_amount
        assert_equal 400.0, p.pretax_amount
        assert_equal 80.0, p.total_tax_amount
        assert_equal 400.0, p.total_pretax_amount
        assert_equal 'deductible', p.direction
      end
      tax_item.parts.detect { |part| part.journal_entry_item.entry == sale1_entry }.tap do |p|
        assert p
        assert_equal vat_collected_account, p.account
        assert_equal 24.0, p.tax_amount
        assert_equal 120.0, p.pretax_amount
        assert_equal 24.0, p.total_tax_amount
        assert_equal 120.0, p.total_pretax_amount
        assert_equal 'collected', p.direction
      end
    end

    assert_equal -356, subject.global_balance
  end
  test 'compute declaration with journal entry items on debit created previously but not declared' do
    #
    # Tax: 20%
    #
    # Purchase1 (on debit, deductible)
    #    HT 1500
    #   VAT 300
    #   TTC 1800
    #
    # ======>
    #
    # Deductible
    #   tax     300
    #   pretax 1500
    #
    # Global balance
    #   -380

    tax = taxes(:taxes_003)

    financial_year = financial_year_in_debit_mode
    started_on = financial_year.started_on
    stopped_on = started_on.end_of_month
    printed_on = started_on + 1.day

    purchases_account = create(:account, name: 'Purchases')
    suppliers_account = create(:account, name: 'Suppliers')
    clients_account = create(:account, name: 'Clients')
    revenues_account = create(:account, name: 'Revenues')
    vat_deductible_account = tax.deduction_account
    vat_collected_account = tax.collect_account

    # Create declaration before the journal entry
    previous = build(:tax_declaration, financial_year: financial_year, started_on: started_on, stopped_on: stopped_on)
    assert previous.save
    assert_equal 0, previous.global_balance

    purchase1 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       tax_payability: 'at_invoicing')
    purchase1_item = create(:purchase_item,
                            purchase: purchase1,
                            tax: tax)
    purchase1_entry = build(:journal_entry,
                            printed_on: printed_on,
                            real_credit: 1800.0,
                            real_debit: 1800.0)
    purchase1_entry.items = [
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: suppliers_account,
            real_credit: 1800.0),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: vat_deductible_account,
            real_debit: 300.0,
            real_pretax_amount: 1500.0,
            tax: tax,
            resource: purchase1_item),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: purchases_account,
            real_debit: 1500.0)
    ]
    assert purchase1_entry.save

    subject = build(:tax_declaration,
                    financial_year: financial_year,
                    started_on: (started_on + 1.month).beginning_of_month,
                    stopped_on: (stopped_on + 1.month).end_of_month)
    assert subject.save
    assert_equal -300, subject.global_balance
  end
  test 'compute declaration with journal entry items on payment but without payment' do
    #
    # Tax: 20%
    #
    # Purchase1 (on payment, deductible)
    #    HT 725
    #   VAT 145
    #   TTC 870
    #
    # ======>
    #
    # Global balance 0 (no payment)

    tax = taxes(:taxes_003)

    financial_year = financial_year_in_debit_mode
    started_on = financial_year.started_on
    stopped_on = started_on.end_of_month
    printed_on = started_on + 1.day

    purchases_account = create(:account, name: 'Purchases')
    suppliers_account = create(:account, name: 'Suppliers')
    bank_account = create(:account, name: 'Brank')
    vat_deductible_account = tax.deduction_account

    purchase1 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       tax_payability: 'at_paying')
    purchase1_item = create(:purchase_item,
                            purchase: purchase1,
                            tax: tax)
    purchase1_entry = build(:journal_entry,
                            printed_on: printed_on,
                            real_credit: 870.0,
                            real_debit: 870.0)
    purchase1_entry.items = [
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: suppliers_account,
            real_credit: 870.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: vat_deductible_account,
            real_debit: 145.0,
            real_pretax_amount: 725.0,
            tax: tax,
            resource: purchase1_item),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: purchases_account,
            real_debit: 725.0)
    ]
    assert purchase1_entry.save

    subject = build(:tax_declaration, financial_year: financial_year, started_on: started_on, stopped_on: stopped_on)
    assert subject.save

    assert_equal 'payment', purchase1_entry.items.detect { |i| i.tax == tax }.reload.tax_declaration_mode

    subject.items.detect { |item| item.tax == tax }.tap do |tax_item|
      assert_equal 0, tax_item.parts.length
      assert_equal 0.0, tax_item.deductible_tax_amount
      assert_equal 0.0, tax_item.deductible_pretax_amount
      assert_equal 0.0, tax_item.collected_tax_amount
      assert_equal 0.0, tax_item.collected_pretax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_tax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_pretax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_tax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_pretax_amount
      assert_equal 0.0, tax_item.balance_tax_amount
      assert_equal 0.0, tax_item.balance_pretax_amount
    end

    assert_equal 0, subject.global_balance
  end
  test 'compute declaration with journal entry items on payment with payment but no declared' do
    #
    # Tax: 20%
    #
    # Purchase1 (on payment, deductible)
    #    HT 725
    #   VAT 145
    #   TTC 870
    #
    #   Payment1 340
    #   Payment2 60
    #
    #
    # ======>
    #
    # Deductible
    #   tax     66.67 (= 145 * (340 + 60) / 870)
    #   pretax 333.33 (= 725 * (340 + 60) / 870)
    #
    # Global balance
    #   -66.67

    tax = taxes(:taxes_003)

    financial_year = financial_year_in_debit_mode
    started_on = financial_year.started_on
    stopped_on = started_on.end_of_month
    printed_on = started_on + 1.day

    purchases_account = create(:account, name: 'Purchases')
    suppliers_account = create(:account, name: 'Suppliers')
    bank_account = create(:account, name: 'Brank')
    vat_deductible_account = tax.deduction_account

    purchase1 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       tax_payability: 'at_paying')
    purchase1_item = create(:purchase_item,
                            purchase: purchase1,
                            tax: tax)
    purchase1_entry = build(:journal_entry,
                            printed_on: printed_on,
                            real_credit: 870.0,
                            real_debit: 870.0)
    purchase1_entry.items = [
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: suppliers_account,
            real_credit: 870.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: vat_deductible_account,
            real_debit: 145.0,
            real_pretax_amount: 725.0,
            tax: tax,
            resource: purchase1_item),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: purchases_account,
            real_debit: 725.0)
    ]
    assert purchase1_entry.save

    payment1 = build(:journal_entry,
                     printed_on: printed_on,
                     real_credit: 340.0,
                     real_debit: 340.0)
    payment1.items = [
      build(:journal_entry_item,
            entry: payment1,
            account: suppliers_account,
            real_debit: 340.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: payment1,
            account: bank_account,
            real_credit: 340.0)
    ]
    assert payment1.save

    payment2 = build(:journal_entry,
                     printed_on: printed_on,
                     real_credit: 60.0,
                     real_debit: 60.0)
    payment2.items = [
      build(:journal_entry_item,
            printed_on: printed_on,
            entry: payment2,
            account: suppliers_account,
            real_debit: 60.0,
            letter: 'A'),
      build(:journal_entry_item,
            printed_on: printed_on,
            entry: payment2,
            account: bank_account,
            real_credit: 60.0)
    ]
    assert payment2.save

    subject = build(:tax_declaration, financial_year: financial_year, started_on: started_on, stopped_on: stopped_on)
    assert subject.save

    assert_equal 'payment', purchase1_entry.items.detect { |i| i.tax == tax }.reload.tax_declaration_mode

    subject.items.detect { |item| item.tax == tax }.tap do |tax_item|
      assert_equal 66.67, tax_item.deductible_tax_amount
      assert_equal 333.33, tax_item.deductible_pretax_amount
      assert_equal 0.0, tax_item.collected_tax_amount
      assert_equal 0.0, tax_item.collected_pretax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_tax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_pretax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_tax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_pretax_amount
      assert_equal -66.67, tax_item.balance_tax_amount
      assert_equal -333.33, tax_item.balance_pretax_amount

      assert_equal 1, tax_item.parts.length
      tax_item.parts.detect { |part| part.journal_entry_item.entry == purchase1_entry }.tap do |p|
        assert p
        assert_equal vat_deductible_account, p.account
        assert_equal 66.67, p.tax_amount
        assert_equal 333.33, p.pretax_amount
        assert_equal 145.0, p.total_tax_amount
        assert_equal 725.0, p.total_pretax_amount
        assert_equal 'deductible', p.direction
      end
    end

    assert_equal -66.67, subject.global_balance
  end
  test 'compute declaration with journal entry items on payment with payment and previous declared' do
    #
    # Tax: 20%
    #
    # Purchase1 (on payment, deductible)
    #    HT 725
    #   VAT 145
    #   TTC 870
    #
    #   Payment1 340 (previously declared)
    #   Payment2  60
    #
    # Sale1 (on payment, collected)
    #    HT 320
    #   VAT 64
    #   TTC 384
    #
    #   Payment3 300 (previously declared)
    #   Payment4  84
    #
    # ======>
    #
    # PREVIOUS DECLARATION :
    #
    # Deductible
    #   tax     56.67 (= 145 * 340 / 870)
    #   pretax 283.33 (= 725 * 340 / 870)
    # Collected
    #   tax     50.00 (= 64 * 300 / 384)
    #   pretax 250.00 (= 320 * 300 / 384)
    #
    # Global balance
    #   -6.67 (= 50 - 56.67)
    #
    # NEW DECLARATION :
    #
    # Deductible
    #   tax     10.00 (= 145 * (340 + 60) / 870 - 56.67)
    #   pretax  50.00 (= 725 * (340 + 60) / 870 - 283.33)
    # Collected
    #   tax     14.00 (= 64 * (300 + 84) / 384 - 50.00)
    #   pretax  70.00(= 320 * (300 + 84) / 384 - 250.00)
    #
    # Global balance
    #   4.00 (= 14 - 10)

    tax = taxes(:taxes_003)

    financial_year = financial_year_in_payment_mode

    previous_declaration_started_on = financial_year.started_on.beginning_of_month
    previous_declaration_stopped_on = previous_declaration_started_on.end_of_month
    previous_declaration_printed_on = previous_declaration_started_on + 1.day

    started_on = (previous_declaration_stopped_on + 1.day).beginning_of_month
    stopped_on = started_on.end_of_month
    printed_on = started_on + 1.day

    purchases_account = create(:account, name: 'Purchases')
    suppliers_account = create(:account, name: 'Suppliers')
    clients_account = create(:account, name: 'Clients')
    bank_account = create(:account, name: 'Brank')
    revenues_account = create(:account, name: 'Revenues')
    vat_deductible_account = tax.deduction_account
    vat_collected_account = tax.collect_account

    purchase1 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       tax_payability: 'at_paying')
    purchase1_item = create(:purchase_item,
                            purchase: purchase1,
                            tax: tax)
    purchase1_entry = build(:journal_entry,
                            printed_on: previous_declaration_printed_on,
                            real_credit: 870.0,
                            real_debit: 870.0)
    purchase1_entry.items = [
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: suppliers_account,
            real_credit: 870.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: vat_deductible_account,
            real_debit: 145.0,
            real_pretax_amount: 725.0,
            tax: tax,
            resource: purchase1_item),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: purchases_account,
            real_debit: 725.0)
    ]
    assert purchase1_entry.save

    payment1 = build(:journal_entry,
                     printed_on: previous_declaration_printed_on,
                     real_credit: 340.0,
                     real_debit: 340.0)
    payment1.items = [
      build(:journal_entry_item,
            entry: payment1,
            account: suppliers_account,
            real_debit: 340.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: payment1,
            account: bank_account,
            real_credit: 340.0)
    ]
    assert payment1.save

    payment2 = build(:journal_entry,
                     printed_on: printed_on,
                     real_credit: 60.0,
                     real_debit: 60.0)
    payment2.items = [
      build(:journal_entry_item,
            printed_on: printed_on,
            entry: payment2,
            account: suppliers_account,
            real_debit: 60.0,
            letter: 'A'),
      build(:journal_entry_item,
            printed_on: printed_on,
            entry: payment2,
            account: bank_account,
            real_credit: 60.0)
    ]
    assert payment2.save

    sale1 = create(:sale, nature: sale_natures(:sale_natures_001))
    sale1_item = create(:sale_item, sale: sale1, tax: tax)
    sale1_entry = build(:journal_entry,
                        printed_on: previous_declaration_printed_on,
                        real_credit: 384.0,
                        real_debit: 384.0)
    sale1_entry.items = [
      build(:journal_entry_item,
            entry: sale1_entry,
            account: clients_account,
            real_debit: 384.0,
            letter: 'B'),
      build(:journal_entry_item,
            entry: sale1_entry,
            account: vat_collected_account,
            real_credit: 64.0,
            real_pretax_amount: 320.0,
            tax: tax,
            resource: sale1_item),
      build(:journal_entry_item,
            entry: sale1_entry,
            account: revenues_account,
            real_credit: 320.0)
    ]
    assert sale1_entry.save

    payment3 = build(:journal_entry,
                     printed_on: previous_declaration_printed_on,
                     real_credit: 300.0,
                     real_debit: 300.0)
    payment3.items = [
      build(:journal_entry_item,
            entry: payment3,
            account: clients_account,
            real_credit: 300.0,
            letter: 'B'),
      build(:journal_entry_item,
            entry: payment3,
            account: revenues_account,
            real_debit: 300.0)
    ]
    assert payment3.save

    payment4 = build(:journal_entry,
                     printed_on: printed_on,
                     real_credit: 84.0,
                     real_debit: 84.0)
    payment4.items = [
      build(:journal_entry_item,
            printed_on: printed_on,
            entry: payment4,
            account: clients_account,
            real_credit: 84.0,
            letter: 'B'),
      build(:journal_entry_item,
            printed_on: printed_on,
            entry: payment4,
            account: revenues_account,
            real_debit: 84.0)
    ]
    assert payment4.save

    previous = create(:tax_declaration,
                      financial_year: financial_year,
                      started_on: previous_declaration_started_on,
                      stopped_on: previous_declaration_stopped_on)
    assert_equal -6.67, previous.global_balance

    subject = build(:tax_declaration,
                    financial_year: financial_year,
                    started_on: started_on,
                    stopped_on: stopped_on)
    assert subject.save

    subject.items.detect { |item| item.tax == tax }.tap do |tax_item|
      assert_equal 2, tax_item.parts.length
      tax_item.parts.detect { |part| part.journal_entry_item.entry == purchase1_entry }.tap do |p|
        assert p
        assert_equal vat_deductible_account, p.account
        assert_equal 10.0, p.tax_amount
        assert_equal 50.0, p.pretax_amount
        assert_equal 145.0, p.total_tax_amount
        assert_equal 725.0, p.total_pretax_amount
        assert_equal 'deductible', p.direction
      end
      tax_item.parts.detect { |part| part.journal_entry_item.entry == sale1_entry }.tap do |p|
        assert p
        assert_equal vat_collected_account, p.account
        assert_equal 14.0, p.tax_amount
        assert_equal 70.0, p.pretax_amount
        assert_equal 64.0, p.total_tax_amount
        assert_equal 320.0, p.total_pretax_amount
        assert_equal 'collected', p.direction
      end

      assert_equal 10.0, tax_item.deductible_tax_amount
      assert_equal 50.0, tax_item.deductible_pretax_amount
      assert_equal 14.0, tax_item.collected_tax_amount
      assert_equal 70.0, tax_item.collected_pretax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_tax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_pretax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_tax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_pretax_amount
      assert_equal 4.0, tax_item.balance_tax_amount
      assert_equal 20.0, tax_item.balance_pretax_amount
    end

    assert_equal 4.0, subject.global_balance
  end
  test 'compute declaration with journal entry items on payment with multiple deals on the same affair' do
    #
    # Tax: 20%
    #
    # Purchase1 (on payment, deductible)
    #    HT 725
    #   VAT 145
    #   TTC 870
    #
    # Purchase2 (on payment, deductible)
    #    HT  60
    #   VAT  12
    #   TTC  72
    #
    # Payment1 300
    #
    #
    # ======>
    #
    # Deductible
    #   tax     50.00 (= (145 * 300 / (870 + 72)) + (12 * 300 / (870 + 72)))
    #   pretax 250.00 (= (725 * 300 / (870 + 72)) + (60 * 300 / (870 + 72)))
    #
    # Global balance
    #   -50.00
    tax = taxes(:taxes_003)

    financial_year = financial_year_in_debit_mode
    started_on = financial_year.started_on
    stopped_on = started_on.end_of_month
    printed_on = started_on + 1.day

    purchases_account = create(:account, name: 'Purchases')
    suppliers_account = create(:account, name: 'Suppliers')
    bank_account = create(:account, name: 'Brank')
    vat_deductible_account = tax.deduction_account

    purchase_affair = create(:purchase_affair, letter: 'A')

    purchase1 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       affair: purchase_affair,
                       tax_payability: 'at_paying')
    purchase1_item = create(:purchase_item,
                            purchase: purchase1,
                            tax: tax)
    purchase1_entry = build(:journal_entry,
                            printed_on: printed_on,
                            real_credit: 870.0,
                            real_debit: 870.0)
    purchase1_entry.items = [
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: suppliers_account,
            real_credit: 870.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: vat_deductible_account,
            real_debit: 145.0,
            real_pretax_amount: 725.0,
            tax: tax,
            resource: purchase1_item),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: purchases_account,
            real_debit: 725.0)
    ]
    assert purchase1_entry.save

    purchase2 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       affair: purchase_affair,
                       tax_payability: 'at_paying')
    purchase2_item = create(:purchase_item,
                            purchase: purchase2,
                            tax: tax)
    purchase2_entry = build(:journal_entry,
                            printed_on: printed_on,
                            real_credit: 72.0,
                            real_debit: 72.0)
    purchase2_entry.items = [
      build(:journal_entry_item,
            entry: purchase2_entry,
            account: suppliers_account,
            real_credit: 72.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: purchase2_entry,
            account: vat_deductible_account,
            real_debit: 12.0,
            real_pretax_amount: 60.0,
            tax: tax,
            resource: purchase2_item),
      build(:journal_entry_item,
            entry: purchase2_entry,
            account: purchases_account,
            real_debit: 60.0)
    ]
    assert purchase2_entry.save

    payment1 = build(:journal_entry,
                     printed_on: printed_on,
                     real_credit: 300.0,
                     real_debit: 300.0)
    payment1.items = [
      build(:journal_entry_item,
            entry: payment1,
            account: suppliers_account,
            real_debit: 300.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: payment1,
            account: bank_account,
            real_credit: 300.0)
    ]
    assert payment1.save

    subject = build(:tax_declaration, financial_year: financial_year, started_on: started_on, stopped_on: stopped_on)
    assert subject.save

    assert_equal 'payment', purchase1_entry.items.detect { |i| i.tax == tax }.reload.tax_declaration_mode
    assert_equal 'payment', purchase2_entry.items.detect { |i| i.tax == tax }.reload.tax_declaration_mode

    subject.items.detect { |item| item.tax == tax }.tap do |tax_item|
      assert_equal 50.0, tax_item.deductible_tax_amount
      assert_equal 250.0, tax_item.deductible_pretax_amount
      assert_equal 0.0, tax_item.collected_tax_amount
      assert_equal 0.0, tax_item.collected_pretax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_tax_amount
      assert_equal 0.0, tax_item.fixed_asset_deductible_pretax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_tax_amount
      assert_equal 0.0, tax_item.intracommunity_payable_pretax_amount
      assert_equal -50.0, tax_item.balance_tax_amount
      assert_equal -250.0, tax_item.balance_pretax_amount

      assert_equal 2, tax_item.parts.length
      tax_item.parts.detect { |part| part.journal_entry_item.entry == purchase1_entry }.tap do |p|
        assert p
        assert_equal vat_deductible_account, p.account
        assert_equal 46.18, p.tax_amount
        assert_equal 230.89, p.pretax_amount
        assert_equal 145.0, p.total_tax_amount
        assert_equal 725.0, p.total_pretax_amount
        assert_equal 'deductible', p.direction
      end
      tax_item.parts.detect { |part| part.journal_entry_item.entry == purchase2_entry }.tap do |p|
        assert p
        assert_equal vat_deductible_account, p.account
        assert_equal 3.82, p.tax_amount
        assert_equal 19.11, p.pretax_amount
        assert_equal 12.0, p.total_tax_amount
        assert_equal 60.0, p.total_pretax_amount
        assert_equal 'deductible', p.direction
      end
    end
    assert_equal -50.0, subject.global_balance
  end
  test 'does not create tax declaration item parts with zero amount' do
    tax = taxes(:taxes_003)

    financial_year = financial_year_in_debit_mode
    started_on = financial_year.started_on
    stopped_on = started_on.end_of_month
    printed_on = started_on + 1.day

    purchases_account = create(:account, name: 'Purchases')
    suppliers_account = create(:account, name: 'Suppliers')
    bank_account = create(:account, name: 'Brank')
    vat_deductible_account = tax.deduction_account

    purchase1 = create(:purchase_invoice,
                       nature: purchase_natures(:purchase_natures_001),
                       tax_payability: 'at_paying')
    purchase1_item = create(:purchase_item,
                            purchase: purchase1,
                            tax: tax)
    purchase1_entry = build(:journal_entry,
                            printed_on: printed_on,
                            real_credit: 870.0,
                            real_debit: 870.0)
    purchase1_entry.items = [
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: suppliers_account,
            real_credit: 870.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: vat_deductible_account,
            real_debit: 145.0,
            real_pretax_amount: 725.0,
            tax: tax,
            resource: purchase1_item),
      build(:journal_entry_item,
            entry: purchase1_entry,
            account: purchases_account,
            real_debit: 725.0)
    ]
    assert purchase1_entry.save

    payment1 = build(:journal_entry,
                     printed_on: printed_on,
                     real_credit: 870.0,
                     real_debit: 870.0)
    payment1.items = [
      build(:journal_entry_item,
            entry: payment1,
            account: suppliers_account,
            real_debit: 870.0,
            letter: 'A'),
      build(:journal_entry_item,
            entry: payment1,
            account: bank_account,
            real_credit: 870.0)
    ]
    assert payment1.save

    previous = create(:tax_declaration,
                      financial_year: financial_year,
                      started_on: started_on,
                      stopped_on: stopped_on)

    subject = create(:tax_declaration,
                     financial_year: financial_year,
                     started_on: (started_on + 1.month).beginning_of_month,
                     stopped_on: (stopped_on + 1.month).end_of_month)
    assert subject.save

    assert_empty subject.items.select { |item| item.parts.any? }
  end

  def financial_year_in_debit_mode
    financial_years(:financial_years_008)
  end

  def financial_year_in_payment_mode
    financial_years(:financial_years_008).tap do |y|
      y.update_attribute :tax_declaration_mode, :payment
    end
  end
end
