class CorrectTreatmentAnimals< ActiveRecord::Migration
  def up

    change_table :animal_posologies do |t|
      t.remove :decimal
    end

  end

  def down

  end

end