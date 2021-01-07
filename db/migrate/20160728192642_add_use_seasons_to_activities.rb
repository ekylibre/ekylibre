class AddUseSeasonsToActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :activities, :use_seasons, :boolean, default: false
  end
end
