class AddMetadataToDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :klippa_metadata, :jsonb, default: {}
  end
end
