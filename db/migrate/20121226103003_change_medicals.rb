class ChangeMedicals< ActiveRecord::Migration
  def change

      rename_table :drug_natures, :animal_drug_natures
      rename_table :diseases, :animal_diseases
  end
end