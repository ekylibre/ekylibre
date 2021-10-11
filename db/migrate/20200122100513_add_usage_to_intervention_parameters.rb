class AddUsageToInterventionParameters < ActiveRecord::Migration[4.2]
  def change
    add_column :intervention_parameters, :usage_id, :string
  end
end
