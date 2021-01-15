class AddRoleToParcelItem < ActiveRecord::Migration[4.2]
  def change
    add_column :parcel_items, :role, :string
  end
end
