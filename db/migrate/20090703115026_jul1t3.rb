class Jul1t3 < ActiveRecord::Migration
  def self.up

    add_column :users, :admin, :boolean, :null=>false, :default=>true
    add_column :users, :rights, :text
  end

  def self.down
    remove_column :users, :rights
    remove_column :users, :admin
  end
end
