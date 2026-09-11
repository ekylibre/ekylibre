# frozen_string_literal: true

# Reprise de la migration qu'Active Storage 6.1 fournit dans
# `db/update_migrate` : la colonne `service_name` y devient obligatoire, chaque
# blob mémorisant désormais le service qui l'héberge.
#
# Elle est recopiée plutôt qu'installée par `rails active_storage:update` pour
# qu'elle porte l'horodatage de la série d'Ekylibre et soit rejouée sur chaque
# schéma de tenant comme les autres.
class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[6.1]
  def up
    return unless table_exists?(:active_storage_blobs)
    return if column_exists?(:active_storage_blobs, :service_name)

    add_column :active_storage_blobs, :service_name, :string

    if (configured_service = ActiveStorage::Blob.service.name)
      ActiveStorage::Blob.unscoped.update_all(service_name: configured_service)
    end

    change_column_null :active_storage_blobs, :service_name, false
  end

  def down
    return unless table_exists?(:active_storage_blobs)

    remove_column :active_storage_blobs, :service_name
  end
end
