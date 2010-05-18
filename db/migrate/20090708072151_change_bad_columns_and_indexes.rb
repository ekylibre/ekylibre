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
    for language in Language.all
      for company in Company.all
        attrs = language.attributes.merge('company_id'=>company.id)
        attrs.delete('id')
        l = Language.create!(attrs)
        Entity.update_all({:language_id=>l.id}, {:language_id=>language.id, :company_id=>company.id})
      end
    end
    Language.delete_all(["company_id IS NULL"])
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
