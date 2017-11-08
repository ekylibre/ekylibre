class RenameProductReceptionToReception < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE parcels SET type = 'Reception' WHERE nature = 'incoming'"
        execute "UPDATE parcels SET type = 'Shipment' WHERE nature = 'outgoing'"
      end
      dir.down do
        execute "UPDATE parcels SET type = 'ProductReception'"
      end
    end
  end
end
