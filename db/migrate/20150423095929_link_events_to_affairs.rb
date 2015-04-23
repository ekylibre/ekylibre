class LinkEventsToAffairs < ActiveRecord::Migration
  def change
    add_reference :events, :affair
  end
end
