class FixesProductsSpecies < ActiveRecord::Migration
  def up

    rename_table :product_species, :product_varieties

    change_table :products do |t|
      t.rename :specy_id, :variety_id
    end

  end

  def down

   rename_table :product_varieties, :product_species

    change_table :products do |t|
      t.rename   :variety_id, :specy_id
    end

  end

end
