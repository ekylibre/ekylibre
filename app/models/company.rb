# == Schema Information
# Schema version: 20090410102120
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
#  entity_id    :integer       
#

class Company < ActiveRecord::Base
  has_many :accounts
  has_many :account_balances
  has_many :address_norms
  has_many :address_norm_items
  has_many :bank_accounts
  has_many :bank_account_statements
  has_many :complements
  has_many :complement_choices
  has_many :complement_datas
  has_many :contacts
  has_many :currencies
  has_many :delays
  has_many :deliveries
  has_many :delivery_lines
  has_many :departments
  has_many :documents
  has_many :employees
  has_many :entities
  has_many :entity_natures
  has_many :entries
  has_many :establishments
  has_many :financialyears
  has_many :invoices
  has_many :invoice_lines
  has_many :journals
  has_many :journal_periods
  has_many :journal_records
  has_many :parameters
  has_many :payments
  has_many :payment_modes
  has_many :payment_parts
  has_many :prices
  has_many :products
  has_many :product_stocks
  has_many :professions
  has_many :purchase_orders
  has_many :purchase_order_lines
  has_many :roles
  has_many :sale_orders
  has_many :sale_order_lines
  has_many :sale_order_natures
  has_many :sequences
  has_many :shelves
  has_many :stock_locations
  has_many :stock_moves
  has_many :stock_trackings
  has_many :taxes
  has_many :templates
  has_many :units
  has_many :users

  #validates_presence_of :entity_id

  
  def before_validation
    self.code = name.to_s[0..7].simpleize if code.blank?
    self.code = rand.to_s[2..100].to_i.to_s(36)[0..7] if code.blank?
    self.code.upper!
    while Company.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
      self.code.succ!
    end
    self.siren = '000000000' if self.siren.blank?
  end

  def set_entity_id(id)
    self.entity_id = id
    self.save
    #raise Exception.new self.entity_id.inspect
  end

  def after_create
    role = Role.create!(:name=>tc('default.role.name.admin'), :company_id=>self.id,:actions=>'  ')
    role.can_do :all
    role = Role.create!(:name=>tc('default.role.name.public'), :company_id=>self.id,:actions=>'  ')
    self.parameter('general.language').value=Language.find_by_iso2('fr')
    self.load_template("#{RAILS_ROOT}/lib/template.xml")
    self.departments.create!(:name=>tc('default.department_name'))
    self.establishments.create!(:name=>tc('default.establishment_name'), :nic=>"00000")
    currency = self.currencies.create!(:name=>'Euro', :code=>'EUR', :format=>'%f €', :rate=>1)
    self.shelves.create(:name=>tc('default.shelf_name'))
    for unit in Unit.default_units
      self.units.create(:name=>unit[0].to_s, :label=>tc('default.unit_'+unit[0].to_s), :base=>unit[1][:base], :quantity=>unit[1][:quantity])
    end
    self.address_norms.create!(:name=>'Norme AFNOR ZX110', :company_id=> self.id)
    self.taxes.create!(:name=>tc('default.tva210'), :group_name=>'TVA', :nature=>'percent', :amount=>0.021)
    self.taxes.create!(:name=>tc('default.tva550'), :group_name=>'TVA', :nature=>'percent', :amount=>0.055)
    self.taxes.create!(:name=>tc('default.tva1960'), :group_name=>'TVA', :nature=>'percent', :amount=>0.196)
    self.entity_natures.create!(:name=>'Monsieur', :abbreviation=>'M', :physical=>true)
    self.entity_natures.create!(:name=>'Madame', :abbreviation=>'Mme', :physical=>true)
    self.entity_natures.create!(:name=>'Société Anonyme', :abbreviation=>'SA', :physical=>false)
    indefini = self.entity_natures.create!(:name=>'Indéfini',:abbreviation=>'-', :in_name=>false)
#    raise Exception.new self.entities.inspect
    #raise Exception.new [:nature_id=>indefini.id, :language_id=>1, :name=>self.name].inspect
    #self.entities
    firm = self.entities.create!(:nature_id=>indefini.id, :language_id=>1, :name=>self.name)
    #firm = self.entities.create( :name=>'toto')
    self.set_entity_id(firm.id)
    self.payment_modes.create!(:name=>tc('default.check'), :company_id=>self.id)
   # self.entity_id = firm.id
    #raise Exception.new self.inspect
    delays = []
    ['expiration', 'standard', 'immediate'].each do |d|
      delays << self.delays.create!(:name=>tc('default.delays.name.'+d), :expression=>tc('default.delays.expression.'+d), :active=>true)
    end
    self.sale_order_natures.create!(:name=>tc('default.sale_order_nature_name'), :expiration_id=>delays[0].id, :payment_delay_id=>delays[2].id, :downpayment=>false, :downpayment_minimum=>300, :downpayment_rate=>0.3)

    #tc('countries')
    
#    puts tc('accounting_system').to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}.collect{|a| a[0].to_s+'  ::  '+a[1].to_s}.join "\n"
    tc('mini_accounting_system').to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}.each do |a|
      puts a.inspect
      begin
        account = self.accounts.find_by_number(a[0].to_s)
        if account 
          account.update_attributes!(:name=>a[1])
        else
          self.accounts.create!(:number=>a[0].to_s, :name=>a[1])
        end
      rescue Exception
        
      end

    end
  end

  def parameter(name)
    parameter = Parameter.find_by_name_and_company_id(name,self.id)
    parameter = Parameter.new(:name=>name, :nature=>:u, :company_id=>self.id)
    parameter
  end

  def load_accounting_system
    t('models.company.accounting_system').each do |a|
      self.accounts.create!(:number=>a[0], :name=>a[1])
    end
#    for a in 1..8
#      self.accounts.create!(:number=>a.to_s, :name=>l(:accounting_system, a.to_sym), :label=>l(:accounting_system, a.to_sym), :parent_id=>0)
#    end
  end

  def load_template(filename)
    f = File.open(filename,'rb')
    Template.create!(:name=>filename.simpleize,:company_id=>self.id, :content=>f.read)
    f.close
  end

  def admin_role
    self.roles.find(:first, :conditions=>"actions ILIKE '%all%'")
  end

  def available_entities(options={})
#    options[:conditions]={:deleted=>false}
    self.entities.find(:all, options)
  end

  def available_products(options={})
    options[:conditions]={:active=>true}
    self.products.find(:all, options)
  end

  def available_taxes(options={})
#    options[:conditions]={:deleted=>false}
    self.taxes.find(:all, options)
  end

  def invoice(records, options={})
    Invoice.generate(self.id,records)
  end

  def current_financialyear
    self.financialyears.find(:last, :conditions => "closed = false", :order=>"started_on ASC")
  end

end
