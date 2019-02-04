class RenameClosedOnInJournals < ActiveRecord::Migration
  def self.up
    rename_column :journals, :closed_on, :latest_closure_on
  end

  def self.down
    rename_column :journals, :latest_closure_on, :closed_on
  end
end
