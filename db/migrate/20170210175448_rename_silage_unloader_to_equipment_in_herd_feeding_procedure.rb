class RenameSilageUnloaderToEquipmentInHerdFeedingProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'equipment'
          FROM interventions
          WHERE (iparam.reference_name = 'silage_unloader'
            AND interventions.procedure_name = 'herd_feeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'silage_unloader'
          FROM interventions
          WHERE (iparam.reference_name = 'equipment'
            AND interventions.procedure_name = 'herd_feeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
