# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'test_helper'
module Backend
  class FinancialYearsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions generate_last_journal_entry: :get_and_post, close: :get_and_post, compute_balances: :touch, destroy_all_empty: :destroy, except: %i[synthesis run_progress]

    test 'locking a financial year locks its fixed asset depreciations as well' do
      FinancialYear.delete_all
      financial_year = create(:financial_year, started_on: Date.today.beginning_of_year, stopped_on: Date.today.end_of_year)
      fixed_asset = create(:fixed_asset, started_on: Date.today, stopped_on: Date.today + 1.day)
      fixed_asset_depreciation = create(:fixed_asset_depreciation, fixed_asset: fixed_asset, started_on: Date.today, stopped_on: Date.today + 1.day)
      assert !fixed_asset_depreciation.locked
      post :lock, params: { id: financial_year.id }
      assert FixedAssetDepreciation.up_to(financial_year.stopped_on).where(locked: false).empty?
    end

    test 'rendering allocation view' do
      FinancialYear.delete_all
      setup_allocation

      @company.update!(legal_position_code: "SA")

      get :close, params: { id: @financial_year }
      assert_template partial: '_capital_result_allocation'

      @company.update!(legal_position_code: "EI")

      get :close, params: { id: @financial_year }
      assert_equal 1, (Nokogiri::HTML(response.body).css('div.amount_allocated--individual_capital #allocations_101')).count

      @company.update!(legal_position_code: "GAEC")
      get :close, params: { id: @financial_year }
      assert_template partial: '_person_result_allocation'
    end

    test 'amount allocated are balanced' do
      FinancialYear.delete_all
      OutgoingPayment.delete_all
      Regularization.delete_all
      Payslip.delete_all
      JournalEntry.delete_all
      setup_allocation

      @company.update!(legal_position_code: "SA")
      result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)
      closing = Journal.create!(name: 'Close TEST', code: 'CLOSTST', nature: :closure)
      forward = Journal.create!(name: 'Forward TEST', code: 'FWDTST', nature: :forward)

      Account.create!(name: 'Test1061x', number: '1061')
      Account.create!(name: 'Test1063x', number: '1063')
      Account.create!(name: 'Test1064x', number: '1064')
      Account.create!(name: 'Test1068x', number: '1068')
      Account.create!(name: 'Test457x', number: '457')
      Account.create!(name: 'Test4423x', number: '4423')

      accounts = {
        7030 => Account.find_or_import_from_nomenclature(:processing_products_revenues),
        5110 => Account.find_or_import_from_nomenclature(:pending_deposit_payments),
        6028 => Account.find_or_import_from_nomenclature(:raw_material_expenses),
        5120 => Account.find_or_import_from_nomenclature(:banks),
        4552 => Account.find_or_import_from_nomenclature(:usual_associates_current_accounts)
      }

      generate_entry(accounts[4552], 2000, destination_account: accounts[7030])
      generate_entry(accounts[5110], 2000, destination_account: accounts[4552])
      generate_entry(accounts[6028], 300, destination_account: accounts[4552])
      generate_entry(accounts[4552], 300, destination_account: accounts[5120])

      validate_fog

      allocations = {
        '1061' => 0,
        '1063' => 150,
        '1064' => 150,
        '1068' => 150,
        '457' => 400,
        '4423' => 300,
        '110' => 400
      }

      post :close, params: {
        id: @financial_year,
        financial_year: { stopped_on: @financial_year.stopped_on },
        result_journal: result,
        closure_journal: closing,
        forward_journal: forward,
        allocations: allocations
      }

      assert_equal 1, flash[:notifications]['error'].count

      allocations = {
        '1061' => 150,
        '1063' => 150,
        '1064' => 150,
        '1068' => 150,
        '457' => 400,
        '4423' => 300,
        '110' => 400
      }

      post :close, params: {
        id: @financial_year,
        financial_year: { stopped_on: @financial_year.stopped_on },
        result_journal: result,
        closure_journal: closing,
        forward_journal: forward,
        allocations: allocations
      }

      assert_equal 1, flash[:notifications]['success'].count
      assert @financial_year.reload.close(User.first, nil, result_journal: result)

      @company.update!(legal_position_code: "GAEC")
      @next_year2 = create(:financial_year, started_on: Date.new(2010, 1, 1), stopped_on: Date.new(2010, 12, 31))
      generate_entry(accounts[6028], 30000, printed_on: @financial_year.stopped_on + 2.days, destination_account: accounts[4552])
      validate_fog
      @next_year.reload

      get :close, params: { id: @next_year }
      assert_template partial: '_negative_result_allocation_person'

      post :close, params: {
        id: @next_year,
        financial_year: { stopped_on: @next_year.stopped_on },
        result_journal: result,
        closure_journal: closing,
        forward_journal: forward,
        allocations: allocations
      }

      assert_equal 1, flash[:notifications]['success'].count
    end

    private

      def setup_allocation
        @dumpster_account = Account.create!(name: 'TestDumpster', number: '10001')
        @dumpster_journal = Journal.create!(name: 'Dumpster journal', code: 'DMPTST')
        @financial_year = create(:financial_year, started_on: Date.new(2008, 1, 1), stopped_on: Date.new(2008, 12, 31))
        @next_year = create(:financial_year, started_on: Date.new(2009, 1, 1), stopped_on: Date.new(2009, 12, 31))
        @profits = Account.create!(name: 'FinancialYear result profit', number: '120', usages: :financial_year_result_profit)
        @losses = Account.create!(name: 'FinancialYear result loss', number: '129', usages: :financial_year_result_loss)
        @credit_carry_forward = Account.create!(name: 'credit carry forward', number: '110', usages: :credit_retained_earnings)
        @debit_carry_forward = Account.create!(name: 'debit carry forward', number: '119', usages: :debit_retained_earnings)
        @company = Entity.create!(last_name: 'Test', nature: :organization, of_company: true)
        @open = Account.create!(number: '89', name: 'Opening account')
        @close = Account.create!(number: '891', name: 'Closing account')
      end

      def generate_entry(account, debit, letter: nil, printed_on: Date.new(2008, 1, 1) + 2.days, destination_account: @dumpster_account)
        return if debit.zero?

        side = debit > 0 ? :debit : :credit
        other_side = debit < 0 ? :debit : :credit
        amount = debit.abs
        JournalEntry.create!(journal: @dumpster_journal, printed_on: printed_on, items_attributes: [
          {
            name: side.to_s.capitalize,
            account: account,
            letter: letter,
            :"real_#{side}" => amount
          },
          {
            name: other_side.to_s.capitalize,
            account: destination_account,
            :"real_#{other_side}" => amount
          }
        ])
      end

      def validate_fog
        JournalEntry.find_each { |je| je.update(state: :confirmed) }
      end
  end
end
