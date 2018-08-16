class CreateInterventionsCosts < ActiveRecord::Migration
  def up
    unless table_exists?(:intervention_costs)
      create_table :intervention_costs do |t|
        t.decimal :inputs_cost
        t.decimal :doers_cost
        t.decimal :tools_cost
        t.decimal :receptions_cost
      end

      add_column :interventions, :intervention_costs_id, :integer

      historical_recovery
    end
  end

  def down
    drop_table :intervention_costs
    remove_column :interventions, :intervention_costs_id
  end

  private

  def historical_recovery
    Intervention.all.each do |intervention|
      costs = {
        inputs_cost: intervention.cost(:input),
        doers_cost: intervention.cost(:doer),
        tools_cost: intervention.cost(:tool),
        receptions_cost: intervention.receptions_cost.to_f.round(2)
      }

      intervention_costs = InterventionCosts.new(costs)
      intervention_costs.save

      intervention.update_attribute(:intervention_costs_id, intervention_costs.id)
    end
  end
end
