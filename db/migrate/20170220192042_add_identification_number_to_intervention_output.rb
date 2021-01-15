class AddIdentificationNumberToInterventionOutput < ActiveRecord::Migration[4.2]
  def change
    add_column :intervention_parameters, :identification_number, :string
  end
end
