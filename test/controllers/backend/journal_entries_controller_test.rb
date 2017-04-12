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

    test 'duplicate' do
      get :new, duplicate_of: JournalEntry.find_by(id: JournalEntryItem.first.id).id
      assert_select '#items-table' do
        assert_select 'tbody.nested-fields'
      end
    end
  end
end
