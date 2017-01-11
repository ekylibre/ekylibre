module Backend
  class BankReconciliationGapsController < Backend::BaseController
    def create
      return head :bad_request unless @bank_statement = BankStatement.find(params[:bank_statement_id])

      bank_statement_items = fetch_bank_items
      journal_entry_items  = fetch_journal_items

      bank_sold    = bank_statement_items.sum(:credit) - bank_statement_items.sum(:debit)
      journal_sold = journal_entry_items.sum(:credit)  - journal_entry_items.sum(:debit)

      gap = bank_sold + journal_sold

      mode = gap > 0 ? :debit : :credit
      shortest = Account.of_usage(:other_usual_running_profits).minimum('LENGTH(number)')
      credit_gap_account = Account.of_usage(:other_usual_running_profits).where("LENGTH(number) = #{shortest}").first

      shortest = Account.of_usage(:other_usual_running_profits).minimum('LENGTH(number)')
      debit_gap_account = Account.of_usage(:other_usual_running_expenses).where("LENGTH(number) = #{shortest}").first

      statement_account = @bank_statement.cash.account

      debit_account  = debit_gap_account
      credit_account = statement_account
      if mode == :debit
        debit_account  = statement_account
        credit_account = credit_gap_account
      end

      return head :bad_request unless debit_account && credit_account

      entry = JournalEntry.create!(
        journal_entry_params.merge(
          currency: @bank_statement.currency,
          printed_on: Time.zone.now,
          items_attributes:
          {
            '0' => {
              name: "#{'rest.actions.payment_gap'.t} #{Time.zone.today.l} - #{debit_account.name}",
              real_debit: gap.abs,
              account_id: debit_account.id
            },
            '-1' => {
              name: "#{'rest.actions.payment_gap'.t} #{Time.zone.today.l} - #{credit_account.name}",
              real_credit: gap.abs,
              account_id: credit_account.id
            }
          }
        )
      )

      entry_items_to_letter = JournalEntryItem.where(id: journal_entry_items + entry.items.where(account_id: statement_account.id))
      letter = @bank_statement.letter_items(bank_statement_items, entry_items_to_letter)

      return head :bad_request unless letter
      first_item = bank_statement_items.order(transfered_on: :asc).first
      redirect_to reconciliation_backend_bank_statement_path(@bank_statement, scroll_to: first_item.id)
    end

    private

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
