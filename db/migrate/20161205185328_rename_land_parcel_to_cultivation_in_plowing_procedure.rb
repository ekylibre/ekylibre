class RenameLandParcelToCultivationInPlowingProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'plowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'plowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
