class CreateFinancialYearExchanges < ActiveRecord::Migration
  def change
    create_table :financial_year_exchanges do |t|
      t.references :financial_year, null: false, index: true
      t.date :started_on, null: false
      t.date :stopped_on, null: false
      t.datetime :closed_at
      t.stamps
    end
  end
end
