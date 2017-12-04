class CreateInterventionTemplates < ActiveRecord::Migration
  def change
    create_table :intervention_templates do |t|
      t.string :name
      t.boolean :active, default: true
      t.string :description

      t.timestamps null: false
    end
  end
end
