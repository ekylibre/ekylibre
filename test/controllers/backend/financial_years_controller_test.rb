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
  class FinancialYearsControllerTest < ActionController::TestCase
    test_restfully_all_actions generate_last_journal_entry: :get_and_post, close: :get_and_post, compute_balances: :touch, destroy_all_empty: :destroy, except: %i[synthesis run_progress prepare_for_closure]

    test 'locking a financial year locks its fixed asset depreciations as well' do
      FinancialYear.delete_all
      financial_year = create(:financial_year, started_on: Date.today.beginning_of_year, stopped_on: Date.today.end_of_year)
      fixed_asset = create(:fixed_asset, started_on: Date.today, stopped_on: Date.today + 1.day)
      fixed_asset_depreciation = create(:fixed_asset_depreciation, fixed_asset: fixed_asset, started_on: Date.today, stopped_on: Date.today + 1.day)
      assert !fixed_asset_depreciation.locked
      post :lock, id: financial_year.id
      assert FixedAssetDepreciation.up_to(financial_year.stopped_on).where(locked: false).empty?
    end

    test 'the user in charge of a financial year closure is the only one who can keep adding entries for this period' do
      FinancialYear.delete_all
      financial_year = create(:financial_year, started_on: Date.today.beginning_of_year, stopped_on: Date.today.end_of_year)

      sign_in User.first
      post :prepare_for_closure, id: financial_year.id, redirect: backend_financial_years_path

      assert_equal FinancialYear.first.closer, User.first
      assert_equal FinancialYear.first.state, 'closure_in_preparation'

      assert create(:journal_entry, :with_items, printed_on: Date.today, creator: User.first)
      assert_raises ActiveRecord::RecordInvalid do
        create(:journal_entry, :with_items, printed_on: Date.today, creator: User.second)
      end

      delete :prepare_for_closure, id: financial_year.id, redirect: backend_financial_years_path

      assert_nil FinancialYear.first.closer
      assert_equal FinancialYear.first.state, 'opened'

      assert create(:journal_entry, :with_items, printed_on: Date.today, creator: User.first)
      assert create(:journal_entry, :with_items, printed_on: Date.today, creator: User.second)
    end
  end
end
