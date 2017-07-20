class AddDeliveryModeToParcelItems < ActiveRecord::Migration
  def change
    add_column :parcel_items, :delivery_mode, :string
    add_reference :parcel_items, :delivery, index: true
    add_reference :parcel_items, :transporter, index: true
  end
end
