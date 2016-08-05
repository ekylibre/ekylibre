class AddUseSeasonsToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :use_seasons, :boolean, default: false
  end
end
