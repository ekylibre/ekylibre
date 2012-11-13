class CreateAnimals < ActiveRecord::Migration
  def change
    create_table :animals do |t|
      t.belongs_to :group,               :null=>false
      t.string     :name,                  :null=>false
      t.string     :identification_number,                :null=>false
      t.date       :born_on,            :null=>false
      t.string     :sex,                :null=>false, :limit=>1, :default=>'M'
      t.text       :description
      t.text       :comment
      t.date       :outgone_on,  :null=>false
      t.date       :income_on, :null=>false
      t.date       :purchased_on,          :null=>false
      t.date       :ceded_on
      t.stamps
    end
    add_stamps_indexes :animals
    add_index :animals, :name
    add_index :animals, :group_id
    
    create_table :animal_groups do |t|
       t.string     :name,                  :null=>false
       t.text       :description
       t.text       :comment
       t.stamps
    end
    add_stamps_indexes :animal_groups
    
  end
end
