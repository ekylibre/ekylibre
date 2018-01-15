# This migration comes from planning_engine (originally 20180112151052)
class CreateInterventionTemplateActivities < ActiveRecord::Migration
  def change
    create_table :intervention_template_activities do |t|
      t.references :intervention_template, index: { name: :intervention_template_activity_id }, foreign_key: true
      t.references :activity, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
