class AddToolList < ActiveRecord::Migration
  def self.up
    add_column :shape_operations, :tools_list, :string

  end

  def self.down
    remove_column :shape_operations, :tools_list
  end
end
