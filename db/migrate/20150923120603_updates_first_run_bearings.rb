class UpdatesFirstRunBearings < ActiveRecord::Migration
  def up
    execute "UPDATE preferences SET name = 'first_run.executed_loaders.' || split_part(name, '.', 2) WHERE name LIKE 'first_run.%.executed'"
    if select_value("SELECT count(*) FROM preferences WHERE name = 'first_run.executed'").to_i.zero?
      execute "INSERT INTO preferences (name, nature, boolean_value, created_at, updated_at) SELECT 'first_run.executed', 'boolean', true, created_at, updated_at FROM preferences WHERE name = 'first_run.executed_loaders.interventions'"
    end
  end

  def down
    execute "DELETE FROM preferences WHERE name = 'first_run.executed'"
    execute "UPDATE preferences SET name = 'first_run.' || split_part(name, '.', 3) || '.executed' WHERE name LIKE 'first_run.executed_loaders.%'"
  end
end
