class AddAnalyticsCodesToConcernedTables < ActiveRecord::Migration[5.0]
  def change
    add_column :activities, :isacompta_analytic_code, :string, limit: 2
    add_column :project_budgets, :isacompta_analytic_code, :string, limit: 2
    add_column :teams, :isacompta_analytic_code, :string, limit: 2
    add_column :products, :isacompta_analytic_code, :string, limit: 2
  end
end
