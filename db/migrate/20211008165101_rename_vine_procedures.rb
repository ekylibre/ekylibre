class RenameVineProcedures < ActiveRecord::Migration[5.0]
  def change
    reversible do |d|
      d.up do
        # intervine_hilling
        execute "UPDATE interventions SET procedure_name = 'intervine_hilling' WHERE procedure_name = 'vine_inter_row_hilling'"
        execute "UPDATE intervention_parameters SET reference_name = 'intervine_hiller' WHERE reference_name = 'interrow_hiller'"
        execute "UPDATE interventions SET procedure_name = 'intervine_hill_removing' WHERE procedure_name = 'vine_inter_row_hill_removing'"
        execute "UPDATE intervention_parameters SET reference_name = 'intervine_hill_remover' WHERE reference_name = 'interrow_hill_remover'"

      end
      d.down do
        execute "UPDATE interventions SET procedure_name = 'vine_inter_row_hilling' WHERE procedure_name = 'intervine_hilling'"
        execute "UPDATE intervention_parameters SET reference_name = 'interrow_hiller' WHERE reference_name = 'intervine_hiller'"
        execute "UPDATE interventions SET procedure_name = 'vine_inter_row_hill_removing' WHERE procedure_name = 'intervine_hill_removing'"
        execute "UPDATE intervention_parameters SET reference_name = 'interrow_hill_remover' WHERE reference_name = 'intervine_hill_remover'"
      end
    end
  end
end
