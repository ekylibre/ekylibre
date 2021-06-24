class AddOmniauthToUsers < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.string :provider
      t.string :uid
      t.index :provider
      t.index :uid
    end
  end
end
