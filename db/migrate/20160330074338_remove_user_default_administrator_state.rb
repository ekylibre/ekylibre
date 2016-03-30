class RemoveUserDefaultAdministratorState < ActiveRecord::Migration
  def change
    change_column_default :users, :administrator, false
  end
end
