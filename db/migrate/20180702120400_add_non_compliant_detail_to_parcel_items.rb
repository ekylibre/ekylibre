class AddNonCompliantDetailToParcelItems < ActiveRecord::Migration[4.2]
  def change
    add_column :parcel_items, :non_compliant_detail, :string
  end
end
