class AddSignupAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :signup_at, :datetime
  end
end
