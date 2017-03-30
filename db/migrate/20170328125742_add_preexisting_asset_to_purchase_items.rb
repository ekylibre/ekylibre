class AddPreexistingAssetToPurchaseItems < ActiveRecord::Migration
  def change
    add_column :purchase_items, :preexisting_asset, :boolean

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE purchase_items
          SET preexisting_asset = true
          WHERE fixed_asset_id IS NOT NULL;
        SQL
      end

      dir.down do
        # NOOP
      end
    end
  end
end
