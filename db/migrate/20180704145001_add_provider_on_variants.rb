class AddProviderOnVariants < ActiveRecord::Migration[4.2]
  def up
    # add providers colums to store pairs on provider / id number on article
    add_column :product_nature_variants, :providers, :jsonb
  end

  def down
    remove_column :product_nature_variants, :providers
  end
end
