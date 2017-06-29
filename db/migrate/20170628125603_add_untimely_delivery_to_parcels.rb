class AddUntimelyDeliveryToParcels < ActiveRecord::Migration
  def change
    add_column :parcels, :untimely_delivery, :boolean
  end
end
