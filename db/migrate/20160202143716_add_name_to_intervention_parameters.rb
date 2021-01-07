class AddNameToInterventionParameters < ActiveRecord::Migration[4.2]
  def change
    add_column :intervention_parameters, :new_name, :string
  end
end
