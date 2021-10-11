class MigrateProvidersToProvider < ActiveRecord::Migration[4.2]
  def change
    execute <<~SQL
      UPDATE interventions
      SET "provider" = CONCAT('{"vendor": "ekylibre", "name": "zero", "id": 0, "data": {"zero_id": ', providers->>'zero_id', ' }}')::json
      WHERE "providers" IS NOT NULL AND "providers"->>'zero_id' IS NOT NULL
    SQL
  end
end
