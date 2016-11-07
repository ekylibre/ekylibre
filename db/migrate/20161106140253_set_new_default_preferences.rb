class SetNewDefaultPreferences < ActiveRecord::Migration
  def up
    execute "INSERT INTO preferences (name, nature, boolean_value, created_at, updated_at) SELECT 'distribute_sales_and_purchases_on_activities', 'boolean', (SELECT count(*) FROM sale_items WHERE activity_budget_id IS NOT NULL) + (SELECT count(*) FROM purchase_items WHERE activity_budget_id IS NOT NULL) > 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE 'distribute_sales_and_purchases_on_activities' NOT IN (SELECT name FROM preferences WHERE user_id IS NULL)"
    execute "INSERT INTO preferences (name, nature, boolean_value, created_at, updated_at) SELECT 'distribute_sales_and_purchases_on_teams', 'boolean', (SELECT count(*) FROM sale_items WHERE team_id IS NOT NULL) + (SELECT count(*) FROM purchase_items WHERE team_id IS NOT NULL) > 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE 'distribute_sales_and_purchases_on_teams' NOT IN (SELECT name FROM preferences WHERE user_id IS NULL)"
  end
end
