class MergeDocumentArchivesToDocuments < ActiveRecord::Migration

  def id_partition(id)
    ("%09d" % id.to_i).scan(/\d{3}/).join("/")
  end

  def change

    add_column :documents, :uploaded, :boolean, null: false, default: false

    # add_column :documents, :archived_at, :datetime, null: false
    add_column :documents, :template_id, :integer
    add_column :documents, :file_file_name, :string
    add_column :documents, :file_file_size, :integer
    add_column :documents, :file_content_type, :string
    add_column :documents, :file_updated_at, :datetime
    add_column :documents, :file_fingerprint, :string
    add_column :documents, :file_pages_count, :integer
    add_column :documents, :file_content_text, :text

    remove_column :documents, :archives_count, :integer, default: 0, null: false

    reversible do |r|
      r.up do

        execute <<-SQL
          UPDATE documents
          SET template_id = document_archives.template_id,
           file_file_name = document_archives.file_file_name,
           file_file_size = document_archives.file_file_size,
           file_content_type = document_archives.file_content_type,
           file_updated_at = document_archives.file_updated_at,
           file_fingerprint = document_archives.file_fingerprint,
           file_pages_count = document_archives.file_pages_count,
           file_content_text = document_archives.file_content_text
          FROM document_archives
          WHERE document_archives.document_id = documents.id
        SQL

        doc_path =  Ekylibre::Tenant.private_directory.join('attachments').join('documents')
        doc_a_path =  Ekylibre::Tenant.private_directory.join('attachments').join('document_archives')

        if doc_path.is_a?(Pathname) && doc_a_path.is_a?(Pathname)

          unless File.directory?(doc_path)
            FileUtils.mkdir_p(doc_path)
          end

          for doc_a in connection.select_rows("SELECT id, document_id FROM document_archives")

            doc_a_dir = doc_a_path.join(self.id_partition(doc_a[0]))

            if File.directory?(doc_a_dir)

              doc_dir = doc_path.join(self.id_partition(doc_a[1]))

              unless File.directory?(doc_dir)
                FileUtils.mkdir_p(doc_dir)
              end

              if File.directory?(doc_dir)
                FileUtils.mv Dir.glob("#{doc_a_dir}/*"), doc_dir
              end

            end

          end

          FileUtils.remove_dir(doc_a_path,true)

        else
          raise "Not a path"
        end


        drop_table :document_archives

      end

      r.down do
        create_table "document_archives", force: :cascade do |t|
          t.integer  "document_id",                   null: false
          t.datetime "archived_at",                   null: false
          t.integer  "template_id"
          t.string   "file_file_name"
          t.integer  "file_file_size"
          t.string   "file_content_type"
          t.datetime "file_updated_at"
          t.string   "file_fingerprint"
          t.integer  "file_pages_count"
          t.text     "file_content_text"
          t.datetime "created_at",                    null: false
          t.datetime "updated_at",                    null: false
          t.integer  "creator_id"
          t.integer  "updater_id"
          t.integer  "lock_version",      default: 0, null: false
        end

        add_index "document_archives", ["archived_at"], name: "index_document_archives_on_archived_at", using: :btree
        add_index "document_archives", ["created_at"], name: "index_document_archives_on_created_at", using: :btree
        add_index "document_archives", ["creator_id"], name: "index_document_archives_on_creator_id", using: :btree
        add_index "document_archives", ["document_id"], name: "index_document_archives_on_document_id", using: :btree
        add_index "document_archives", ["template_id"], name: "index_document_archives_on_template_id", using: :btree
        add_index "document_archives", ["updated_at"], name: "index_document_archives_on_updated_at", using: :btree
        add_index "document_archives", ["updater_id"], name: "index_document_archives_on_updater_id", using: :btree

        execute <<-SQL
          INSERT INTO document_archives
           (document_id, archived_at, template_id, file_file_name, file_file_size, file_content_type,
            file_updated_at, file_fingerprint, file_pages_count, file_content_text, created_at, updated_at)
          SELECT id, file_updated_at, template_id, file_file_name, file_file_size, file_content_type, file_updated_at,
            file_fingerprint, file_pages_count, file_content_text, file_updated_at, file_updated_at from documents
        SQL


        # restore file structure
        doc_path =  Ekylibre::Tenant.private_directory.join('attachments').join('documents')
        doc_a_path =  Ekylibre::Tenant.private_directory.join('attachments').join('document_archives')

        if doc_path.is_a?(Pathname) && doc_a_path.is_a?(Pathname)

          unless File.directory?(doc_a_path)
            FileUtils.mkdir_p(doc_a_path)
          end

          for doc in connection.select_rows("SELECT id, document_id FROM document_archives")

            doc_dir = doc_path.join(self.id_partition(doc[1]))

            if File.directory?(doc_dir)

              doc_a_dir = doc_a_path.join(self.id_partition(doc[0]))

              unless File.directory?(doc_a_dir)
                FileUtils.mkdir_p(doc_a_dir)
              end

              if File.directory?(doc_a_dir)
                FileUtils.mv Dir.glob("#{doc_dir}/*"), doc_a_dir
              end

            end

          end

          FileUtils.remove_dir(doc_path,true)

        else
          raise "Not a path"
        end


      end
    end

  end
end
