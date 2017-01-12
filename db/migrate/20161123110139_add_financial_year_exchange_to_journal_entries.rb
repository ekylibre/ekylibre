class AddFinancialYearExchangeToJournalEntries < ActiveRecord::Migration
  def change
    add_reference :journal_entries, :financial_year_exchange, index: true
  end
end
