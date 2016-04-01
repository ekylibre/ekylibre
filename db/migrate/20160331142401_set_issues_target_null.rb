class SetIssuesTargetNull < ActiveRecord::Migration
  def change
    change_column_null :issues, :target_id, true
    change_column_null :issues, :target_type, true
  end
end
