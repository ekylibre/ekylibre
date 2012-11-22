class AddPicturesAnimals < ActiveRecord::Migration
  def self.up
    change_table :animals do |t|
      t.has_attached_file :picture
    end
  end
  def self.down
    drop_attached_file :animals, :picture
  end
end