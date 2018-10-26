class AddRoleToParcelItem < ActiveRecord::Migration
  def change
    add_column :parcel_items, :role, :string
  end
end
