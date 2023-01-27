class DailyCharge < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:daily_charges, :activity)
      add_reference :daily_charges, :activity, foreign_key: true, index: true
    end
  end
end
