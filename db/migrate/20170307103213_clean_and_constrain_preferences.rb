class CleanAndConstrainPreferences < ActiveRecord::Migration
  def change
    execute <<-SQL
      DELETE FROM preferences
      WHERE id IN (SELECT id
                   FROM preferences
                     JOIN (SELECT duplicates.name AS name, COUNT(id) AS number, MAX(duplicates.created_at) AS to_keep_date
                           FROM preferences AS duplicates
                           GROUP BY duplicates.name) AS incidences
                     ON incidences.name = preferences.name
                 WHERE incidences.number > 1
                   AND preferences.created_at != incidences.to_keep_date)
    SQL

    add_index :preferences, %i[user_id name], unique: true
  end
end
