class AddNonCompliantToParcelItems < ActiveRecord::Migration[4.2]
  def change
    add_column :parcel_items, :non_compliant, :boolean
  end
end
