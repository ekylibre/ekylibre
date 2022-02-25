class AddColumnsToShipmentItem < ActiveRecord::Migration[5.0]
  def change
    add_column :parcel_items, :unit_pretax_sale_amount, :decimal, precision: 19, scale: 4
    add_reference :parcels, :sale_nature, index: true, foreign_key: { to_table: :sale_natures}
    add_reference :sale_items, :shipment_item, index: true
  end
end
