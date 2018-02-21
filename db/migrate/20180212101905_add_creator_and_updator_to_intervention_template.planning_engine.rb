# This migration comes from planning_engine (originally 20180212101416)
class AddCreatorAndUpdatorToInterventionTemplate < ActiveRecord::Migration
  def change
    add_column :intervention_templates, :creator_id, :integer
    add_column :intervention_templates, :updater_id, :integer
  end
end
