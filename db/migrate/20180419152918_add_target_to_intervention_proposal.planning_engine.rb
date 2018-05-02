# This migration comes from planning_engine (originally 20180419152744)
class AddTargetToInterventionProposal < ActiveRecord::Migration
  def change
    add_column :intervention_proposals, :target, :string
  end
end
