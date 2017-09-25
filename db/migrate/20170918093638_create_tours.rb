class CreateTours < ActiveRecord::Migration
  def change
    create_table :tours do |t|
      t.string :page
      t.string :title
      t.string :content
      t.boolean :enabled, default: true
      t.string :position
      t.string :language

      t.timestamps null: false
    end
  end
end
