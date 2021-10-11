class CreateInterventionTemplates < ActiveRecord::Migration
  def change
    unless table_exists?(:intervention_templates)
      create_table :intervention_templates do |t|
        t.string :name
        t.boolean :active, default: true
        t.string :description
        t.string :procedure_name
        t.references :campaign, index: true, foreign_key: true
        t.integer :preparation_time_hours
        t.integer :preparation_time_minutes
        t.decimal :workflow
        t.timestamps null: false
        t.timestamps null: false
      end
    end
  end
end
