class AddInterventionTemplateProductParameterReferenceToInterventionProposalParameter < ActiveRecord::Migration
  def change
    unless column_exists?(:intervention_proposal_parameters, :intervention_template_product_parameter_id)
      add_reference :intervention_proposal_parameters, :intervention_template_product_parameter
    end
  end
end
