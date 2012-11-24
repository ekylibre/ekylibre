class UpdateAnimals < ActiveRecord::Migration
  def change

    add_column :animals, :race_id, :integer
    add_column :animals, :father_id, :integer
    add_column :animals, :mother_id, :integer
    add_index :animals, :race_id
    add_index :animals, :father_id
    add_index :animals, :mother_id

    add_column :animal_groups, :age_min, :integer
    add_column :animal_groups, :age_max, :integer
    add_column :animal_groups, :sex, :string, :limit => 16
    add_column :animal_groups, :pregnant, :boolean, :null => false, :default => false

    create_table :animal_races do |t|
       t.belongs_to :nature,             :null => false
       t.string     :name,               :null => false
       t.text       :description
       t.text       :comment
       t.integer    :code
       t.stamps
    end
    add_stamps_indexes :animal_races
    add_index :animal_races, :nature_id

    create_table :animal_race_natures do |t|
       t.string     :name,                  :null => false
       t.text       :description
       t.text       :comment
       t.stamps
    end
    add_stamps_indexes :animal_race_natures

    create_table :animal_cares do |t|
       t.belongs_to :animal
       t.belongs_to :nature,               :null => false
       t.string     :name,                 :null => false
       t.text       :description
       t.text       :comment
       t.datetime   :start_on
       t.datetime   :end_on
       t.decimal    :quantity_per_care
       t.belongs_to :entity
       t.belongs_to :animal_group
       t.stamps
    end
    add_stamps_indexes :animal_cares
    add_index :animal_cares, :animal_id
    add_index :animal_cares, :nature_id
    add_index :animal_cares, :entity_id
    add_index :animal_cares, :animal_group_id


    create_table :animal_care_natures do |t|
       t.string     :name,                  :null => false
       t.text       :description
       t.text       :comment
       t.stamps
    end
    add_stamps_indexes :animal_care_natures

    create_table :drugs do |t|
      t.belongs_to :unit
      t.belongs_to :nature, :null => false
      t.string  :name, :null => false
      t.integer :frequency, :default => 1
      t.decimal :quantity, :precision => 19, :scale => 4, :default => 0.0
      t.text    :comment
      t.stamps
    end
    add_stamps_indexes :drugs
    add_index :drugs, :name
    add_index :drugs, :unit_id
    add_index :drugs, :nature_id

    create_table :drug_natures do |t|
      t.string :name, :null => false
      t.stamps
    end
    add_stamps_indexes :drug_natures
    add_index :drug_natures, :name

    create_table :animal_cares_drugs, :id => false do |t|
      t.belongs_to :animal_care
      t.belongs_to :drug
    end
    add_index :animal_cares_drugs, :animal_care_id
    add_index :animal_cares_drugs, :drug_id

  end

end
