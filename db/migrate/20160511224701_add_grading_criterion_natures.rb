class AddGradingCriterionNatures < ActiveRecord::Migration
  def change
    add_column :grading_quality_criteria, :nature, :string
  end
end
