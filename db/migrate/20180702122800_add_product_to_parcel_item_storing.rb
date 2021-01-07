class AddProductToParcelItemStoring < ActiveRecord::Migration[4.2]
  def change
    add_reference :parcel_item_storings, :product, index: true, foreign_key: true
  end
end
