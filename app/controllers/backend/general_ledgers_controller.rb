# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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

module Backend
  class GeneralLedgersController < Backend::BaseController
    def self.list_conditions
      code = ''
      code << search_conditions({ journal_entry_item: %i[name debit credit real_debit real_credit] }, conditions: 'c') + "\n"
      code << journal_period_crit('params')
      code << journal_entries_states_crit('params')
      code << accounts_range_crit('params')
      code << journals_crit('params')
      code << journal_letter_crit('params')
      code << amount_range_crit('params')
      code << "c\n"
      code.c
    end

    list(:journal_entry_items, conditions: list_conditions, joins: %i[entry account], order: "accounts.number, journal_entries.number, #{JournalEntryItem.table_name}.position") do |t|
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
      t.column :entry_number, url: true
      t.column :printed_on
      t.column :name
      t.column :variant, url: true, hidden: true
      t.column :letter
      t.column :real_debit,  currency: :real_currency, hidden: true
      t.column :real_credit, currency: :real_currency, hidden: true
      t.column :debit,  currency: true, hidden: true, on_select: :sum
      t.column :credit, currency: true, hidden: true, on_select: :sum
      t.column :absolute_debit,  currency: :absolute_currency, on_select: :sum
      t.column :absolute_credit, currency: :absolute_currency, on_select: :sum
    end

    def show; end
  end
end
