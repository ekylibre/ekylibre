class RemoveUserDefaultAdministratorState < ActiveRecord::Migration[4.2]
  def change
    change_column_default :users, :administrator, false
  end
end
