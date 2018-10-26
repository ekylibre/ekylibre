class AddWorkNumberToParcelItems < ActiveRecord::Migration
  def change
    add_column :parcel_items, :product_work_number, :string
  end
end
