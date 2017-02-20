class RenameProcedureSilageUnloadToHerdFeeding < ActiveRecord::Migration
  def change
    reversible do |d|
      d.up do
        execute "UPDATE interventions SET procedure_name = 'herd_feeding' WHERE procedure_name = 'silage_unload'"
      end
      d.down do
        execute "UPDATE interventions SET procedure_name = 'silage_unload' WHERE procedure_name = 'herd_feeding'"
      end
    end
  end
end
