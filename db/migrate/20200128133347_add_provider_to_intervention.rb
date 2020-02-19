class AddProviderToIntervention < ActiveRecord::Migration
  def change
    add_column :interventions, :provider, :jsonb

    reversible do |dir|
      dir.up do
        query("CREATE INDEX intervention_provider_index ON interventions USING gin ((provider -> 'vendor'), (provider -> 'name'), (provider -> 'id'))")
      end
      dir.down do
        query("DROP INDEX intervention_provider_index")
      end
    end
  end
end
