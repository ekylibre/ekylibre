class AddActivityCostDistribution < ActiveRecord::Migration[4.2]
  def change
    add_column :activities, :distribution_key, :string
    add_column :loans, :activity_id, :integer, index: true
    add_column :fixed_assets, :activity_id, :integer, index: true
    add_foreign_key :fixed_assets, :activities, column: :activity_id
    add_foreign_key :loans, :activities, column: :activity_id
  end
end
