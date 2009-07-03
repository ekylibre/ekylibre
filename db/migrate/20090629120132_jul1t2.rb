class Jul1t2 < ActiveRecord::Migration
  def self.up
    
    Company.find(:all).each do |company|
      if company.sales_journal_id.nil?
        sales = company.journals.create!(:name=>"Journal de ventes", :nature=>"sale", :currency_id=>company.currencies.find(:first).id)
        company.sales_journal_id = sales.id
        company.save
      end
      
      if company.purchases_journal_id.nil?
        purchases = company.journals.create!(:name=>"Journal d'achats", :nature=>"purchase", :currency_id=>company.currencies.find(:first).id)
        company.purchases_journal_id = purchases.id
        company.save
      end
      
      if company.bank_journal_id.nil?
        bank = company.journals.create!(:name=>"Journal de banque", :nature=>"bank", :currency_id=>company.currencies.find(:first).id)
        company.bank_journal_id = bank.id
        company.save
      end
      
      company.financialyears.create!(:code=>"2009/2010", :started_on=>Date.today, :stopped_on=>Date.today+(365)) if company.financialyears.size == 0
    end
    
#     Tax.find(:all).each do |tax|
#       if tax.company.accounts.size > 140
#         if tax.account_collected_id.nil?
#           if tax.amount == 0.0210
#             tax.account_collected_id = Account.find_by_company_id_and_number(tax.company_id, "445711").id
#           elsif tax.amount == 0.0550
#             tax.account_collected_id = Account.find_by_company_id_and_number(tax.company_id, "445712").id
#           elsif tax.amount == 0.1960
#             tax.account_collected_id = Account.find_by_company_id_and_number(tax.company_id, "445713").id
#           end
#           tax.save
#         end
    #       end
    #  end
    
    Tax.find(:all).each do |tax|
      tax.save
    end
    
    remove_column :roles, :actions
    add_column :roles,    :rights,  :text
    #add_column :entries, :fog, :boolean, :null=>false, :default=>true

    Role.find(:all).each do |role|
      if role.name == "Administrateur"
        role.rights = "administrate"
        role.save
      end
    end
    
  end
    
  def self.down
    remove_column :roles, :rights
    add_column :roles, :actions, :text
  end
end
