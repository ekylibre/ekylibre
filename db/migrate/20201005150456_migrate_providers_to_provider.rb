class MigrateProvidersToProvider < ActiveRecord::Migration
  def change
    execute <<~SQL
      UPDATE interventions
      SET "provider" = CONCAT('{"vendor": "ekylibre", "name": "zero", "id": 0, "data": {"zero_id": ', providers->>'zero_id', ' }}')::json
      WHERE "providers" IS NOT NULL
    SQL
  end
end
