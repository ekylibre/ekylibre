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
# == Table: tax_declaration_items
#
#  balance_pretax_amount                :decimal(19, 4)   default(0.0), not null
#  balance_tax_amount                   :decimal(19, 4)   default(0.0), not null
#  collected_pretax_amount              :decimal(19, 4)   default(0.0), not null
#  collected_tax_amount                 :decimal(19, 4)   default(0.0), not null
#  created_at                           :datetime         not null
#  creator_id                           :integer
#  currency                             :string           not null
#  deductible_pretax_amount             :decimal(19, 4)   default(0.0), not null
#  deductible_tax_amount                :decimal(19, 4)   default(0.0), not null
#  fixed_asset_deductible_pretax_amount :decimal(19, 4)   default(0.0), not null
#  fixed_asset_deductible_tax_amount    :decimal(19, 4)   default(0.0), not null
#  id                                   :integer          not null, primary key
#  intracommunity_payable_pretax_amount :decimal(19, 4)   default(0.0), not null
#  intracommunity_payable_tax_amount    :decimal(19, 4)   default(0.0), not null
#  lock_version                         :integer          default(0), not null
#  tax_declaration_id                   :integer          not null
#  tax_id                               :integer          not null
#  updated_at                           :datetime         not null
#  updater_id                           :integer
#
require 'test_helper'

class TaxDeclarationItemTest < ActiveSupport::TestCase
  test 'it is possible to declare VAT for a financial year no matter if it has been done for previous financial years or not' do
    clean_irrelevant_fixtures
    create_journals

    financial_year_17 = create(:financial_year, started_on: '01/01/2017', stopped_on: '31/12/2017')
    financial_year_18 = create(:financial_year, started_on: '01/01/2018', stopped_on: '31/12/2018')

    Timecop.travel(Time.new(2018, 01, 02))

    sale = create(:sale_with_accounting)
    sale_item = create(:sale_item, sale: sale)
    sale.invoice!
    incoming_payment = create(:incoming_payment, payer: sale.client, amount: sale.amount, currency: sale.currency)
    sale.affair.attach(incoming_payment)
    sale.affair.finish

    tax_declaration = create(:tax_declaration, financial_year: financial_year_18)
    tax_declaration.propose
    tax_declaration.confirm

    Timecop.return

    assert TaxDeclaration.where(financial_year: financial_year_17).none?
    assert TaxDeclaration.where(financial_year: financial_year_18).any?
  end

  test 'when declaring VAT, journal entries are filtered by financial year' do
    clean_irrelevant_fixtures
    create_journals

    financial_year_17 = create(:financial_year, started_on: '01/01/2017', stopped_on: '31/12/2017')
    financial_year_18 = create(:financial_year, started_on: '01/01/2018', stopped_on: '31/12/2018')

    Timecop.travel(Time.new(2017, 01, 02))

    sale_one = create(:sale_with_accounting)
    sale_item_one = create(:sale_item, sale: sale_one)
    sale_one.invoice!

    Timecop.travel(Time.new(2018, 01, 02))

    sale_two = create(:sale_with_accounting, nature: sale_one.nature)
    sale_item_two = create(:sale_item, sale: sale_two)
    sale_two.invoice!

    Timecop.return

    tax_declaration = create(:tax_declaration, financial_year: financial_year_18)
    tax_declaration.propose
    tax_declaration.confirm

    tax_declaration.items.each do |tdi|
      tdi.parts.each do |tdip|
        assert tdip.journal_entry_item.financial_year_id == financial_year_18.id
      end
    end
  end

  test 'unlettered entries when closing a financial year are deferred on to the next one without any tax to avoid duplication in VAT declaration' do
    clean_irrelevant_fixtures
    create_journals

    financial_year_18 = create(:financial_year, started_on: '01/01/2018', stopped_on: '31/12/2018')
    financial_year_19 = create(:financial_year, started_on: '01/01/2019', stopped_on: '31/12/2019')

    Timecop.travel(Time.new(2018, 01, 02))
    sale_one = create(:sale_with_accounting)
    sale_item_one = create(:sale_item, sale: sale_one)
    sale_one.invoice!
    incoming_payment = create(:incoming_payment, payer: sale_one.client, amount: sale_one.amount, currency: sale_one.currency)
    sale_one.affair.attach(incoming_payment)
    sale_one.affair.finish

    sale_two = create(:sale_with_accounting, nature: sale_one.nature)
    sale_item_two = create(:sale_item, sale: sale_two)
    sale_two.invoice!

    tax_declaration = create(:tax_declaration, financial_year: financial_year_18)
    tax_declaration.propose
    tax_declaration.confirm

    JournalEntry.all.each { |ji| ji.confirm }

    Timecop.travel(Time.new(2019, 01, 02))
    financial_year_18.close(Date.new(2018, 12, 31),
                            result_journal_id: Journal.where(nature: 'result').first.id,
                            forward_journal_id: Journal.where(nature: 'forward').first.id,
                            closure_journal_id: Journal.where(nature: 'closure').first.id)

    financial_year_19.journal_entries.each do |je|
      assert je.items.where.not(tax_id: nil).empty?
    end
  end

  private

  def clean_irrelevant_fixtures
    FinancialYear.delete_all
    OutgoingPayment.delete_all
    Sale.delete_all
    SaleItem.delete_all
    Regularization.delete_all
    Payslip.delete_all
    JournalEntry.delete_all
    JournalEntryItem.delete_all
    Affair.delete_all
    TaxDeclaration.delete_all
  end

  def create_journals
    create(:journal, nature: 'result')
    create(:journal, nature: 'closure')
    create(:journal, nature: 'forward')
  end
end
