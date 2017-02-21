class AddIdentificationNumberToInterventionOutput < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :identification_number, :string
  end
end
