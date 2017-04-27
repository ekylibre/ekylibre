class CorrectingAnimalChangingIntervention < ActiveRecord::Migration
  def up
    execute "UPDATE interventions SET procedure_name = 'animal_group_changing', actions = 'animal_group_changing' WHERE procedure_name = 'animal_changing';"
  end

  def down
    # NOOP
  end
end
