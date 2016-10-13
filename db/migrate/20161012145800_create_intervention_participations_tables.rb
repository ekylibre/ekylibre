class CreateInterventionParticipationsTables < ActiveRecord::Migration
  def change
    create_table :intervention_participations do |t|
      t.references :intervention, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true

      t.string :state

      t.boolean :request_compliant, null: false, default: false

      t.stamps
    end

    add_column :interventions, :request_compliant, :boolean

    add_reference :intervention_working_periods, :intervention_participation, foreign_key: true
    add_column    :intervention_working_periods, :nature, :string

    reversible do |dir|
      dir.up do
        change_column_null :intervention_working_periods, :intervention_id, true
      end

      dir.down do
        execute <<-SQL
          UPDATE intervention_working_periods AS working_periods
          SET    intervention_id = participations.intervention_id
            FROM  intervention_participations AS participations
            WHERE working_periods.intervention_participation_id = participations.id
              AND working_periods.intervention_id IS NULL;
          SQL
        change_column_null :intervention_working_periods, :intervention_id, false
      end
    end
  end
end
