class UpdatesAndNormalizesInterventions < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          UPDATE intervention_parameters
          SET working_zone = products.initial_shape
          FROM products, interventions
          WHERE products.id = intervention_parameters.product_id
          AND (intervention_parameters.working_zone IS NULL OR ST_AsText(intervention_parameters.working_zone) = cast('MULTIPOLYGON EMPTY' as text))
          AND intervention_parameters.type IN ('InterventionTarget')
          AND interventions.id = intervention_parameters.intervention_id
          AND interventions.procedure_name IN ('harvest_transportation', 'plant_uncovering', 'installation_maintenance')
        SQL
      end
      dir.down {}
    end
  end
end
