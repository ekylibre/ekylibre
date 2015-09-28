class UpdateNatureOfDocuments < ActiveRecord::Migration
  def up
    change_column :documents, :nature, :string, null: true
    change_column :attachments, :nature, :string, null: true
  end

  def down
    change_column :documents, :nature, :string, null: false
    change_column :attachments, :nature, :string, null: false
  end
end
