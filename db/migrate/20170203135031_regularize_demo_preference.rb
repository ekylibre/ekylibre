class RegularizeDemoPreference < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE preferences SET nature = 'boolean', boolean_value = false, string_value = NULL, integer_value = NULL, decimal_value = NULL WHERE name = 'demo' AND nature != 'boolean'
    SQL
  end
end
