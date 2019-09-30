class CreateInterventionsCosts < ActiveRecord::Migration[4.2]
  def up
    create_table :intervention_costs do |t|
      t.decimal :inputs_cost
      t.decimal :doers_cost
      t.decimal :tools_cost
      t.decimal :receptions_cost
    end

    add_column :interventions, :intervention_costs_id, :integer

    say 'Please think to run `bundle exec rake maintenance:interventions:update_costings`'.yellow
  end

  def down
    drop_table :intervention_costs
    remove_column :interventions, :intervention_costs_id
  end
end
