class AddOmniauthToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :provider
      t.string :uid
    end

    add_index :users, :provider
    add_index :users, :uid
  end
end
