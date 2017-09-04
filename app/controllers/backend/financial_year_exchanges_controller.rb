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
  class FinancialYearExchangesController < Backend::BaseController
    manage_restfully only: %i[new create show]

    list(:journal_entries, conditions: { financial_year_exchange_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :number, url: true
      t.column :printed_on
      t.column :journal, url: true
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
    end

    def journal_entries_export
      return unless (@exchange = find_and_check)
      export = FinancialYearExchangeExport.new(@exchange)
      export.export(params[:format]) do |file, name|
        send_data File.read(file), filename: name
      end
    end

    def journal_entries_import
      return unless (@exchange = find_and_check)
      if request.post?
        file = params[:upload]
        @import = FinancialYearExchangeImport.new(file, @exchange)
        if @import.run
          notify_success :journal_entries_imported
          redirect_to_back
          return
        end
      end
    end

    def notify_accountant
      return unless (@exchange = find_and_check)
      if @exchange.accountant_email?
        @exchange.generate_public_token!
        FinancialYearExchangeExportMailer.notify_accountant(@exchange, current_user).deliver_now
        notify_success :accountant_notified
      else
        notify_error :accountant_without_email
      end
      redirect_to_back
    end

    def close
      return unless (@exchange = find_and_check)
      @exchange.close!
      notify_success :closed_financial_year_exchange
      redirect_to_back
    end
  end
end
