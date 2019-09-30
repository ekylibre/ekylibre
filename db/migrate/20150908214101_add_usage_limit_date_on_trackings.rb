class AddUsageLimitDateOnTrackings < ActiveRecord::Migration[4.2]
  def change
    add_column :trackings, :usage_limit_on, :date
    add_column :trackings, :usage_limit_nature, :string
  end
end
