class ChangeLifeDurationTypeToDecimal < ActiveRecord::Migration[4.2]
  def up
    change_column :activities, :life_duration, 'decimal(5,2) USING CAST(life_duration AS decimal(5,2))'
  end

  def down
    change_column :activities, :life_duration, 'integer USING CAST(life_duration AS integer)'
  end
end
