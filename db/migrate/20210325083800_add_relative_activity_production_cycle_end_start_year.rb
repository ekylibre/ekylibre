class AddRelativeActivityProductionCycleEndStartYear < ActiveRecord::Migration[5.0]
  def change
    change_table :activities do |t|
      t.integer :production_started_on_year
      t.integer :production_stopped_on_year
    end
  end
end
