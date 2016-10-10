class MergeMechanicalHarvestingWithHarvesting < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'matters'
          FROM interventions
          WHERE ((iparam.reference_name = 'straws'
            OR iparam.reference_name = 'grains')
            AND interventions.procedure_name = 'mechanical_harvesting'
            AND iparam.intervention_id = interventions.id)
        SQL
        execute <<-SQL
        UPDATE
          interventions
          SET procedure_name = 'harvesting'
          WHERE (interventions.procedure_name = 'mechanical_harvesting')
        SQL
      end
      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end
