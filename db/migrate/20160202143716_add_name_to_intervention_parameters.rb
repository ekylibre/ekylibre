class AddNameToInterventionParameters < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :new_name, :string
  end
end
