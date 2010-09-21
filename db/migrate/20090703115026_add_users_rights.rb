class AddUsersRights < ActiveRecord::Migration
  def self.up
    add_column :users, :admin, :boolean, :null=>false, :default=>true
    add_column :users, :rights, :text    
    execute "UPDATE #{quote_table_name(:users)} SET rights='administrate' WHERE rights IS NULL"    
  end
  
  def self.down
    remove_column :users, :rights
    remove_column :users, :admin
  end
end
