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

module Backend
  class AssociatesController < Backend::BaseController
    manage_restfully t3e: { entity_name: :entity_name }

    # unroll entity: :name

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :started_on, url: true
      t.column :entity, url: true
      t.column :associate_nature
      t.column :share_quantity, class: "center-align"
      t.column :percentage_on_company, percentage: true, class: "center-align"
      t.column :associate_account, url: true
      t.column :balance, class: "right-align", currency: true
      t.column :description, hidden: true
    end

    list(:associate_journal_entry_items, model: :journal_entry_items, joins: :entry, conditions: ['journal_entries.financial_year_id = ? AND account_id = ?', 'params[:current_financial_year]'.c, "Associate.find_by(id: params[:id]).associate_account_id".c], line_class: "(RECORD.completely_lettered? ? 'lettered-item' : '')".c, order: "printed_on DESC, #{JournalEntryItem.table_name}.position", export_class: ListExportJob) do |t|
      t.column :journal, url: true
      t.column :entry_number, url: true
      t.column :printed_on, datatype: :date, label: :column
      t.column :name
      t.column :state_label
      t.column :letter
      t.column :main_client_or_supplier_account, through: :entry, url: true
      t.column :real_debit,  currency: :real_currency, hidden: true
      t.column :real_credit, currency: :real_currency, hidden: true
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, on_select: :sum
      t.column :absolute_credit, currency: :absolute_currency, on_select: :sum
    end

  end
end
