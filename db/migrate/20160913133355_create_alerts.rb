class CreateAlerts < ActiveRecord::Migration
  def change
    create_table :alerts do |t|
      t.references :sensor, index: true, foreign_key: true
      t.string :nature, null: false

      t.stamps
    end
  end
end
