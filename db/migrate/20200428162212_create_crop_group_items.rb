class CreateCropGroupItems < ActiveRecord::Migration[4.2]
  def change
    create_table :crop_group_items do |t|
      t.references :crop_group, index: true, foreign_key: true
      t.references :crop, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
