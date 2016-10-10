class CreateInterventionParticipations < ActiveRecord::Migration
  def change
    create_table :intervention_participations do |t|
      t.references :intervention, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true
      t.datetime :started_at
      t.datetime :stopped_at
      t.string :nature

      t.stamps
    end
  end
end
