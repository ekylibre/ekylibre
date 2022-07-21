class AddTargetToInterventionProposal < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:intervention_proposals, :target)
      add_column :intervention_proposals, :target, :string
    end
  end
end
