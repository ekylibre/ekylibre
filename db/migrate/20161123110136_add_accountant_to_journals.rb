class AddAccountantToJournals < ActiveRecord::Migration
  def change
    change_table :journals do |t|
      t.references :accountant, index: true
    end
  end
end
