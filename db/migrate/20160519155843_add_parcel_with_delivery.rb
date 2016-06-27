class AddParcelWithDelivery < ActiveRecord::Migration
  def change
    add_column :parcels, :with_delivery, :boolean, null: false, default: false
    reversible do |d|
      d.up do
        execute 'UPDATE parcels SET with_delivery = TRUE'
        execute "UPDATE parcels SET delivery_mode = 'third' WHERE nature = 'incoming' AND delivery_mode = 'indifferent'"
        execute "UPDATE parcels SET delivery_mode = 'us' WHERE nature = 'outgoing' AND delivery_mode = 'indifferent'"
      end
    end
  end
end
