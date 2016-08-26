class RenameCropperDriverToDriverInNomenclatureHarversting < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'driver'
          FROM interventions
          WHERE (iparam.reference_name = 'cropper_driver'
            AND interventions.procedure_name = 'harvesting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cropper_driver'
          FROM interventions
          WHERE (iparam.reference_name = 'driver'
            AND interventions.procedure_name = 'harvesting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
