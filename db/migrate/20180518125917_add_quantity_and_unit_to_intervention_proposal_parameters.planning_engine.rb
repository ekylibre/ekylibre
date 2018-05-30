# This migration comes from planning_engine (originally 20180518124733)
class AddQuantityAndUnitToInterventionProposalParameters < ActiveRecord::Migration
  def up
    add_column :intervention_proposal_parameters, :quantity, :decimal
    add_column :intervention_proposal_parameters, :unit, :string
  end

  def down
    remove_column :intervention_proposal_parameters, :quantity
    remove_column :intervention_proposal_parameters, :unit
  end
end
