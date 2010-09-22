class MergeAndRemoveDocumentNatures < ActiveRecord::Migration
  def self.up
    add_column :document_templates, :code,   :string, :limit=>32
    add_column :document_templates, :family, :string, :limit=>32
    add_column :document_templates, :to_archive, :boolean

    for nature in connection.select_all("SELECT * FROM #{quoted_table_name(:document_natures)}")
      to_archive = ["f", "false", "0", ""].include?(nature['to_archive'].to_s) ? quoted_false : quoted_true
      execute "UPDATE #{quoted_table_name(:document_templates)} SET code='#{nature['code'].gsub('\'','\'\'')}', family='#{nature['family'].gsub('\'','\'\'')}', to_archive=#{to_archive} WHERE nature_id=#{nature['id']}"
    end

    remove_index :document_templates, :column=>:nature_id
    remove_index :document_templates, :column=>[:company_id, :nature_id]
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
    add_index :document_templates, [:company_id, :nature_id]
    add_index :document_templates, :nature_id
    
    for nature in connection.select_all("SELECT * FROM #{quoted_table_name(:document_templates)}")
      to_archive = ["f", "false", "0", ""].include?(nature['to_archive'].to_s) ? quoted_false : quoted_true
      id = connection.insert "INSERT INTO #{quoted_table_name(:document_natures)} (created_at, updated_at, company_id, name, code, family, to_archive) SELECT CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, #{nature['company_id']}, '#{nature['name'].gsub('\'','\'\'')}', '#{nature['code'].gsub('\'','\'\'')}', '#{nature['family'].gsub('\'','\'\'')}', #{to_archive}"
      execute "UPDATE #{quoted_table_name(:document_templates)} SET nature_id=#{id} WHERE id=#{nature['id']}"
    end

    remove_column :document_templates, :code
    remove_column :document_templates, :family
    remove_column :document_templates, :to_archive
  end
end
