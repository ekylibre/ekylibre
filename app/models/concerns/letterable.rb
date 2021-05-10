# frozen_string_literal: true

# Provides methods to letter something from corresponding bank_statement_items.
# Used by Incoming and Outgoing Payments.
module Letterable
  extend ActiveSupport::Concern

  def letter_with(bank_statement_items)
    return false unless bank_statement_items

    join_to_bank_statement_items(bank_statement_items)
  end

  protected

    def join_to_bank_statement_items(bank_statement_items)
      return false unless journal_entry && bank_statement_items.present?

      if bank_statement_items.is_a?(Array)
        ids = bank_statement_items.map(&:id).compact.uniq
        bank_statement_items = BankStatementItem.where(id: ids)
      end

      cash = bank_statement_items.first.cash
      bank_statement_id = bank_statement_items.first.bank_statement.id
      letter = cash.next_reconciliation_letter
      jeis = JournalEntryItem
        .where(id: journal_entry.items.to_a
                                .select { |item| item.balance == relative_amount })

      jeis_accounts = jeis.map(&:account).uniq
      bsis_accounts = bank_statement_items.map(&:cash).map(&:account).uniq
      return false if jeis_accounts.size > 1 || bsis_accounts.size > 1 || jeis_accounts.first != bsis_accounts.first

      return false if jeis.sum(:balance).abs != bank_statement_items.map(&:balance).sum.abs

      transaction do
        jeis.update_all(bank_statement_letter: letter, bank_statement_id: bank_statement_id)
        bank_statement_items.update_all(letter: letter)
      end
    end

    def letterable_items(bank_statement_items)
      return false unless journal_entry && bank_statement_items.present?

      cash_id = bank_statement_items.first.cash.id
      return false unless mode.cash_id == cash_id

      # items = BankStatementItem.where(id: bank_statement_items)
      bank_items_balance = bank_statement_items.map(&:credit).compact.sum - bank_statement_items.map(&:debit).compact.sum
      return false unless relative_amount == bank_items_balance

      bank_statement_items
    end
end
