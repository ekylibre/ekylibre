class AddSpecieVarietyAttributeToProduct < ActiveRecord::Migration[4.2]
  def change
    add_column :products, :specie_variety, :jsonb, default: '{}'
  end
end
