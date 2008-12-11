 # == Schema Information
# Schema version: 20080819191919
#
# Table name: companies
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  code         :string(8)     not null
#  siren        :string(9)     
#  born_on      :date          
#  locked       :boolean       not null
#  deleted      :boolean       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Company < ActiveRecord::Base
  has_many :users
  
  def before_validation
    self.code = name.to_s[0..7].simpleize if code.blank?
    self.code = rand.to_s[2..100].to_i.to_s(36)[0..7] if code.blank?
    self.code.upper!
    while Company.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
      self.code.succ!
    end
    self.siren = '123456789' if self.siren.blank?
  end

  def after_create
    role = Role.create!(:name=>lc(:administrator), :company_id=>self.id)
    role.can_do :all
    role = Role.create!(:name=>lc(:public), :company_id=>self.id)
    self.parameter('general.language').value=Language.find_by_iso2('fr')
    self.load_template("#{RAILS_ROOT}/lib/template.xml")
    self.departments.create!(:name=>lc(:default_department_name))
    self.establishments.create!(:name=>lc(:default_establishment_name), :nic=>"00000")    
    self.journal_natures.create!(:name=>lc(:default_sales_journal_nature_name))
    self.journal_natures.create!(:name=>lc(:default_purchases_journal_nature_name))
    self.journal_natures.create!(:name=>lc(:default_bank_journal_nature_name))
    self.journal_natures.create!(:name=>lc(:default_operations_journal_nature_name))
    self.widgets.create!(:name=>'test', :location=>Location.find_by_name('side'), :nature=>'content')
   # menu = self.menus.create!(:name=>lc(:menu_principal) , :label=>'test label')
   # menu_item1 = menu.menu_items.create!(:name=>lc(:accueuil), :url=>'/guide' , :company_id => self.id)
   # menu_item2 = menu.menu_items.create!(:name=>lc(:compta), :url=>'/guide/accountancy', :company_id => self.id )
   # sous_menu1 = menu_item1.children.create!(:name=>lc(:compta_ss), :url=>'/guide/accountancy' , :company_id => self.id , :menu_id => menu.id)
   # sous_menu2 = menu_item1.children.create!(:name=>lc(:ventes_ss), :url=>'/guide/sales' , :company_id => self.id ,:menu_id => menu.id)
    menu = self.menus.create!(:name=>'guide' , :label=>'test label')
    menu_item1 = menu.menu_items.create!(:name=>'Accueil', :url=>'/guide' , :company_id => self.id)
    menu_item2 = menu.menu_items.create!(:name=>'Comptabilité', :url=>'/guide/accountancy', :company_id => self.id )
    menu_item3 = menu.menu_items.create!(:name=>'Ventes', :url=>'/guide/sales', :company_id => self.id )
    menu_item4 = menu.menu_items.create!(:name=>'Achats', :url=>'/guide/purchases', :company_id => self.id )
    menu_item5 = menu.menu_items.create!(:name=>'Stocks', :url=>'/guide/stocks', :company_id => self.id )
    menu2 = self.menus.create!(:name=>'user' , :label=>'test user label')
    menu_test_dynamic = menu2.menu_items.create!(:name=>'$company_name' , :url=>'/config/company', :dynamic => true, :company_id => self.id)
    menu_test_dynamic2 = menu2.menu_items.create!(:name=>'$user_label' , :url=>'/config/user', :dynamic => true, :company_id => self.id)
    menu_test_dynamic3 = menu2.menu_items.create!(:name=>'Quitter' , :url=>'/authentication/logout', :company_id => self.id)
    sous_menu11 = menu_item1.children.create!(:name=>'A propos', :url=>'/guide/about_us' , :company_id => self.id , :menu_id => menu.id)
    sous_menu1 = menu_item1.children.create!(:name=>'Quitter', :url=>'/authentication/logout' , :company_id => self.id , :menu_id => menu.id)
    sous_menu2 = menu_item2.children.create!(:name=>'Comptes', :url=>'/accountancy/accounts' , :company_id => self.id ,:menu_id => menu.id)
    sous_menu3 = menu_item2.children.create!(:name=>'Ecritures', :url=>'/accountancy/entries' , :company_id => self.id ,:menu_id => menu.id)
    sous_menu4 = menu_item2.children.create!(:name=>'Journaux', :url=>'/accountancy/journals' , :company_id => self.id ,:menu_id => menu.id)
    #sous_ss_menu = sous_menu1.children.create!(:name=>lc(:compta_sss), :url=>'/guide/accountancy' , :company_id => self.id , :menu_id => menu.id)
   # self.load_accounting_system
  end

  def menu(name)
    Menu.find(:first, :conditions => { :company_id => self.id , :name => name})

  end
  def parameter(name)
    parameter = Parameter.find_by_name_and_company_id(name,self.id)
    parameter = Parameter.new(:name=>name, :nature=>:u, :company_id=>self.id)
    parameter
  end

  def load_accounting_system
    for a in 1..8
      self.accounts.create!(:number=>a.to_s, :name=>l(:accounting_system, a.to_sym), :label=>l(:accounting_system, a.to_sym), :parent_id=>0)
    end
  end

  def load_template(filename)
    f = File.open(filename,'rb')
    Template.create!(:name=>filename.simpleize,:company_id=>self.id, :content=>f.read)
    f.close
  end

  def admin_role
    self.roles.find(:first, :conditions=>"actions=' all '")
  end

end
