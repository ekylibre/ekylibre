class AddUsageToInterventionParameters < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :usage_id, :string
  end
end
