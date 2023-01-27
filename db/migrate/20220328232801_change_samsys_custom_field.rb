class ChangeSamsysCustomField < ActiveRecord::Migration[5.0]

  # change type_name for 'Modèle' of an Equipment to mod_name in custom_fields and Equipment
  def up
    execute <<~SQL
      UPDATE custom_fields SET column_name = 'mod_name' WHERE name = 'Modèle' AND customized_type = 'Equipment'
    SQL
    execute <<~SQL
      UPDATE products SET custom_fields = replace(custom_fields::text, '"field_name"', '"mod_name"')::jsonb WHERE type = 'Equipment'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE custom_fields SET column_name = 'field_name' WHERE name = 'Modèle' AND customized_type = 'Equipment'
    SQL
    execute <<~SQL
      UPDATE products SET custom_fields = replace(custom_fields::text, '"mod_name"', '"field_name"')::jsonb WHERE type = 'Equipment'
    SQL
  end
end
