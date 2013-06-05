class UnifyDocuments < ActiveRecord::Migration
  def rename_table_and_indexes(old_table, new_table)
    rename_table(old_table, new_table)
    # Updates indexes names
    for index in indexes(new_table)
      rename_index new_table, index.name.to_sym, ("index_#{new_table}_on_" + index.columns.join("_and_")).to_sym
    end
  end

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


    # Create DocumentVersion from old Document
    rename_table_and_indexes :documents, :document_archives

    # Create Document
    create_table :documents do |t|
      t.string :number, :null => false, :limit => 63
      t.string :name,   :null => false
      t.string :nature, :null => false, :limit => 63
      t.integer :archives_count, :null => false, :default => 0
      t.references :template, :polymorphic => true
      t.string     :datasource, :limit => 63
      t.text       :datasource_parameters
      t.stamps
    end
    add_stamps_indexes :documents
    add_index :documents, :number
    add_index :documents, :name
    add_index :documents, :nature
    add_index :documents, :datasource


    # Documents
    # TODO Move documents to the new dir
    add_column :document_archives, :position, :integer
    # add_column :document_archives, :nature, :string, :limit => 63
    # change_column_null :document_archives, :nature, false
    rename_column :document_archives, :printed_at, :archived_at
    # rename_column :document_archives, :owner_id, :datasource_id
    # rename_column :document_archives, :owner_type, :datasource_type
    # add_column :document_archives, :name, :string, :null => false
    rename_column :document_archives, :filename, :file_file_name
    add_column :document_archives, :file_content_type, :string
    rename_column :document_archives, :filesize, :file_file_size
    add_column :document_archives, :file_updated_at, :datetime
    add_column :document_archives, :file_fingerprint, :string
    add_column :document_archives, :document_id, :integer
    add_index :document_archives, :document_id

    add_column :documents, :archive_id, :integer
    execute("UPDATE #{quoted_table_name(:documents)} SET archives_count = 1")
    # TODO Adds a good datasource conversion
    execute "INSERT INTO #{quoted_table_name(:documents)} (datasource, datasource_parameters, name, archive_id, created_at, creator_id, updated_at, updater_id) SELECT owner_type, owner_id, original_name, id, created_at, creator_id, updated_at, updater_id FROM #{quoted_table_name(:document_archives)}"
    execute "UPDATE #{quoted_table_name(:document_archives)} SET document_id = d.id, position = 1 FROM #{quoted_table_name(:documents)} AS d WHERE d.archive_id = #{quoted_table_name(:document_archives)}.id"
    remove_column :documents, :archive_id
    change_column_null :document_archives, :document_id, false

    # remove_column :document_archives, :name
    # remove_column :document_archives, :nature
    remove_column :document_archives, :owner_id
    remove_column :document_archives, :owner_type

    remove_column :document_archives, :original_name
    remove_column :document_archives, :crypt_key
    remove_column :document_archives, :crypt_mode
    remove_column :document_archives, :extension
    remove_column :document_archives, :subdir
    remove_column :document_archives, :sha256
    remove_column :document_archives, :nature_code
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
