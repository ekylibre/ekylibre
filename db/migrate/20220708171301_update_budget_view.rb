class UpdateBudgetView < ActiveRecord::Migration[5.0]
  def change
    update_view :economic_indicators, version: 5, revert_to_version: 4, materialized: true
  end
end
