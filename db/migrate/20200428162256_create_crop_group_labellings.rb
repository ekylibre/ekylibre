class CreateCropGroupLabellings < ActiveRecord::Migration[4.2]
  def change
    create_table :crop_group_labellings do |t|
      t.references :crop_group, index: true, foreign_key: true
      t.references :label, index: true, foreign_key: true

      t.stamps
    end
  end
end
