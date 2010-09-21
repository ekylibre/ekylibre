class FillDocumentTemplatesNature < ActiveRecord::Migration
  def self.up
    execute "UPDATE #{quote_table_name(:document_templates)} SET nature = code WHERE nature IS NULL"
  end

  def self.down
  end
end
