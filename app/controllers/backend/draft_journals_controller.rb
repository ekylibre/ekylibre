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
  class DraftJournalsController < Backend::BaseController
    include JournalEntriesCondition

    list(:journal_entry_items, conditions: journal_entries_conditions(with_journals: true, state: :draft), joins: :entry, line_class: "(RECORD.position==1 ? 'first-item' : '')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
      t.column :journal, url: true
      t.column :entry_number, url: true
      t.column :printed_on, datatype: :date
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
      t.column :name
      t.column :real_debit,  currency: :real_currency, hidden: true
      t.column :real_credit, currency: :real_currency, hidden: true
      t.column :debit,  currency: true
      t.column :credit, currency: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
    end

    # this method lists all the entries generated in draft mode
    def show; end

    # This method confirm all draft entries
    def confirm
      conditions = nil
      begin
        conditions = eval(self.class.journal_entries_conditions(with_journals: true, state: :draft))
        journal_entries = JournalEntry.where(conditions)
        undone = 0
        journal_entries.find_each do |entry|
          entry.confirm if entry.can_confirm?
          undone += 1 if entry.draft?
        end
        notify_success(:draft_journal_entries_have_been_validated, count: journal_entries.size - undone)
      rescue Exception => e
        notify_error(:exception_raised, message: e.message)
      end
      redirect_to action: :show
    end
  end
end
