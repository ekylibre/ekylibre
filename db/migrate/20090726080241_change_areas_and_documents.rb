class ChangeAreasAndDocuments < ActiveRecord::Migration
  def self.up
    # It's like the table creation because it was never used
    add_column :documents, :template,    :string  #,  :null=>false
    add_column :documents, :subdir,      :string  #,  :null=>false
    add_column :documents, :extension,   :string  #,  :null=>false
    add_column :documents, :owner_id,    :integer #, :null=>false
    add_column :documents, :owner_type,  :string  #,  :null=>false
    add_index :documents, :owner_id
    add_index :documents, :owner_type

    add_column :contacts, :line_6, :string
    add_column :areas, :country, :string, :limit=>2, :default=>"\?\?"
    add_column :areas, :district_id, :integer
    add_column :areas, :city, :string
    add_column :areas, :city_name, :string
    add_column :areas, :code, :string
    add_column :districts, :code, :string
    add_index :areas, :district_id
    change_column :areas, :city_id, :integer, :null=>true

    execute "UPDATE #{quoted_table_name(:contacts)} SET line_6="+connection.concatenate(connection.trim("line_6_code"), "' '", connection.trim("line_6_city"))
    execute "INSERT INTO #{quoted_table_name(:areas)} (name, postcode, city, city_name, company_id, created_at, updated_at) SELECT DISTINCT COALESCE(line_6,''), COALESCE(line_6_code,''), line_6_city, "+connection.trim("REPLACE(UPPER(line_6_city), 'CEDEX', '')")+", contacts.company_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM #{quoted_table_name(:contacts)} AS contacts LEFT JOIN #{quoted_table_name(:areas)} AS areas ON (contacts.line_6=areas.name) WHERE areas.id IS NULL"
    execute "UPDATE #{quoted_table_name(:areas)} SET country='fr'"
    for result in connection.select_all("SELECT id, name, company_id FROM #{quoted_table_name(:areas)}")
      execute "UPDATE #{quoted_table_name(:contacts)} SET area_id=#{result['id']} WHERE company_id=#{result['company_id']} AND line_6='"+result['name'].gsub("'","''")+"'"
    end
    for result in connection.select_all("SELECT id, name, district_id FROM #{quoted_table_name(:cities)}")
      execute "UPDATE #{quoted_table_name(:areas)} SET city='"+result['name'].gsub("'","''")+"', district_id=#{result['district_id']||'NULL'} WHERE city_id=#{result['id']}"
    end

    remove_column :areas, :city_id
    remove_column :contacts, :line_6_code
    remove_column :contacts, :line_6_city    
    remove_column :documents, :key

    drop_table :cities
    drop_table :templates
  end

  def self.down
    create_table :templates do |t|
      t.column :name,                   :string,   :null=>false
      t.column :content,                :text,     :null=>false
      t.column :cache,                  :text    
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_stamps :templates
    add_index :templates, :company_id
    add_index :templates, [:company_id, :name], :unique=>true

    create_table :cities do |t|
      t.column :insee_cdc, :string, :limit=>1
      t.column :insee_cheflieu, :string, :limit=>1
      t.column :insee_reg, :string, :limit=>2
      t.column :insee_dep, :string, :limit=>3
      t.column :insee_com, :string, :limit=>3
      t.column :insee_ar, :string, :limit=>1
      t.column :insee_ct, :string, :limit=>2
      # Type de nom en clair
      t.column :insee_tncc, :string, :limit=>1
      # Article en majuscule
      t.column :insee_artmaj, :string, :limit=>5
      # Nom en clair (majuscule)
      t.column :insee_ncc, :string, :limit=>70
      # Article (typographie en riche)
      t.column :insee_artmin, :string, :limit=>5
      # Nom en clair (typographie riche)
      t.column :insee_nccenr, :string, :limit=>70
      
      t.column :name, :string, :null=>false
      t.column :district_id, :integer, :references=>:districts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id, :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_stamps :cities
    
    add_column :documents, :key, :integer
    add_column :contacts, :line_6_code, :string, :limit=>38
    add_column :contacts, :line_6_city, :string, :limit=>38
    add_column :areas, :city_id, :integer


    execute("INSERT INTO #{quoted_table_name(:cities)} (name, district_id, company_id, created_at, updated_at) SELECT DISTINCT COALESCE(city,''), district_id, company_id, current_timestamp, current_timestamp FROM #{quoted_table_name(:areas)} AS areas")
    for result in connection.select_all("SELECT id, name, company_id FROM #{quoted_table_name(:cities)}")
      execute "UPDATE #{quoted_table_name(:areas)} SET city_id=#{result['id']} WHERE company_id=#{result['company_id']} AND city='"+result['name'].gsub("'","''")+"'"
    end
    for result in connection.select_all("SELECT id, postcode, city FROM #{quoted_table_name(:areas)}")
      execute "UPDATE #{quoted_table_name(:contacts)} SET line_6_code='"+result['postcode'].to_s.gsub("'","''")+"', line_6_city='"+result['city'].to_s.gsub("'","''")+"' WHERE area_id=#{result['id']} "
    end

    remove_column :districts, :code
    remove_column :areas, :code
    remove_column :areas, :city_name
    remove_column :areas, :city
    remove_column :areas, :district_id
    remove_column :areas, :country
    remove_column :contacts, :line_6
    
    # It's like the table destruction because it was never used before this migration
    remove_column :documents, :template
    remove_column :documents, :subdir
    remove_column :documents, :extension
    remove_column :documents, :owner_id
    remove_column :documents, :owner_type

    FileUtils.rm_rf(Rails.root.join("private"))
    execute "DELETE FROM #{quoted_table_name(:documents)}"
  end
end
