class AddAmountReferenceToSaleItems < ActiveRecord::Migration
  def change
    add_column :sale_items, :amount_reference, :string
  end
end
