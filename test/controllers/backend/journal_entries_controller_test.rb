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
  class JournalEntriesControllerTest < ActionController::TestCase
    test_restfully_all_actions(
      new: { journal_id: 3 },
      toggle_autocompletion: { format: :json },
      currency_state: { from: 'EUR' },
      update: {
        items_attributes: {
          0 => { account_id: 152, name: 'Test' },
          1 => { account_id: 160, name: 'Test' }
        }
      },
      index: :redirected_get
    )

    test 'create with affair' do
      sale = Sale.last
      affair = sale.affair
      journal = Journal.last
      date = DateTime.now.to_date
      user = User.where(administrator: true).last
      sign_in(user)
      post(:create,
           journal_entry: {
             journal_id: journal.id,
             printed_on:  date,
             real_currency_rate: 1,
             real_currency: 'EUR',
             number: 'HA0010',
             affair_id: affair.id,
             items_attributes: {
               '1491818768866' => {
                 name: 'Test',
                 account_id: Account.last.id,
                 activity_budget_id: ActivityBudget.first.id,
                 team_id: Team.last.id,
                 real_debit: 10,
                 real_credit: 0.0,
                 _destroy: false
               },
               '1491818830695' => {
                 name: 'Hallo',
                 account_id: Account.last.id,
                 activity_budget_id: ActivityBudget.first.id,
                 team_id: Team.last.id,
                 real_debit: 0.0,
                 real_credit: 10,
                 _destroy: false
               }
             }
           },
           redirect: backend_sale_path(sale))
      assert_response :redirect
      assert_redirected_to backend_sale_url(sale)
    end

    test 'duplicate' do
      get :new, duplicate_of: JournalEntry.find_by(id: JournalEntryItem.first.id).id
      assert_select '#items-table' do
        assert_select 'tbody.nested-fields'
      end
    end
  end
end
