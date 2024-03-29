class CastParcelsToFitSti < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE parcels SET type = 'Reception' WHERE nature = 'incoming'"
        execute "UPDATE parcels SET type = 'Shipment' WHERE nature = 'outgoing'"
      end
      dir.down do
        execute 'UPDATE parcels SET type = NULL '
      end
    end
  end
end
