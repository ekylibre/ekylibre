class AddActivityTacticSteps < ActiveRecord::Migration
  def change
    create_table :activity_tactic_steps do |t|
      t.references :tactic, null: false, index: true
      t.string :name, null: false
      t.date :started_on
      t.date :stopped_on
      t.string :procedure_action, null: false
      t.stamps
    end
  end
end
