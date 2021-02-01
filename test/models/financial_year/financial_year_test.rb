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
# == Table: financial_years
#
#  accountant_id             :integer
#  already_existing          :boolean          default(FALSE), not null
#  closed                    :boolean          default(FALSE), not null
#  closer_id                 :integer
#  code                      :string           not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  currency                  :string           not null
#  currency_precision        :integer
#  custom_fields             :jsonb
#  id                        :integer          not null, primary key
#  last_journal_entry_id     :integer
#  lock_version              :integer          default(0), not null
#  started_on                :date             not null
#  state                     :string
#  stopped_on                :date             not null
#  tax_declaration_frequency :string
#  tax_declaration_mode      :string           not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#

require 'test_helper'

module FinancialYearTest
  class FinancialYearTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    test_model_actions class: FinancialYear

    test 'chronology' do
      first_year = financial_years(:financial_years_001)
      assert_not_nil first_year

      assert_nil first_year.previous, 'No previous financial year expected'

      assert_not_nil first_year.next, "No next financial year found... #{first_year.attributes.inspect}"

      assert_not_nil first_year.next.previous
      assert_equal first_year, first_year.next.previous
    end

    test 'accountant can be set' do
      year = financial_years(:financial_years_025)
      year.accountant = create(:entity, :accountant)
      assert year.valid?
    end

    test 'financial year can t be created before company born at date' do
      assert FinancialYear.on(Date.civil(1900, 1, 4)).nil?
      assert FinancialYear.on(Date.civil(2015, 5, 4))
    end

    test 'compute periods given a specific interval' do
      FinancialYear.delete_all
      financial_year_18_19 = create(:financial_year, started_on: Date.new(2018, 9, 1), stopped_on: Date.new(2019, 8, 31))

      assert_equal financial_year_18_19.split_into_periods('semesters'), [
        [Date.new(2018, 9, 1), Date.new(2019, 2, 28)],
        [Date.new(2019, 3, 1), Date.new(2019, 8, 31)]
      ]
      assert_equal financial_year_18_19.split_into_periods('trimesters'), [
        [Date.new(2018, 9, 1), Date.new(2018, 11, 30)],
        [Date.new(2018, 12, 1), Date.new(2019, 2, 28)],
        [Date.new(2019, 3, 1), Date.new(2019, 5, 31)],
        [Date.new(2019, 6, 1), Date.new(2019, 8, 31)]
      ]
      assert_equal financial_year_18_19.split_into_periods('months'), [
        [Date.new(2018, 9, 1), Date.new(2018, 9, 30)],
        [Date.new(2018, 10, 1), Date.new(2018, 10, 31)],
        [Date.new(2018, 11, 1), Date.new(2018, 11, 30)],
        [Date.new(2018, 12, 1), Date.new(2018, 12, 31)],
        [Date.new(2019, 1, 1), Date.new(2019, 1, 31)],
        [Date.new(2019, 2, 1), Date.new(2019, 2, 28)],
        [Date.new(2019, 3, 1), Date.new(2019, 3, 31)],
        [Date.new(2019, 4, 1), Date.new(2019, 4, 30)],
        [Date.new(2019, 5, 1), Date.new(2019, 5, 31)],
        [Date.new(2019, 6, 1), Date.new(2019, 6, 30)],
        [Date.new(2019, 7, 1), Date.new(2019, 7, 31)],
        [Date.new(2019, 8, 1), Date.new(2019, 8, 31)],
      ]
    end

    test 'can not get more than 2 opened financial years' do
      FinancialYear.delete_all
      year1 = create(:financial_year, started_on: '01-01-2015', stopped_on: '31-12-2015', state: :opened)
      year2 = create(:financial_year, started_on: '01-01-2016', stopped_on: '31-12-2016', state: :opened)
      assert_raise(ActiveRecord::RecordInvalid) { create(:financial_year, started_on: '01-01-2017', stopped_on: '31-12-2017', state: :opened) }

      year1.update_attribute(:state, :closed)
      assert create(:financial_year, started_on: '01-01-2017', stopped_on: '31-12-2017', state: :opened), 'There are still at least 2 financial years opened'
    end

    test 'can not create accountant elements on a closed financial year' do
      FinancialYear.delete_all
      year = create(:financial_year, started_on: '01-01-2017', stopped_on: '31-12-2017', state: :closed)

      create_accountant_elements_should_raise '06-01-2017'
    end

    test 'can not create accountant elements on a locked financial year' do
      FinancialYear.delete_all
      year = create(:financial_year, started_on: '01-01-2017', stopped_on: '31-12-2017', state: :locked)

      create_accountant_elements_should_raise '06-01-2017'
    end

    test 'destroy all consecutive financial years without entries' do
      # This behaviour is intended for farms existing before the migration that adds the 'state' field. Those have lots of unused financial years and users want to quickly delete them.

      # Clean data
      FinancialYear.delete_all
      TaxDeclaration.delete_all
      Payslip.delete_all
      Regularization.delete_all
      OutgoingPayment.delete_all
      JournalEntry.delete_all
      Inventory.delete_all

      # Generate financial years with no journal entries, no tax declarations and no inventory in order to make destroyable
      (2001..2010).each { |y| create(:financial_year, :skip_validate, year: y, state: :opened) }
      assert_equal FinancialYear.count, 10
      assert_equal FinancialYear.consecutive_destroyables.count, FinancialYear.count

      # Add an entry to a financial year, not the first nor the last, in order to make it not destroyable
      printed_on = FinancialYear.order(:started_on)[7].started_on + 100.days
      create(:journal_entry, :with_items, printed_on: printed_on)
      assert_equal 7, FinancialYear.consecutive_destroyables.count
      assert FinancialYear.where(id: FinancialYear.consecutive_destroyables.map(&:id)).delete_all
    end

    def create_accountant_elements_should_raise(accounting_date)
      assert_raise(ActiveRecord::RecordInvalid) { create(:sale, invoiced_at: accounting_date) }
      assert_raise(ActiveRecord::RecordInvalid) { create(:purchase_invoice, invoiced_at: accounting_date) }
      assert_raise(ActiveRecord::RecordInvalid) { create(:cash_transfer, transfered_at: accounting_date) }
      assert_raise(ActiveRecord::RecordInvalid) { create(:parcel, given_at: accounting_date) }
    end
  end
end
