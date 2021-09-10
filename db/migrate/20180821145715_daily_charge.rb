class DailyCharge < ActiveRecord::Migration
  def change
    unless column_exists?(:daily_charges, :activity)
      add_reference :daily_charges, :activity, foreign_key: true, index: true
    end
  end
end
