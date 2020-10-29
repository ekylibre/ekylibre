module Backend
  module BankReconciliation
    # Handles bank reconciliation.
    class ItemsController < Backend::BaseController
      def index
        return unless find_bank_statement

        set_period!
        reconciliate_one(@bank_statement)

        @items_grouped_by_date = group_by_date(@items)

        t3e @bank_statement, cash: @bank_statement.cash_name, started_on: @bank_statement.started_on.l, stopped_on: @bank_statement.stopped_on.l
      end

      def reconciliate
        return unless cash = find_cash
        return unless @bank_statements = find_bank_statements(cash)

        cash = cash.first if cash.is_a?(Array)
        set_period!

        @items = cash.unpointed_journal_entry_items.between(@period_start, @period_end)

        @bank_statements.each do |bank_statement|
          reconciliate_one(bank_statement)
        end

        @items_grouped_by_date = group_by_date(@items)

        t3e cash: cash.name, started_on: @period_start.l, stopped_on: @period_end.l
      end

      def count
        return unless cash = find_cash
        return unless @bank_statements = find_bank_statements(cash)

        set_period!

        count = @bank_statements.map { |bank_statement| bank_statement.items.transfered_between(@period_start, @period_end) }.flatten.count

        respond_to do |format|
          format.json { render json: count }
        end
      end

      private

      def find_cash
        find_and_check :cash, params[:cash_id]
      end

      def find_bank_statement
        @bank_statement = find_and_check :bank_statement, params[:bank_statement_id]
      end

      def find_bank_statements(cash)
        @bank_statements = BankStatement.where(cash: cash.id)

        if @bank_statements
          @bank_statements = @bank_statements.between(params[:period_start].to_date.beginning_of_day, params[:period_end].to_date.end_of_day)
        end

        return @bank_statements if @bank_statements.present?

        notify_error :no_bank_statement_found_for_this_period
        redirect_to_back
        false
      end

      def reconciliate_one(bank_statement)
        bank_statement_items = bank_statement.items unless @bank_statement.nil?
        bank_statement_items = bank_statement.items.transfered_between(@period_start, @period_end) unless @bank_statements.nil?

        @journal_entry_items ||= bank_statement.eligible_entries_in(@period_start, @period_end)

        return no_entries if @journal_entry_items.blank? && @bank_statements.nil?

        auto_reconciliate!(bank_statement, bank_statement_items, @journal_entry_items)

        @items = [] if @items.nil?
        @items += bank_statement_items + @journal_entry_items
      end

      def set_period!
        @period_start = @bank_statement.started_on - 20.days if params[:bank_statement_id].present?
        @period_end   = @bank_statement.stopped_on + 20.days if params[:bank_statement_id].present?

        %i[start end].each do |boundary|
          next unless params[:"period_#{boundary}"].present?
          date = Date.strptime(params[:"period_#{boundary}"], '%Y-%m-%d')
          instance_variable_set("@period_#{boundary}", date)
        end

        @period_start ||= (Date.today - 20.days).at_beginning_of_month
        @period_end ||= Date.today
      end

      def no_entries
        notify_error :need_entries_to_reconciliate
        redirect_to params[:redirect] if params[:redirect].present?
        backend_bank_statement_path(@bank_statement) unless @bank_statement.nil?
        backend_bank_statements_path(@bank_statements) unless @bank_statements.nil?
      end

      def auto_reconciliate!(bank_statement, items, entries)
        items.where(letter: nil).find_each do |bank_item|
          next unless item_is_unique?(bank_item, others: items.where.not(id: bank_item.id))

          matching_entry = entries.where(printed_on: bank_item.transfered_on,
                                         credit: bank_item.debit,
                                         debit: bank_item.credit,
                                         bank_statement_letter: nil)
          next if matching_entry.count(:id) != 1

          bank_statement.letter_items(items.where(id: bank_item), matching_entry)
        end
      end

      def item_is_unique?(item, others: [])
        others
          .where(transfered_on: item.transfered_on,
                 debit: item.debit,
                 credit: item.credit)
          .blank?
      end

      def group_by_date(items)
        return {} if items.nil?

        items.each(&:reload).group_by do |item|
          attributes = item.attributes
          attributes['transfered_on'] || attributes['printed_on']
        end.sort.to_h
      end
    end
  end
end
