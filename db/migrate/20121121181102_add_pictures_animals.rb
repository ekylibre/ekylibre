class AddPicturesAnimals < ActiveRecord::Migration
  def up
    change_table :animals do |t|
      t.has_attached_file :picture
    end
  end
  def down
    drop_attached_file :animals, :picture
  end
end
