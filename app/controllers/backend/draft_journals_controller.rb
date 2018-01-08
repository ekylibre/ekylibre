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
      conditions = eval(self.class.journal_entries_conditions(with_journals: true, state: :draft))
      journal_entries = JournalEntry.reorder(:printed_on).where(conditions)
      journal_entries = journal_entries.joins(:financial_year).where('journal_entries.printed_on BETWEEN financial_years.started_on AND financial_years.stopped_on') # TODO: remove once journal entries will always have its financial_year_id associated to the printed_on
      if journal_entries.empty?
        redirect_to action: :show
        return
      end
      previous_draft_entries = JournalEntry.where(state: :draft).where('printed_on < ?', journal_entries.first.printed_on)
      previous_draft_entries = previous_draft_entries.joins(:financial_year).where('journal_entries.printed_on BETWEEN financial_years.started_on AND financial_years.stopped_on') # TODO: remove once journal entries will always have its financial_year_id associated to the printed_on
      if previous_draft_entries.any?
        notify_error(:draft_journal_entries_cannot_be_validated)
      else
        count = journal_entries.count
        JournalEntry.transaction do
          journal_entries.update_all(state: :confirmed, validated_at: Time.zone.now)
          JournalEntryItem.where(entry_id: journal_entries).update_all(state: :confirmed)
        end
        notify_success(:draft_journal_entries_have_been_validated, count: count)
      end
      redirect_to action: :show
    end
  end
end
