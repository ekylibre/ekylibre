class CreateTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.string :name, null: false
      t.string :value, null: false

      t.stamps
    end

    add_index :tokens, :name, unique: true
  end
end
