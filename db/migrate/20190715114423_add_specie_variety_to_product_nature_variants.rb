class AddSpecieVarietyToProductNatureVariants < ActiveRecord::Migration[4.2]
  def up
    add_column :product_nature_variants, :specie_variety, :string
  end

  def down
    # NOOP
  end
end
