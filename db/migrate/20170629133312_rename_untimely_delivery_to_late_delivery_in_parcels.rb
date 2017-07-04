class RenameUntimelyDeliveryToLateDeliveryInParcels < ActiveRecord::Migration
  def change
  	rename_column :parcels, :untimely_delivery, :late_delivery
  end
end
