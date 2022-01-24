class CreateInterventionTemplateActivities < ActiveRecord::Migration
  def change
    unless data_source_exists?(:intervention_template_activities)
      create_table :intervention_template_activities do |t|
        t.references :intervention_template, index: { name: :intervention_template_activity_id }, foreign_key: true
        t.references :activity, index: true, foreign_key: true
        t.timestamps null: false
      end
    end
  end
end
