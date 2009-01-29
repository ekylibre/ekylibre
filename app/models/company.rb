# == Schema Information
# Schema version: 20081111111111
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
    self.siren = '000000000' if self.siren.blank?
  end

  def after_create
    role = Role.create!(:name=>tc(:administrator), :company_id=>self.id)
    role.can_do :all
    role = Role.create!(:name=>tc(:public), :company_id=>self.id)
    self.parameter('general.language').value=Language.find_by_iso2('fr')
    self.load_template("#{RAILS_ROOT}/lib/template.xml")
    self.departments.create!(:name=>tc('default.department_name'))
    self.establishments.create!(:name=>tc('default.establishment_name'), :nic=>"00000")
    currency = self.currencies.create!(:name=>'Euro', :code=>'EUR', :format=>'%f €', :rate=>1)
    self.shelves.create(:name=>tc('default.shelf_name'))
    for unit in Unit.default_units
      self.units.create(:name=>unit[0].to_s, :label=>tc('default.unit_'+unit[0].to_s), :base=>unit[1][:base], :quantity=>unit[1][:quantity])
    end
    self.taxes.create(:name=>'TVA 19.6', :nature=>'percent')
    self.address_norms.create!(:name=>'Norme AFNOR ZX110', :company_id=> self.id)
    self.taxes.create!(:name=>tc('default.tva210'), :group_name=>'TVA', :nature=>'percent', :amount=>0.021)
    self.taxes.create!(:name=>tc('default.tva550'), :group_name=>'TVA', :nature=>'percent', :amount=>0.055)
    self.taxes.create!(:name=>tc('default.tva1960'), :group_name=>'TVA', :nature=>'percent', :amount=>0.196)
    self.price_lists.create!(:name=>tc('default.price_list_name'), :currency=>currency)
    entit = self.entity_natures.create!( :name=>'Monsieur' , :abbreviation=>'M', :company_id=> self.id)
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

  def available_entities(options={})
#    options[:conditions]={:deleted=>false}
    self.entities.find(:all, options)
  end

  def available_price_lists(options={})
    options[:conditions]={:deleted=>false}
    self.price_lists.find(:all, options)
  end

  def available_products(options={})
    options[:conditions]={:active=>true}
    self.products.find(:all, options)
  end

  def available_taxes(options={})
#    options[:conditions]={:deleted=>false}
    self.taxes.find(:all, options)
  end

end
