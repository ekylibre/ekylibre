class FixDocumentTemplateExtension < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        query <<~SQL
          UPDATE "document_templates"
          SET "file_extension" = 'odt'
          WHERE "file_extension" = '?'
        SQL
      end
    end

  end
end
