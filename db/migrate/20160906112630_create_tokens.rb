class CreateTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.string :name, null: false
      t.string :value, null: false
      t.stamps
      t.index :name, unique: true
    end
  end
end
