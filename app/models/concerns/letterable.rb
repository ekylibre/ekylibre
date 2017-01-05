# Provides methods to letter something from corresponding bank_statement_items.
# Used by Incoming and Outgoing Payments.
module Letterable
  extend ActiveSupport::Concern

  def letter_with(bank_statement_items)
    items = letterable_items(bank_statement_items)

    return false unless items

    letters = items.pluck(:letter)
    items.update_all(letter: nil)
    JournalEntryItem.pointed_by(items.first.bank_statement)
                    .where(bank_statement_letter: letters)
                    .update_all(bank_statement_letter: nil, bank_statement_id: nil)

    join_to_bank_statement_items(items)
  end

  protected

  def join_to_bank_statement_items(items)
    bank_statement = items.first.bank_statement
    letter = bank_statement.next_letter
    journal_entry
      .items
      .where(account_id: bank_statement.cash_account_id)
      .update_all(bank_statement_id: bank_statement.id, bank_statement_letter: letter)
    items.update_all(letter: letter)
    letter
  end

  def letterable_items(bank_statement_items)
    return false unless journal_entry && bank_statement_items.present?

    bank_statement = bank_statement_items.first.bank_statement
    return false unless mode.cash_id == bank_statement.cash_id

    items = BankStatementItem.where(id: bank_statement_items)
    bank_items_balance = items.sum(:debit) - items.sum(:credit)
    return false unless relative_amount == bank_items_balance
    items
  end
end
