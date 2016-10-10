class AddActivitySeasons < ActiveRecord::Migration
  def change
    create_table :activity_seasons do |t|
      t.references :activity, null: false, index: true
      t.string :name, null: false
      t.stamps
    end

    add_reference :activity_productions, :season, index: true
  end
end
