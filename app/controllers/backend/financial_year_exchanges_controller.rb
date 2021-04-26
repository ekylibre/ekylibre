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
      t.column :continuous_number
      t.column :printed_on, datatype: :date
      t.column :journal, url: true
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :letter
      t.column :bank_statement_number
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
    end

    def journal_entries_export
      return unless (exchange = find_and_check)

      FinancialYearExchangeExportJob.perform_later(exchange, params[:format], current_user)
      notify_success(:document_in_preparation)
      redirect_to_back
    end

    def journal_entries_import
      return unless (@exchange = find_and_check)

      notify_import_warning
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
      return unless (exchange = find_and_check)

      if exchange.accountant_email?
        exchange.generate_public_token!
        FinancialYearExchangeExportJob.perform_later(exchange, params[:format], current_user, notify_accountant: true)
        notify_success :document_in_preparation
      else
        notify_error :accountant_without_email
      end
      redirect_to_back
    end

    def notify_accountant_modal
      render partial: 'backend/financial_year_exchanges/notify_accountant_modal', locals: { id: params[:id] }
    end

    def close
      return unless (@exchange = find_and_check)

      @exchange.close!
      notify_success :closed_financial_year_exchange
      redirect_to_back
    end

    private

      def notify_import_warning
        warnings = []
        warnings = :journals_import.tl[:warnings]
        return if warnings.empty?

        notify_warning_now(:before_journal_import_assumed_format_x, x: as_list(warnings), html: true)
      end

      # @param [Array<String>] elements
      # @return [String] HTML representation of a list that contains all the elements in `elements`
      def as_list(elements)
        helpers.content_tag(:ul) do
          elements.map do |element|
            helpers.content_tag(:li, element)
          end.join.html_safe
        end
      end
  end
end
