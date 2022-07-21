class AddQuantityAndUnitToInterventionProposalParameters < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:intervention_proposal_parameters, :quantity)
      add_column :intervention_proposal_parameters, :quantity, :decimal
    end
    unless column_exists?(:intervention_proposal_parameters, :unit)
      add_column :intervention_proposal_parameters, :unit, :string
    end
  end

  def down
    remove_column :intervention_proposal_parameters, :quantity
    remove_column :intervention_proposal_parameters, :unit
  end
end
