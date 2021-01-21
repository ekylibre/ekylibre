class RenameTypeNameReception < ActiveRecord::Migration[4.2]
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
