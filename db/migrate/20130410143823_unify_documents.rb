class UnifyDocuments < ActiveRecord::Migration
  def up
    # Templates
    change_column :document_templates, :nature, :string, :limit => 63, :null => false
    add_column :document_templates, :archiving, :string, :limit => 63
    add_column :document_templates, :managed, :boolean, :null => false, :default => false
    add_column :document_templates, :formats, :string
    execute "UPDATE #{quoted_table_name(:document_templates)} SET archiving = CASE WHEN to_archive THEN 'last' ELSE 'nothing' END"
    change_column_null :document_templates, :archiving, false
    change_column_default :document_templates, :language, nil
    change_column_default :document_templates, :by_default, false

    root = Rails.root.join("private", "reporting")
    for template in select_all("SELECT id, source FROM #{quoted_table_name(:document_templates)}")
      file = root.join(template["id"], "content.xml")
      FileUtils.mkdir_p(file.dirname)
      File.open(file, "rb") do |f|
        f.write(template["source"])
      end
    end

    remove_column :document_templates, :country
    remove_column :document_templates, :to_archive
    remove_column :document_templates, :family
    remove_column :document_templates, :cache
    remove_column :document_templates, :code
    remove_column :document_templates, :filename
    remove_column :document_templates, :source

    # Documents
    # TODO Move documents
    add_column :documents, :nature, :string, :limit => 63
    change_column_null :documents, :nature, false
    rename_column :documents, :printed_at, :archived_at
    rename_column :documents, :owner_id, :origin_id
    rename_column :documents, :owner_type, :origin_type
    add_column :documents, :name, :string, :null => false
    rename_column :documents, :filename, :file_file_name
    add_column :documents, :file_content_type, :string
    rename_column :documents, :filesize, :file_file_size
    add_column :documents, :file_updated_at, :datetime
    add_column :documents, :file_fingerprint, :string
    remove_column :documents, :original_name
    remove_column :documents, :crypt_key
    remove_column :documents, :crypt_mode
    remove_column :documents, :extension
    remove_column :documents, :subdir
    remove_column :documents, :sha256
    remove_column :documents, :nature_code
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
