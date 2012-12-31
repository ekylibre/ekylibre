class ChangeMedicalAnimals< ActiveRecord::Migration
  def up
    add_column :animal_treatments, :drug_admission_path, :string
  end
  
  def down
    remove_column :animal_treatments, :drug_admission_path
  end
  
end