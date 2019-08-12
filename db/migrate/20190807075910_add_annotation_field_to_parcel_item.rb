class AddAnnotationFieldToParcelItem < ActiveRecord::Migration
  def change
    add_column :parcel_items, :annotation, :text
  end
end
