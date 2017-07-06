class AddLateDeliveryToParcels < ActiveRecord::Migration
  def change
    add_column :parcels, :late_delivery, :boolean
  end
end
