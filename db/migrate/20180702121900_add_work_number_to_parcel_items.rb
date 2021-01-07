class AddWorkNumberToParcelItems < ActiveRecord::Migration[4.2]
  def change
    add_column :parcel_items, :product_work_number, :string
  end
end
