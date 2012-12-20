class UpdateTreatments< ActiveRecord::Migration
  def change

    change_table :animal_events do |t|
       t.belongs_to     :treatment
    end
    add_index :animal_events, :treatment_id

  end
end