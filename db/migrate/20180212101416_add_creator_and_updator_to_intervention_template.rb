class AddCreatorAndUpdatorToInterventionTemplate < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:intervention_templates, :creator_id)
      add_column :intervention_templates, :creator_id, :integer
    end
    unless column_exists?(:intervention_templates, :updater_id)
      add_column :intervention_templates, :updater_id, :integer
    end
  end
end
