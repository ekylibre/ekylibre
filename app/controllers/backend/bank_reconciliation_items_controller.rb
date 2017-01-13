module Backend
  # Handles bank reconciliation.
  class BankReconciliationItemsController < Backend::BaseController
    def index
      return unless find_bank_statement

      set_period!
      bank_statement_items = @bank_statement.items
      journal_entry_items  = @bank_statement.eligible_journal_entry_items
                                            .between(@period_start, @period_end)

      return no_entries if journal_entry_items.blank?

      auto_reconciliate!(bank_statement_items, journal_entry_items)

      @items_grouped_by_date = group_by_date(bank_statement_items + journal_entry_items)

      t3e @bank_statement, cash: @bank_statement.cash_name, started_on: @bank_statement.started_on, stopped_on: @bank_statement.stopped_on
    end

    private

    def find_bank_statement
      @bank_statement = BankStatement.find_by(id: params[:bank_statement_id])
      @bank_statement || (head(:bad_request) && nil)
    end

    def set_period!
      @period_start = @bank_statement.started_on - 20.days
      @period_end   = @bank_statement.stopped_on + 20.days

      [:start, :end].each do |boundary|
        next unless params[:"period_#{boundary}"]
        date = Date.strptime(params[:"period_#{boundary}"], '%Y-%m-%d')
        instance_variable_set("@period_#{boundary}", date)
      end
    end

    def no_entries
      notify_error :need_entries_to_reconciliate
      redirect_to params[:redirect] || backend_bank_statement_path(@bank_statement)
    end

    def auto_reconciliate!(items, entries)
      items.where(letter: nil).find_each do |bank_item|
        next unless item_is_unique?(bank_item, others: items.where.not(id: bank_item.id))

        matching_entry = entries.where(printed_on: bank_item.transfered_on,
                                       credit: bank_item.debit,
                                       debit: bank_item.credit,
                                       bank_statement_letter: nil)
        next if matching_entry.count(:id) != 1

        @bank_statement.letter_items(items.where(id: bank_item), matching_entry)
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
      items.each(&:reload).group_by do |item|
        attributes = item.attributes
        attributes['transfered_on'] || attributes['printed_on']
      end.sort.to_h
    end
  end
end
