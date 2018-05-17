# This migration comes from planning_engine (originally 20180516080155)
class AddInterventionTemplateProductParameterReferenceToInterventionProposalParameter < ActiveRecord::Migration
  def change
    add_reference :intervention_proposal_parameters, :intervention_template_product_parameter
  end
end
