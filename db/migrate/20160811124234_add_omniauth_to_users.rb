class AddOmniauthToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :provider, index: true
      t.string :uid, index: true
    end
  end
end
