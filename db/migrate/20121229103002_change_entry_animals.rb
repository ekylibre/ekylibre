class ChangeEntryAnimals< ActiveRecord::Migration
  def up
    add_column :animals, :income_reasons, :string
    add_column :animals, :outgone_reasons, :string
    remove_column :animals, :purchased_on
    remove_column :animals, :ceded_on
  end
  def down
    remove_column :animals, :income_reasons
    remove_column :animals, :outgone_reasons
  end
  
end