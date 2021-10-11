class SetUserRoleAsOptional < ActiveRecord::Migration[4.2]
  def change
    change_column_null :users, :role_id, true
  end
end
