class AddLateDeliveryToParcels < ActiveRecord::Migration[4.2]
  def change
    add_column :parcels, :late_delivery, :boolean
  end
end
