class CreateInterventionSettingItems < ActiveRecord::Migration[5.0]
  def change
    create_table :intervention_setting_items do |t|
      t.references :intervention_parameter_setting, index: { name: 'index_int_parameter_setting_items_on_int_parameter_setting_id'}, foreign_key: true
      t.references :intervention, index: true, foreign_key: true
      t.reading null: false, index: true
      t.stamps
    end
  end
end
