# This migration comes from planning_engine (originally 20180404145130)
class AddNumberToInterventionProposal < ActiveRecord::Migration
  def up
    add_column :intervention_proposals, :number, :integer
    sequence = Sequence.of(:interventions)
    # binding.pry
    InterventionProposal.find_each do |i|
      sequence.next_value!
      i.update(number: sequence.last_value)
    end
  end

  def down
    remove_column :intervention_proposals, :number, :integer
  end
end
