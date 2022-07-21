class AddProcessableAttachmentToDocument < ActiveRecord::Migration[4.2]
  def change
    add_column :documents, :processable_attachment, :boolean, null: false, default: true
  end
end
