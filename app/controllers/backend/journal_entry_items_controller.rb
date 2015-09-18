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

class Backend::JournalEntryItemsController < Backend::BaseController
  unroll :entry_number, :name, :real_debit, :real_credit, :currency, account: :number

  def new
    @journal_entry_item = JournalEntryItem.new
    @journal_entry_item.name = params[:name] if params[:name]
    if params['entry-real-debit'] && params['entry-real-credit']
      debit = params['entry-real-debit'].to_f
      credit = params['entry-real-credit'].to_f
      if debit > credit
        @journal_entry_item.real_credit = debit - credit
      else
        @journal_entry_item.real_debit = credit - debit
      end
    end
    if params[:journal_id] && @journal = Journal.find_by(id: params[:journal_id])
      if @journal.cashes.count == 1
        @journal_entry_item.account = @journal.cashes.first.account
      end
    end
    params[:printed_on] = (params[:printed_on] =~ %r(\d\d\d\d-\d\d-\d\d)) ? params[:printed_on].to_date : nil
    if params[:printed_on]
      @financial_year = FinancialYear.at(params[:printed_on])
    end
    if request.xhr?
      render partial: 'backend/journal_entry_items/row_form', object: @journal_entry_item
    else
      redirect_to_back
    end
  end

  def show
    if @journal_entry_item = JournalEntryItem.find_by(id: params[:id])
      redirect_to backend_journal_entry_url(@journal_entry_item.entry_id)
    else
      redirect_to backend_root_url
    end
  end
end
