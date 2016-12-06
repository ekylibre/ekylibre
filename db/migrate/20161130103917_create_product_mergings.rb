class CreateProductMergings < ActiveRecord::Migration
  def change
    create_table :product_mergings do |t|
      t.references  :product
      t.references  :merged_with
      t.datetime    :merged_at
      t.references  :originator

      t.stamps
    end

    add_column :intervention_parameters, :merge_stocks, :boolean
  end
end
