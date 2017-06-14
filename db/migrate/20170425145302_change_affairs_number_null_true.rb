class ChangeAffairsNumberNullTrue < ActiveRecord::Migration
  def change
    change_column_null :affairs, :number, true
  end
end
