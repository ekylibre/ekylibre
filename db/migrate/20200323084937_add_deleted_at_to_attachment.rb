class AddDeletedAtToAttachment < ActiveRecord::Migration
  def change
    add_column :attachments, :deleted_at, :datetime
    add_index :attachments, :deleted_at
    add_column :attachments, :deleter_id, :integer
  end
end
