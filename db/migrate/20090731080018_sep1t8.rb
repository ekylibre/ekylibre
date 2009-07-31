class Sep1t8 < ActiveRecord::Migration
  def self.up
    add_column :event_natures, :usage, :string,  :limit=>16
  end

  def self.down
     remove_column :event_natures, :usage
  end
end
