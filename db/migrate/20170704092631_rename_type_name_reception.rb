class RenameTypeNameReception < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE parcels SET type = 'VariousProductReception' WHERE type = 'Reception'"
      end
      dir.down do
        execute "UPDATE parcels SET type = 'Reception' WHERE type = 'VariousProductReception'"
      end
    end
  end
end
