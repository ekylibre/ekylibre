class AddInterventionProposalReferenceToIntervention < ActiveRecord::Migration
  def change
    unless column_exists?(:interventions, :intervention_proposal_id)
      add_reference :interventions, :intervention_proposal, index: true, foreign_key: true
    end
  end
end
