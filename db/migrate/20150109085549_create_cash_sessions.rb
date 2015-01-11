class CreateCashSessions < ActiveRecord::Migration
  def change
    create_table :cash_sessions do |t|
      t.datetime :started_at
      t.datetime :stopped_at
      t.string :currency
      t.float :noticed_start_amount
      t.float :noticed_stop_amount
      t.float :expected_stop_amount
      t.references :sequence, index: true
      t.references :affair, index: true
      t.references :cash, index: true

      t.stamps
    end
  end
end
