class RenameProductReceptionToReception < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE parcels SET type = 'Reception'"
      end
      dir.down do
        execute "UPDATE parcels SET type = 'ProductReception'"
      end
    end
  end
end
