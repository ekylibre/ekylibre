class Jul2b1 < ActiveRecord::Migration
  def self.up
    remove_index :accounts, :column=>[:alpha, :company_id]
    remove_index :users, :column=>[:name]
    add_index :users, [:name, :company_id], :unique=>true
    add_column :languages, :company_id, :integer

    for language in Language.find(:all)
      for company in Company.find(:all)
        attrs =language.attributes.merge(:company_id=>company.id)
        attrs.delete(:id)
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
    for company in Company.find(:all)
      for language in Language.find(:all, :conditions=>{:company_id=>company.id})
        Entity.update_all({:language_id=>ref[language.iso2].id}, {:language_id=>language.id})
        Language.delete(language) if language.id!=ref[language.iso2].id
      end
    end

    remove_column :languages, :company_id
    remove_index :users, :column=>[:name, :company_id]
    add_index :users, [:name]
    add_index :accounts, [:alpha, :company_id]
  end
end
