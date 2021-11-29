class UpdatePictograms < ActiveRecord::Migration[5.0]
  def change
    add_column :product_nature_variants, :pictogram, :string
  end
end
