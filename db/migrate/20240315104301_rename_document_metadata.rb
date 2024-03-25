class RenameDocumentMetadata < ActiveRecord::Migration[5.2]
  def change
    rename_column :documents, :klippa_metadata, :metadata
  end
end


