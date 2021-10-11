class LinkEventsToAffairs < ActiveRecord::Migration[4.2]
  def change
    add_reference :events, :affair
  end
end
