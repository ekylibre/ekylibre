class ChangeAffairsNumberNullTrue < ActiveRecord::Migration[4.2]
  def change
    change_column_null :affairs, :number, true
  end
end
