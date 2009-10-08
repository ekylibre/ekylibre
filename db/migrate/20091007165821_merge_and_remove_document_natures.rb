class MergeAndRemoveDocumentNatures < ActiveRecord::Migration
  def self.up
    add_column :document_templates, :code,   :string, :limit=>32
    add_column :document_templates, :family, :string, :limit=>32
    add_column :document_templates, :to_archive, :boolean

    for nature in select_all("SELECT * FROM document_natures")
      execute "UPDATE document_templates SET code='#{nature['code'].gsub('\'','\'\'')}', family='#{nature['family'].gsub('\'','\'\'')}', to_archive=CAST('#{nature['to_archive']}' AS BOOLEAN) WHERE nature_id=#{nature['id']}"
    end

    remove_column :document_templates, :nature_id
    drop_table :document_natures
  end

  def self.down
    create_table :document_natures do |t|
      t.column :name,                   :string,   :null=>false
      t.column :code,                   :string,   :null=>false
      t.column :to_archive,             :boolean,  :null=>false, :default=>false
      t.column :family,                 :string
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :document_natures, :company_id
    add_column :document_templates, :nature_id, :integer
    
    for nature in select_all("SELECT * FROM document_templates")
      id = insert "INSERT INTO document_natures (created_at, updated_at, company_id, name, code, family, to_archive) SELECT CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, #{nature['company_id']}, '#{nature['name'].gsub('\'','\'\'')}', '#{nature['code'].gsub('\'','\'\'')}', '#{nature['family'].gsub('\'','\'\'')}', CAST('#{nature['to_archive']}' AS BOOLEAN)"
      execute "UPDATE document_templates SET nature_id=#{id} WHERE id=#{nature['id']}"
    end

    remove_column :document_templates, :code
    remove_column :document_templates, :family
    remove_column :document_templates, :to_archive
  end
end
