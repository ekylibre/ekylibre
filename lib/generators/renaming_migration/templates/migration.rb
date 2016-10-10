class Rename<%= old_name.camelcase %>To<%= new_name.camelcase %>In<%= procedure_name.camelcase %>Procedure < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = '<%= new_name %>'
          FROM interventions
          WHERE (iparam.reference_name = '<%= old_name %>'
            AND interventions.procedure_name = '<%= procedure_name %>'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = '<%= old_name %>'
          FROM interventions
          WHERE (iparam.reference_name = '<%= new_name %>'
            AND interventions.procedure_name = '<%= procedure_name %>'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
