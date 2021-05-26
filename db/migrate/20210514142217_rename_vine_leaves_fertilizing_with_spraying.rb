class RenameVineLeavesFertilizingWithSpraying < ActiveRecord::Migration[4.2]
  def change
    reversible do |d|
      d.up do
        execute "UPDATE interventions SET procedure_name = 'vine_spraying_with_fertilizing' WHERE procedure_name = 'vine_leaves_fertilizing_with_spraying'"
      end
      d.down do
        execute "UPDATE interventions SET procedure_name = 'vine_leaves_fertilizing_with_spraying' WHERE procedure_name = 'vine_spraying_with_fertilizing'"
      end
    end
  end
end
