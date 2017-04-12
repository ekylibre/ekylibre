class RegularizeDemoPreference < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE preferences SET nature = 'boolean', boolean_value = false, string_value = NULL, integer_value = NULL, decimal_value = NULL WHERE name = 'demo' AND nature != 'boolean'
    SQL
  end
end
