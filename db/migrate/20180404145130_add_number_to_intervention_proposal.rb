class AddNumberToInterventionProposal < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:intervention_proposals, :number)
      add_column :intervention_proposals, :number, :integer
    end
  end

  def down
    remove_column :intervention_proposals, :number, :integer
  end
end
