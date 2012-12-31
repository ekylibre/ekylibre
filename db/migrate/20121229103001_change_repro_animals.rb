class ChangeReproAnimals< ActiveRecord::Migration
  def change
    add_column :animals, :is_reproductor, :boolean, :default => false, :null => false
    add_column :animals, :is_external, :boolean, :default => false, :null => false
  end
end