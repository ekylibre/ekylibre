class CorrectTreatmentAnimals< ActiveRecord::Migration
  def up

   change_table :animal_posologies do |t|
     t.remove :decimal
   end

    change_table :animal_group_events do |t|
      t.string :name
    end

  end

  def down

    change_table :animal_group_events do |t|
      t.remove :name
    end

  end

end