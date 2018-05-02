# This migration comes from planning_engine (originally 20180405123945)
class AddInterventionProposalReferenceToIntervention < ActiveRecord::Migration
  def change
    add_reference :interventions, :intervention_proposal, index: true, foreign_key: true
  end
end
