class UpdateAnimals < ActiveRecord::Migration
  def change
    
    add_column :animals, :race_id, :integer
    add_column :animals, :male_parent_id, :integer
    add_column :animals, :female_parent_id, :integer
    
    add_column :animal_groups, :age_min, :integer
    add_column :animal_groups, :age_max, :integer
    add_column :animal_groups, :sex, :string
    add_column :animal_groups, :is_pregnant, :boolean
    
    create_table :animal_races do |t|
       t.belongs_to :type,               :null=>false
       t.string     :name,                  :null=>false
       t.text       :description
       t.text       :comment
       t.integer    :race_code
       t.stamps
    end
    add_stamps_indexes :animal_races
    
    create_table :animal_race_types do |t|
       t.string     :name,                  :null=>false
       t.text       :description
       t.text       :comment
       t.stamps
    end
    add_stamps_indexes :animal_race_types
    
    create_table :animal_cares do |t|
       t.belongs_to :animal
       t.belongs_to :type,               :null=>false
       t.string     :name,                  :null=>false
       t.text       :description
       t.text       :comment
       t.datetime   :start_on
       t.datetime   :end_on
       t.decimal    :quantity_per_care
       t.integer    :entity_id
       t.integer    :animal_group_id
       t.stamps
    end
    add_stamps_indexes :animal_cares
    
    create_table :animal_care_types do |t|
       t.string     :name,                  :null=>false
       t.text       :description
       t.text       :comment
       t.stamps
    end
    add_stamps_indexes :animal_care_types
    
        create_table :drugs do |t|
      t.belongs_to :unit
      t.belongs_to :type, :null=>false
      t.string :name, :null=>false
      t.integer :frequency, :default => 1
      t.decimal :quantity, :precision => 19, :scale => 4, :default => 0.0
      t.string :comment
      t.stamps
    end
    add_stamps_indexes :drugs
    add_index :drugs, :name
    
    create_table :drug_types do |t|
      t.string :name, :null=>false
      t.stamps
    end
    add_stamps_indexes :drug_types
    add_index :drug_types, :name
     
    create_table :animal_cares_drugs, :id => false do |t|
      t.integer :animal_care_id
      t.integer :drug_id
    end
     
  end

end
