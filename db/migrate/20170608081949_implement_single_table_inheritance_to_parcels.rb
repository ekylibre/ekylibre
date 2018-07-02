class ImplementSingleTableInheritanceToParcels < ActiveRecord::Migration
  def change
    add_column :parcels, :type, :string unless column_exists? :parcels, :type

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
