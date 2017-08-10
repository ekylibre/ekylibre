class AddNonCompliantDetailToParcelItems < ActiveRecord::Migration
  def change
    add_column :parcel_items, :non_compliant_detail, :string
  end
end
