class AddOutgoingDeliveryDivision < ActiveRecord::Migration[4.2]
  def change
    add_column :outgoing_delivery_items, :parted, :boolean, null: false, default: false
    add_reference :outgoing_delivery_items, :parted_product
  end
end
