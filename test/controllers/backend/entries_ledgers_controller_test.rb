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
  class EntriesLedgersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures

    setup_sign_in

    test "#update_journal_entry_items update journal entry item and redirect to show" do
      activity_budget = activity_budgets(:activity_budgets_001)
      journal_entry_items = journal_entry_items(:journal_entry_items_001, :journal_entry_items_002)

      put :update_journal_entry_items, params: { activity_budget_id: activity_budget.id, journal_entry_item_ids: journal_entry_items.pluck(:id).join(',') }
      assert_equal activity_budget.id, journal_entry_items.first.reload.activity_budget_id
      assert_redirected_to controller: :entries_ledgers, action: :show
      assert_equal 1, flash[:notifications]['success'].count
      flash.clear

      put :update_journal_entry_items, params: {}
      assert_equal 1, flash[:notifications]['error'].count
    end

  end
end
