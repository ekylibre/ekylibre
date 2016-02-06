class UpdateProducts < ActiveRecord::Migration
  def replace_items_in_array(table, column, options = {})
    conditions = '1=1'
    if options[:reference_name]
      conditions = "reference_name = '#{options[:reference_name]}'"
    end

    # ex of column = abilities_list
    say "replace item in array #{table}##{column}  #{options.inspect}"

    if options[:old] && options[:new]
      execute("UPDATE #{table} SET #{column} = REPLACE(#{column}, '#{options[:old]}', '#{options[:new]}') WHERE #{column} LIKE '%#{options[:old]}%' AND #{conditions}")
    elsif options[:new]
      execute("UPDATE #{table} SET #{column} = COALESCE(NULLIF(#{column}, '') || ', #{options[:new]}',  '#{options[:new]}') WHERE #{conditions}")
    elsif options[:old]
      execute("UPDATE #{table} SET #{column} = REPLACE(REPLACE(REPLACE(#{column}, ', #{options[:old]}', ''), '#{options[:old]}', ''), '#{options[:old]},', '') WHERE #{conditions}")
    else
      raise StandardException
    end
  end

  PRODUCT_ITEMS = [
    { table: 'products', column: 'variety', old: 'mineral_matter', new: 'preparation' },
    { table: 'products', column: 'variety', old: 'organic_matter', new: 'excrement' },

    { table: 'products', column: 'variety', old: 'herbicide', new: 'preparation' },
    { table: 'products', column: 'variety', old: 'fungicide', new: 'preparation' },
    { table: 'products', column: 'variety', old: 'additive', new: 'preparation' },
    { table: 'products', column: 'variety', old: 'insecticide', new: 'preparation' },
    { table: 'products', column: 'variety', old: 'chemical_fertilizer', new: 'preparation' },
    { table: 'products', column: 'variety', old: 'molluscicide', new: 'preparation' },

    { table: 'products', column: 'variety', old: 'animal_medicine', new: 'preparation' },
    { table: 'products', column: 'variety', old: 'disinfectant', new: 'preparation' },
    { table: 'products', column: 'variety', old: 'bottling', new: 'equipment' },

    { table: 'products', column: 'type', old: 'OrganicMatter', new: 'Matter' },
    { table: 'products', column: 'type', old: 'MineralMatter', new: 'Matter' },
    { table: 'products', column: 'type', old: 'AnimalMedicine', new: 'Matter' },
    { table: 'products', column: 'type', old: 'PlantMedicine', new: 'Matter' },
    { table: 'products', column: 'type', old: 'Medicine', new: 'Matter' }
  ].freeze

  def up
    # check if product_nature is present in DB and update it with new values
    for item in PRODUCT_ITEMS
      replace_items_in_array(item[:table], item[:column], item)
    end
  end

  def down
    raise IrreversibleMigration
  end
end
