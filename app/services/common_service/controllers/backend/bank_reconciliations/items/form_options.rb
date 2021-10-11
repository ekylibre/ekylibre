# frozen_string_literal: true

module CommonService
  module Controllers
    module Backend
      module BankReconciliations
        module Items
          class FormOptions
            def initialize(bank_statement:, bank_statements:, period_start:, period_end:, items_grouped_by_date:, params:)
              @bank_statement = bank_statement
              @bank_statements = bank_statements
              @period_start = period_start
              @period_end = period_end
              @items_grouped_by_date = items_grouped_by_date
              @various_journals = Journal.various
              @cash_id = @bank_statements.map(&:cash_id)&.compact&.uniq&.first || @bank_statement.cash.id
              @params = params
            end

            def call
              {
                initial_balance_debit: @bank_statements.sum(:initial_balance_debit),
                initial_balance_credit: @bank_statements.sum(:initial_balance_credit),
                is_disabled: form_options_field_is_disable?,
                precision: Onoma::Currency.find(@bank_statements.map(&:currency).uniq.first).precision,
                cash_id: @cash_id,
                various_journals: @various_journals,
                journal_url_params: form_options_journal_url_params,
                url_redirect_params: form_options_url_redirect_params,
                purchase_natures: PurchaseNature.find_each,
                sale_natures: SaleNature.find_each,
                period_items: form_options_period_items,
                add_line_button: form_options_add_line_button,
              }
            end

            private

              def form_options_field_is_disable?
                financial_years = FinancialYear.out_of_date_range(@period_start)
                exchanges = FinancialYearExchange.where("(started_on >= ? OR stopped_on <= ?)", @period_start, @period_start).opened
                financial_years.count != 1 || exchanges.any?
              end

              def form_options_journal_url_params
                @various_journals.each_with_object([]) do |regul_journal, journal_array|
                  base_params = { journal_id: regul_journal.id }
                  base_params[:cash_id] = @cash_id
                  base_params[:name] = regul_journal.name
                  base_params[:bank_statement_id] = @bank_statement.id unless @bank_statement.nil?
                  base_params[:period_start] = @params[:period_start] if @params[:period_start].present?
                  base_params[:period_end] = @params[:period_end] if @params[:period_end].present?
                  journal_array << base_params
                end
              end

              def form_options_url_redirect_params
                url_redirect_params = { cash_id: @cash_id }
                url_redirect_params[:bank_statement_id] = @bank_statement.id unless @bank_statement.nil?
                url_redirect_params[:period_start] = @params[:period_start] if @params[:period_start].present?
                url_redirect_params[:period_end] = @params[:period_end] if @params[:period_end].present?
                url_redirect_params
              end

              def form_options_period_items
                (@period_start..@period_end).each_with_object([]) do |date, array|
                  items_grouped_by_date = @items_grouped_by_date.fetch(date, [])
                  cash_bank_statetment_on_date = BankStatement.on(date).for_cash(@cash_id).first
                  array << {
                    items_grouped_by_date: items_grouped_by_date,
                    cash_bank_statetment_on_date: cash_bank_statetment_on_date,
                    should_create: items_grouped_by_date.any? || cash_bank_statetment_on_date.present?,
                    locked_item: FinancialYearExchange.opened.at(date).exists?,
                    date: date,
                  }
                end
              end

              def form_options_add_line_button
                bank_statements = []
                bank_statement_dates_ranges = {}
                bank_statement_ids = @items_grouped_by_date.values
                                                          .flatten
                                                          .select { |object| object.is_a?(BankStatementItem) }
                                                          .map(&:bank_statement_id)
                                                          .uniq

                bank_statements_collection = BankStatement.where(id: bank_statement_ids).map{ |bs| [bs.id, bs] }.to_h
                bank_statement_dates_ranges = bank_statements.map do |item|
                  {
                    start: bank_statements_collection[item.bank_statement_id].started_on,
                    end: bank_statements_collection[item.bank_statement_id].stopped_on,
                  }
                end.uniq
              end
          end
        end
      end
    end
  end
end
