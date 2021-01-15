class AddAssetFixableToProductNatureCategories < ActiveRecord::Migration[4.2]
  def change
    add_column :product_nature_categories, :asset_fixable, :boolean, default: false

    reversible do |d|
      d.up do
        execute <<-SQL
          UPDATE product_nature_categories
          SET asset_fixable = true
          WHERE depreciable = true
        SQL
      end

      d.down do
        # NOOP
      end
    end
  end
end
