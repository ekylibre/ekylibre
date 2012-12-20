class CreateDiseases< ActiveRecord::Migration
  def change

    create_table :diseases do |t|
      t.string :name, :null => false
      t.string :code
      t.string :zone
      t.stamps
    end
    add_stamps_indexes :diseases
    add_index :diseases, :name

    create_table :diseases_animal_cares, :id => false do |t|
      t.belongs_to :animal_care
      t.belongs_to :disease
    end
    add_index :diseases_animal_cares, :animal_care_id
    add_index :diseases_animal_cares, :disease_id

  end
end
