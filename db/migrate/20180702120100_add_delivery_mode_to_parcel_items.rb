class AddDeliveryModeToParcelItems < ActiveRecord::Migration[4.2]
  def change
    add_column :parcel_items, :delivery_mode, :string
    add_reference :parcel_items, :delivery, index: true
    add_reference :parcel_items, :transporter, index: true
  end
end
