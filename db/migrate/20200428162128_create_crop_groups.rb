class CreateCropGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :crop_groups do |t|
      t.string :name, null: false
      t.string :target, default: 'plant'
      t.stamps
    end
  end
end
