class ChangeBadColumnsAndIndexes < ActiveRecord::Migration
  def self.up
    remove_index :accounts, :column=>[:alpha, :company_id]
    remove_index :companies, :column=>[:name]
    add_index :companies, [:name]
    remove_index :users, :column=>[:name]
    add_index :users, [:name, :company_id], :unique=>true

    add_column :price_taxes, :company_id, :integer
    taxes = connection.select_all("SELECT * FROM #{quoted_table_name(:taxes)}")
    execute "UPDATE #{quoted_table_name(:price_taxes)} SET company_id=CASE"+taxes.collect{|t| "WHEN tax_id=#{t['id']} THEN #{t['company_id']}"}.join(" ")+" ELSE 0 END" if taxes.size > 0

    change_column_null :price_taxes, :company_id, false

    remove_index :complement_data, :columns=>[:complement_id, :entity_id], :name => "index_#{quoted_table_name(:complement_data)}_on_entity_id_and_complement_id"
    remove_index :price_taxes, :columns=>[:price_id, :tax_id], :name => "index_#{quoted_table_name(:price_taxes)}_on_price_id_and_tax_id"
    add_index :complement_data, [:company_id, :complement_id, :entity_id], :name => "index_#{quoted_table_name(:complement_data)}_on_entity_id_and_complement_id", :unique=>true
    add_index :price_taxes, [:company_id, :price_id, :tax_id], :name => "index_#{quoted_table_name(:price_taxes)}_on_price_id_and_tax_id", :unique=>true
    
    add_column :languages, :company_id, :integer
    execute "DELETE FROM #{quoted_table_name(:languages)}"
    execute "INSERT INTO #{quoted_table_name(:languages)} (name, native_name, iso2, iso3, company_id) SELECT 'French', 'Français', 'fr', 'fra', id FROM #{quoted_table_name(:companies)} AS companies"
    languages = connection.select_all("SELECT * FROM #{quoted_table_name(:languages)}")
    if languages.size > 0
      languages = "CASE "+languages.collect{|l| "WHEN company_id=#{l['company_id']} THEN #{l['id']}"}.join(" ")+" ELSE 0 END"
      execute "UPDATE #{quoted_table_name(:entities)} SET language_id=#{languages}"
    end
  end

  def self.down

    ref = {}
    for iso in connection.select_values("SELECT DISTINCT iso2 FROM #{quoted_table_name(:languages)}")
      ref[iso] = connection.select_value("SELECT id FROM #{quoted_table_name(:languages)} WHERE iso2='#{iso}' LIMIT 1")
    end
    for company in connection.select_all("SELECT * FROM #{quoted_table_name(:companies)}")
      for language in connection.select_all("SELECT * FROM #{quoted_table_name(:languages)} WHERE company_id=#{company['id']}")
        execute "UPDATE #{quoted_table_name(:entities)} SET language_id=#{ref[language['iso2']]} WHERE language_id=#{language['id']}"
        execute "DELETE FROM #{quoted_table_name(:languages)} WHERE id=#{language['id']}" if language['id']!=ref[language['iso2']]
      end
    end
    remove_column :languages, :company_id

    remove_index :complement_data, :columns=>[:company_id, :complement_id, :entity_id], :name => "index_#{quoted_table_name(:complement_data)}_on_entity_id_and_complement_id"
    remove_index :price_taxes, :columns=>[:company_id, :price_id, :tax_id], :name=> "index_#{quoted_table_name(:price_taxes)}_on_price_id_and_tax_id"
    add_index :complement_data, [:complement_id, :entity_id], :name => "index_#{quoted_table_name(:complement_data)}_on_entity_id_and_complement_id"
    add_index :price_taxes, [:price_id, :tax_id], :name=> "index_#{quoted_table_name(:price_taxes)}_on_price_id_and_tax_id"

    remove_column :price_taxes, :company_id

    remove_index :users, :column=>[:name, :company_id]
    add_index :users, [:name]
    # add_index :companies, [:name]
    add_index :accounts, [:alpha, :company_id]
  end
end
