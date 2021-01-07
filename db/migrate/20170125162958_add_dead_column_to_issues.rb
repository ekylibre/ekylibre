class AddDeadColumnToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :dead, :boolean, default: false
  end
end
