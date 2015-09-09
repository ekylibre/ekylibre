class AddUsageLimitDateOnTrackings < ActiveRecord::Migration
  def change
    add_column :trackings, :usage_limit_on, :date
    add_column :trackings, :usage_limit_nature, :string
  end
end
