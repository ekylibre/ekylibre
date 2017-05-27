class CreateAlertPhases < ActiveRecord::Migration
  def change
    create_table :alert_phases do |t|
      t.references :alert, index: true, foreign_key: true, null: false
      t.datetime :started_at, null: false
      t.integer :level, null: false

      t.stamps
    end
  end
end
