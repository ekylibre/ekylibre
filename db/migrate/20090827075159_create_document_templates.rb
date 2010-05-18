class CreateDocumentTemplates < ActiveRecord::Migration
  def self.up
    create_table :document_natures do |t|
      t.column :name,                   :string,   :null=>false
      t.column :code,                   :string,   :null=>false
      t.column :to_archive,             :boolean,  :null=>false, :default=>false
      t.column :family,                 :string
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :document_natures, :company_id

    create_table :document_templates do |t|
      t.column :name,                   :string,   :null=>false
      t.column :nature_id,              :integer,  :null=>false, :references=>:document_natures
      t.column :active,                 :boolean,  :null=>false, :default=>false
      t.column :deleted,                :boolean,  :null=>false, :default=>false
      t.column :source,                 :text
      t.column :cache,                  :text
      t.column :language_id,            :integer,  :references=>:languages
      t.column :country,                :string,   :limit=>2
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :document_templates, :company_id
    add_index :document_templates, :nature_id
    add_index :document_templates, :language_id
    add_index :document_templates, [:company_id, :name]
    add_index :document_templates, [:company_id, :nature_id]
    add_index :document_templates, [:company_id, :active]

    add_column :documents, :template_id, :integer, :references=>:document_templates

    remove_column :documents, :template
  end

  def self.down
    add_column :documents, :template, :string

    remove_column :documents, :template_id

    drop_table :document_templates
    drop_table :document_natures
  end
end
