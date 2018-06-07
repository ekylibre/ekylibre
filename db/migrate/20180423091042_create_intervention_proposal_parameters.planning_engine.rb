# This migration comes from planning_engine (originally 20180423074302)
class CreateInterventionProposalParameters < ActiveRecord::Migration
  def change
    create_table :intervention_proposal_parameters do |t|
      t.references :intervention_proposal, index: { name: :intervention_proposal_parameter_id }, foreign_key: true
      t.references :product, index: true, foreign_key: true
      t.references :product_nature_variant, index: { name: :intervention_product_nature_variant_id }, foreign_key: true
      t.string :product_type
      t.timestamps null: false
    end
  end
end
