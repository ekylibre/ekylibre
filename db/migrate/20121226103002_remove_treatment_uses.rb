class RemoveTreatmentUses< ActiveRecord::Migration
  def up
     drop_table :animal_treatment_uses
  end
  
  def down
     
  end
  
end