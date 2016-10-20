class ChangeSensorVendorPresence < ActiveRecord::Migration
  def change
    change_column_null(:sensors, :vendor_euid, false)
    change_column_null(:sensors, :model_euid, false)
  end
end
