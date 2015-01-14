class AddAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.references :resource,    polymorphic: true, null: false, index: true
      t.references :document,                       null: false, index: true
      t.string     :nature,                         null: false
      t.datetime   :expired_at
      t.stamps
    end

    execute "INSERT INTO attachments (resource_type, resource_id, document_id, nature, created_at, creator_id, updated_at, updater_id, lock_version) SELECT 'Prescription', p.id, d.id, d.nature, p.created_at, p.creator_id, p.updated_at, p.updater_id, p.lock_version FROM prescriptions AS p JOIN documents AS d ON (document_id = d.id)"

    remove_column :prescriptions, :document_id
  end
end
