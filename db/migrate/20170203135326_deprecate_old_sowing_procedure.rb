class DeprecateOldSowingProcedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE interventions
            SET  procedure_name = 'old_sowing'
          WHERE  procedure_name = 'sowing'
        SQL

        execute <<-SQL
          UPDATE interventions
            SET  procedure_name = 'sowing'
          WHERE  procedure_name = 'new_sowing'
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE interventions
            SET  procedure_name = 'sowing'
          WHERE  procedure_name = 'old_sowing'
        SQL

        execute <<-SQL
          UPDATE interventions
            SET  procedure_name = 'new_sowing'
          WHERE  procedure_name = 'sowing'
        SQL
      end
    end
  end
end
