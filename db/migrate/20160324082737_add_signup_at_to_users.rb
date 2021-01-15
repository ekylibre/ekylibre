class AddSignupAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :signup_at, :datetime
  end
end
