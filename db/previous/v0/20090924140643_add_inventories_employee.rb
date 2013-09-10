class AddInventoriesEmployee < ActiveRecord::Migration
  def self.up

    add_column :inventories, :employee_id, :integer,  :references=>:employees, :on_update=>:cascade, :on_delete=>:cascade
  end

  def self.down
    remove_column :inventories, :employee_id
  end
end
