class FixHoeingParameterRenaming < ActiveRecord::Migration
  def up
    execute "UPDATE intervention_parameters AS ip SET reference_name = 'hoe' FROM interventions AS i WHERE i.id = ip.intervention_id AND reference_name = 'cultivator' AND i.procedure_name = 'hoeing'"
  end
  def down
    execute "UPDATE intervention_parameters AS ip SET reference_name = 'cultivator' FROM interventions AS i WHERE i.id = ip.intervention_id AND reference_name = 'hoe' AND i.procedure_name = 'hoeing'"
  end
end
