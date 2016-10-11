class CreateInterventionParticipationsTables < ActiveRecord::Migration
  def change
    create_table :intervention_participations do |t|
      t.references :intervention, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true

      t.datetime :started_at
      t.datetime :stopped_at
      t.string :nature

      t.boolean :request_compliant, null: false, default: false

      t.stamps
    end

    add_reference :intervention_working_periods, :intervention_participation, foreign_key: true
    add_column    :intervention_working_periods, :nature, :string
    change_column :intervention_working_periods, :intervention_id, :integer, null: true
  end
end
