# frozen_string_literal: true

# Active Storage tables. They live in each tenant schema, like every other
# business table: Apartment switches the search_path before the migration runs,
# so attachments are isolated per tenant exactly as their files are (see
# ActiveStorage::Service::TenantDiskService).
class CreateActiveStorageTables < ActiveRecord::Migration[5.2]
  def change
    create_table :active_storage_blobs do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.bigint   :byte_size,    null: false
      t.string   :checksum,     null: false
      t.datetime :created_at,   null: false

      t.index [:key], unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string     :name,     null: false
      t.references :record,   null: false, polymorphic: true, index: false
      t.references :blob,     null: false

      t.datetime :created_at, null: false

      t.index %i[record_type record_id name blob_id],
              name: 'index_active_storage_attachments_uniqueness', unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
