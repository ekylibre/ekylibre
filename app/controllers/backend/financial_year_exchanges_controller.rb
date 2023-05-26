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
    manage_restfully only: %i[new show]

    list(:journal_entries, conditions: { financial_year_exchange_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :number, url: true
      t.column :continuous_number
      t.column :printed_on, datatype: :date
      t.column :journal, url: true
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :letter
      t.column :isacompta_letter
      t.column :bank_statement_number
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
    end

    def create
      ActiveRecord::Base.transaction do
        @financial_year_exchange = FinancialYearExchange.new(permitted_params)
        if @financial_year_exchange.save
          notify_success(:record_x_created, record: 'activerecord.models.financial_year_exchange'.t, name: @financial_year_exchange.id)

          if @financial_year_exchange.isacompta?
            puts @financial_year_exchange.exported_journal_ids.inspect.yellow
            journal_ids = @financial_year_exchange.exported_journal_ids
            if journal_ids.any?
              missing_code_exchanged_journals = Journal.where(id: journal_ids).where(isacompta_code: [nil, ""])
            else
              missing_code_exchanged_journals = Journal.where(isacompta_code: [nil, ""])
            end
            puts missing_code_exchanged_journals.inspect.yellow
            if missing_code_exchanged_journals.count > 0
              journals_link = missing_code_exchanged_journals.map do |journal|
                view_context.link_to(journal.name, edit_backend_journal_url(journal))
              end.join(', ')
              notify(:complete_isacompta_journal_code_html.tl(journals_link: journals_link), html: true)
            end
            # warning about isacompta code on vat
            taxes = Tax.where(active: true).where('collect_isacompta_code IS NULL OR deduction_isacompta_code IS NULL OR fixed_asset_deduction_isacompta_code IS NULL OR fixed_asset_collect_isacompta_code IS NULL')
            if taxes.any? && taxes.count > 0
              taxes_link = taxes.map do |tax|
                view_context.link_to(tax.name, edit_backend_tax_url(tax))
              end.join(', ')
              notify(:complete_isacompta_tax_code_html.tl(taxes_link: taxes_link), html: true)
            end
          end
          redirect_to(backend_financial_year_url(@financial_year_exchange.financial_year))
        else
          render(:new)
        end
      end
    end

    def journal_entries_export
      return unless (exchange = find_and_check)

      if exchange.format == 'isacompta'
        # check if a isacompta code is missing on a Model link to a segment
        if exchange.transmit_isacompta_analytic_codes
          missing_segment = 0
          AnalyticSegment.all.each do |segment|
            missing_code_count = segment.name.classify.constantize.where(isacompta_analytic_code: [nil, ""]).count
            if missing_code_count > 0
              missing_segment += missing_code_count
              notify_error :fill_analytic_codes_of_your_activities.tl(segment: segment.name.text.downcase, missing_code_count: missing_code_count)
            end
          end
          if missing_segment > 0
            redirect_to_back
            return
          end
        end
        # redirect to back if no isacompta journal code exist
        if exchange.exported_journal_ids.any?
          missing_code_exchanged_journals = Journal.where(id: exchange.exported_journal_ids).where(isacompta_code: [nil, ""], isacompta_label: [nil, ""])
        else
          missing_code_exchanged_journals = Journal.where(isacompta_code: [nil, ""], isacompta_label: [nil, ""])
        end
        if missing_code_exchanged_journals.count > 0
          notify_error(:complete_isacompta_journal_code_html.tl(journals_link: view_context.link_to(missing_journal_isacompta.count, { controller: "/backend/journals", action: :index })), html: true)
          redirect_to_back
          return
        end
        # warning about isacompta code on vat
        taxes = Tax.where(active: true).where(collect_isacompta_code: nil, deduction_isacompta_code: nil, fixed_asset_deduction_isacompta_code: nil, fixed_asset_collect_isacompta_code: nil)
        if taxes.any? && taxes.count > 0
          taxes_link = taxes.map do |tax|
            view_context.link_to(tax.name, edit_backend_tax_url(tax))
          end.join(', ')
          notify_error(:complete_isacompta_tax_code_html.tl(taxes_link: taxes_link), html: true)
          redirect_to_back
          return
        end
      end
      # generate export
      FinancialYearExchangeExportJob.perform_later(exchange, params[:format], exchange.transmit_isacompta_analytic_codes, current_user)
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
        FinancialYearExchangeExportJob.perform_later(exchange, params[:format], exchange.transmit_isacompta_analytic_codes, current_user, notify_accountant: true)
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
