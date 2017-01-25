class AddDeadColumnToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :dead, :boolean, default: false
  end
end
