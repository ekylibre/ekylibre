class AddActivitySeasons < ActiveRecord::Migration
  def change
    create_table :activity_seasons do |t|
      t.references :activity, null: false, index: true
      t.string :name
      t.stamps
    end

    add_reference :activity_productions, :activity_season, index: true
  end
end
