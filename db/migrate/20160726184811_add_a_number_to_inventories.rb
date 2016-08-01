class AddANumberToInventories < ActiveRecord::Migration
  def up
    execute "UPDATE inventories SET number = 'I' || LPAD(id::VARCHAR, 8, '0') WHERE number IS NULL OR LENGTH(TRIM(number)) <= 0"
    change_column_null :inventories, :number, false
    execute "INSERT INTO sequences (name, number_format, number_start, number_increment, period, usage, created_at, updated_at) SELECT 'Inventories', 'I[number|8]', iv.max + 1, 1, 'number', 'inventories', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM (SELECT count(*) AS count FROM sequences WHERE usage = 'inventory') AS sq, (SELECT max(id) AS max FROM inventories) AS iv WHERE sq.count <= 0 AND iv.max IS NOT NULL"
  end

  def down
    # Nothing to do
  end
end
