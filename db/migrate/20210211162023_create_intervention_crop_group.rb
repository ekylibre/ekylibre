class CreateInterventionCropGroup < ActiveRecord::Migration[5.0]
  def change
    create_table :intervention_crop_groups do |t|
      t.references :crop_group, foreign_key: true
      t.references :intervention, foreign_key: true

      t.stamps
    end
  end
end
