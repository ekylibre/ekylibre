class CreateInterventionParameterSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :intervention_parameter_settings do |t|
      t.references :intervention, index: true, foreign_key: true
      t.references :intervention_parameter, index: { name: 'index_int_parameter_settings_on_int_parameter_id' }, foreign_key: true
      t.string :nature, null: false
      t.stamps
    end
  end
end