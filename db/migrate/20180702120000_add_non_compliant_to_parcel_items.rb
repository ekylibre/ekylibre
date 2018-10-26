class AddNonCompliantToParcelItems < ActiveRecord::Migration
  def change
    add_column :parcel_items, :non_compliant, :boolean
  end
end
