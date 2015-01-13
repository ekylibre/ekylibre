class AddCashSessions < ActiveRecord::Migration
  def change

    create_table :cash_sessions do |t|
      t.references :cash,                 null: false, index: true
      t.references :sequence,                          index: true
      t.datetime   :started_at,           null: false
      t.datetime   :stopped_at
      t.string     :currency, limit: 3
      t.decimal    :noticed_start_amount, default: 0.0, precision: 19, scale: 4
      t.decimal    :noticed_stop_amount,  default: 0.0, precision: 19, scale: 4
      t.decimal    :expected_stop_amount, default: 0.0, precision: 19, scale: 4
      t.stamps
    end

    change_table :affairs do |t|
      t.references :cash_session,                      index: true
    end

  end
end
