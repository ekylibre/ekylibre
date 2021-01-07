class AddAnnotationFieldToParcelItem < ActiveRecord::Migration[4.2]
  def change
    add_column :parcel_items, :annotation, :text
  end
end
