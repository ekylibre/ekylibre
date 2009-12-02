class AddDocumentTemplatesFilename < ActiveRecord::Migration
  def self.up

    add_column :document_templates, :filename, :string

  end
  
  def self.down
    
    remove_column :document_templates, :filename

  end
end
