class AddVariantsTags < ActiveRecord::Migration[5.2]
  def change
    create_table :product_nature_variant_tags do |t|
      t.references :entity, index: true, null: false
      t.references :variant, index: true, null: false
      t.references :document, index: true
      t.text :description
      t.string :name, index: true, null: false
      t.stamps
    end
  end
end


