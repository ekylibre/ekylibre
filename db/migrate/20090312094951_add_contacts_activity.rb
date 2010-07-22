class AddContactsActivity < ActiveRecord::Migration
  def self.up
    add_column :contacts, :code, :string, :limit=>4
    add_column :contacts, :active, :boolean, :null=>false, :default=>false
    add_column :contacts, :started_at, :datetime
    add_column :contacts, :stopped_at, :datetime

    execute "UPDATE contacts SET code=id"

    add_index  :contacts, :code
    add_index  :contacts, :active
    add_index  :contacts, :started_at
    add_index  :contacts, :stopped_at
  end

  def self.down
    remove_column :contacts, :stopped_at
    remove_column :contacts, :started_at
    remove_column :contacts, :active
    remove_column :contacts, :code
  end

end
