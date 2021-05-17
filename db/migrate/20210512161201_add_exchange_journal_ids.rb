class AddExchangeJournalIds < ActiveRecord::Migration[5.0]
  def change
    add_column :financial_year_exchanges, :exported_journal_ids, :string, array: true, default: []
  end
end
