class SetNameNotNullForProductNatureVariant < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE product_nature_variants pnv
          SET name = pn.name
          FROM product_natures pn
          WHERE pnv.nature_id = pn.id
          AND (pnv.name IS NULL OR pnv.name = '')
        SQL
      end
    end

    change_column_null :product_nature_variants, :name, false
  end
end
