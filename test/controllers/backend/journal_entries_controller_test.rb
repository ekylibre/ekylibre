# -*- coding: utf-8 -*-
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
      new: { journal_id: identify(:journals_001) },
      update: {
        items: {
          0 => { account_id: identify(:accounts_001), name: 'Test' },
          1 => { account_id: identify(:accounts_002), name: 'Test' }
        }
      },
      index: :redirected_get
    )
  end
end
