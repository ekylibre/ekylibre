class AddDeviceInfoIntoCrumbs < ActiveRecord::Migration
  def up
    add_column :crumbs, :device_uid, :string
    execute "UPDATE crumbs SET device_uid = 'unknown:00000000'"
    change_column_null :crumbs, :device_uid, false
  end

  def down
    remove_column :crumbs, :device_uid
  end
end
