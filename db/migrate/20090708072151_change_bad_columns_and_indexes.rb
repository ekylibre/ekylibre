class ChangeBadColumnsAndIndexes < ActiveRecord::Migration
  def self.up
    remove_index :accounts, :column=>[:alpha, :company_id]
    remove_index :companies, :column=>[:name]
    add_index :companies, [:name]
    remove_index :users, :column=>[:name]
    add_index :users, [:name, :company_id], :unique=>true

    add_column :price_taxes, :company_id, :integer
    for company in Company.all
      if company.taxes.size>0
        execute "UPDATE price_taxes SET company_id=#{company.id} WHERE tax_id IN (#{company.taxes.collect{|t| t.id}.join(',')})"
      end
    end
    change_column_null :price_taxes, :company_id, false

    remove_index :complement_data, :columns=>[:complement_id, :entity_id], :name => "index_complement_data_on_entity_id_and_complement_id"
    remove_index :price_taxes, :columns=>[:price_id, :tax_id], :name => "index_price_taxes_on_price_id_and_tax_id"
    add_index :complement_data, [:company_id, :complement_id, :entity_id], :name => "index_complement_data_on_entity_id_and_complement_id", :unique=>true
    add_index :price_taxes, [:company_id, :price_id, :tax_id], :name => "index_price_taxes_on_price_id_and_tax_id", :unique=>true
    
    add_column :languages, :company_id, :integer
    execute "DELETE FROM languages"
    insert  "INSERT INTO languages(name, native_name, iso2, iso3, company_id) SELECT 'French', 'Français', 'fr', 'fra', id FROM companies"
    languages = select_all("SELECT * FROM languages")
    if languages.size > 0
      languages = "CASE "+languages.collect{|l| "WHEN company_id=#{l['company_id']} THEN #{l['id']}"}.join(" ")+" ELSE 0 END"
      execute "UPDATE entities SET language_id=#{languages}"
    end
  end

  def self.down

    ref = {}
    for iso in Language.find_by_sql("SELECT DISTINCT iso2 FROM languages").collect{|x| x.iso2}
      ref[iso] = Language.find_by_iso2(iso)
    end
    for company in Company.all
      for language in Language.find(:all, :conditions=>{:company_id=>company.id})
        Entity.update_all({:language_id=>ref[language.iso2].id}, {:language_id=>language.id})
        Language.delete(language) if language.id!=ref[language.iso2].id
      end
    end
    remove_column :languages, :company_id

    remove_index :complement_data, :columns=>[:company_id, :complement_id, :entity_id], :name => "index_complement_data_on_entity_id_and_complement_id"
    remove_index :price_taxes, :columns=>[:company_id, :price_id, :tax_id], :name=> "index_price_taxes_on_price_id_and_tax_id"
    add_index :complement_data, [:complement_id, :entity_id], :name => "index_complement_data_on_entity_id_and_complement_id"
    add_index :price_taxes, [:price_id, :tax_id], :name=> "index_price_taxes_on_price_id_and_tax_id"

    remove_column :price_taxes, :company_id

    remove_index :users, :column=>[:name, :company_id]
    add_index :users, [:name]
    # add_index :companies, [:name]
    add_index :accounts, [:alpha, :company_id]
  end
end
