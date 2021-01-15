class SetIssuesTargetNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :issues, :target_id, true
    change_column_null :issues, :target_type, true
  end
end
