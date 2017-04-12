class AddMoreAttributesOnInterventionOutputs < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :variety, :string
    add_column :intervention_parameters, :derivative_of, :string
  end
end
