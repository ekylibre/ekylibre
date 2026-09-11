# frozen_string_literal: true

# Reprise de la migration qu'Active Storage fournit dans `db/update_migrate`.
#
# Elle est requise par `config.active_storage.track_variants`, que
# `load_defaults 6.1` active : les variantes cessent d'être identifiées par la
# seule clé de leur blob et sont suivies par un enregistrement propre, ce qui
# permet de les purger avec lui.
#
# Recopiée plutôt qu'installée par `rails active_storage:update` pour porter
# l'horodatage de la série d'Ekylibre et être rejouée sur chaque schéma de
# tenant comme les autres.
class CreateActiveStorageVariantRecords < ActiveRecord::Migration[6.1]
  def change
    return unless table_exists?(:active_storage_blobs)

    create_table :active_storage_variant_records, if_not_exists: true do |t|
      t.belongs_to :blob, null: false, index: false, type: blobs_primary_key_type
      t.string :variation_digest, null: false

      t.index %i[blob_id variation_digest], name: 'index_active_storage_variant_records_uniqueness', unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end

  private

    def blobs_primary_key_type
      pkey_name = connection.primary_key(:active_storage_blobs)
      pkey_column = connection.columns(:active_storage_blobs).find { |c| c.name == pkey_name }
      pkey_column.bigint? ? :bigint : pkey_column.type
    end
end
