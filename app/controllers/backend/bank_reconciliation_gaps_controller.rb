module Backend
  # Handles creation of 'Various Operations' from bank_statement_items + journal_entry_items.
  class BankReconciliationGapsController < Backend::BaseController
    def create
      @bank_statement = BankStatement.find(params[:bank_statement_id])
      @cash = Cash.find(params[:cash_id]) 
      
      return head :bad_request unless @cash
      # return head :bad_request unless @bank_statement
      
      bank_statement_items = fetch_bank_items
      journal_entry_items  = fetch_journal_items

      gap = sold(bank_statement_items, journal_entry_items)

      return unless (accs = accounts(gap))
      new_entry = regul_entry_for(gap.abs, *accs)
      return head :bad_request unless new_entry

      letter_and_redirect bank_statement_items,
                          fuse_items(journal_entry_items,
                                     with_matching_items_of: new_entry)
    end

    private

    def accounts(gap)
      bank = @cash.account
      if gap > 0
        return (head(:bad_request) && nil) unless Account.of_usage(:other_usual_running_profits).count.nonzero?
        return [bank, credit_gap_account]
      end
      return (head(:bad_request) && nil) unless Account.of_usage(:other_usual_running_expenses).count.nonzero?
      [debit_gap_account, bank]
    end

    def sold(bank_items, journal_items)
      [bank_items, journal_items].map { |items| items.sum(:credit) - items.sum(:debit) }
                                 .sum
    end

    def credit_gap_account
      shortest = Account.of_usage(:other_usual_running_profits).minimum('LENGTH(number)')
      Account.of_usage(:other_usual_running_profits).where("LENGTH(number) = #{shortest}").first
    end

    def regul_entry_for(amount, debit, credit)
      return false unless debit && credit
      JournalEntry.create!(
        journal_entry_params.merge(
          currency: @cash.currency,
          printed_on: Time.zone.now,
          items_attributes:
          {
            '0' => item_for(amount, debit, :debit),
            '-1' => item_for(amount, credit, :credit)
          }
        )
      )
    end

    def fuse_items(source_items, with_matching_items_of: [])
      JournalEntryItem.where(id: source_items + with_matching_items_of.items.where(account_id: @bank_statement.cash_account_id))
    end

    def item_for(amount, account, key)
      {
        name: "#{'rest.actions.payment_gap'.t} #{Time.zone.today.l} - #{account.name}",
        "real_#{key}": amount,
        account_id: account.id
      }
    end

    def letter_and_redirect(bank_items, entry_items)
      head :bad_request unless @cash.letter_items(bank_items, entry_items)

      redirect_to backend_bank_statement_bank_reconciliation_items_path(@bank_statement, scroll_to: bank_items.order(transfered_on: :asc).first.id) unless @bank_statement.nil?
      
      redirect_to reconciliate_bank_statements_backend_bank_reconciliation_items_path(cash_id: @cash.id, scroll_to: bank.items.order(transfered_on: :asc).first.id) unless @bank_statements.nil?
    end

    def debit_gap_account
      shortest = Account.of_usage(:other_usual_running_expenses).minimum('LENGTH(number)')
      Account.of_usage(:other_usual_running_expenses).where("LENGTH(number) = #{shortest}").first
    end

    def fetch_bank_items
      params[:bank_statement_item_ids] ? BankStatementItem.where(id: params[:bank_statement_item_ids]) : BankStatementItem.none
    end

    def fetch_journal_items
      params[:journal_entry_item_ids]  ? JournalEntryItem.where(id: params[:journal_entry_item_ids])   : JournalEntryItem.none
    end

    def journal_entry_params
      params.permit(:journal_id)
    end
  end
end
