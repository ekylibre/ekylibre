# == Schema Information
#
# Table name: companies
#
#  id                  :integer       not null, primary key
#  name                :string(255)   not null
#  code                :string(8)     not null
#  born_on             :date          
#  locked              :boolean       not null
#  deleted             :boolean       not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  created_by          :integer       
#  updated_by          :integer       
#  lock_version        :integer       default(0), not null
#  entity_id           :integer       
#  invoice_sequence_id :integer       
#

class Company < ActiveRecord::Base
  has_many :accounts
  has_many :account_balances
  has_many :address_norms
  has_many :address_norm_items
  has_many :areas
  has_many :bank_accounts
  has_many :bank_account_statements
  has_many :complements
  has_many :complement_choices
  has_many :complement_data
  has_many :contacts
  has_many :currencies
  has_many :delays
  has_many :deliveries
  has_many :delivery_lines
  has_many :delivery_modes
  has_many :departments
  has_many :documents
  has_many :embankments
  has_many :employees
  has_many :entities
  has_many :entity_categories
  has_many :entity_natures
  has_many :entries
  has_many :establishments
  has_many :financialyears
  has_many :invoices
  has_many :invoice_lines
  has_many :journals
  has_many :journal_records
  has_many :languages
  has_many :meeting_locations
  has_many :meeting_modes
  has_many :meetings
  has_many :parameters
  has_many :payments
  has_many :payment_modes
  has_many :payment_parts
  has_many :prices
  has_many :price_taxes
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
  has_many :shapes
  has_many :shape_operation_natures
  has_many :shape_operations
  has_many :shelves
  has_many :stock_locations
  has_many :stock_moves
  has_many :stock_trackings
  has_many :stock_transfers
  has_many :taxes
  has_many :templates
  has_many :units
  has_many :users
  belongs_to :entity
  # belongs_to :sales_journal, :class_name=>Journal.to_s
  # belongs_to :purchases_journal, :class_name=>Journal.to_s
  # belongs_to :bank_journal, :class_name=>Journal.to_s

  
  def before_validation
    self.code = self.name.to_s[0..7].simpleize if self.code.blank?
    self.code = rand.to_s[2..100].to_i.to_s(36)[0..7] if self.code.blank?
    self.code.upper!
    while Company.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
      self.code.succ!
    end
    # self.siren = '000000000' if self.siren.blank?
  end

  def siren
    self.entity ? self.entity.siren : '000000000'
  end

  def after_create
    language = self.languages.create!(:name=>'Français', :native_name=>'Français', :iso2=>'fr', :iso3=>'fra')
    self.set_parameter('general.language', language)
    self.roles.create!(:name=>tc('default.role.name.admin'),  :rights=>User.rights_list.join(' '))
    self.roles.create!(:name=>tc('default.role.name.public'), :rights=>'')
    self.load_template("#{RAILS_ROOT}/lib/template.xml")
    self.departments.create!(:name=>tc('default.department_name'))
    self.establishments.create!(:name=>tc('default.establishment_name'), :nic=>"00000")
    currency = self.currencies.create!(:name=>'Euro', :code=>'EUR', :format=>'%f €', :rate=>1)
    self.shelves.create(:name=>tc('default.shelf_name'))
    for unit in Unit.default_units
      self.units.create(:name=>unit[0].to_s, :label=>tc('default.unit_'+unit[0].to_s), :base=>unit[1][:base], :quantity=>unit[1][:quantity])
    end
    self.address_norms.create!(:name=>'Norme AFNOR ZX110', :company_id=> self.id)
    self.taxes.create!(:name=>tc('default.tva000'), :nature=>'percent', :amount=>0.00)
    self.taxes.create!(:name=>tc('default.tva210'), :nature=>'percent', :amount=>0.021)
    self.taxes.create!(:name=>tc('default.tva550'), :nature=>'percent', :amount=>0.055)
    self.taxes.create!(:name=>tc('default.tva1960'),:nature=>'percent', :amount=>0.196)
    self.entity_natures.create!(:name=>'Monsieur', :abbreviation=>'M', :physical=>true)
    self.entity_natures.create!(:name=>'Madame', :abbreviation=>'Mme', :physical=>true)
    self.entity_natures.create!(:name=>'Société Anonyme', :abbreviation=>'SA', :physical=>false)
    undefined_nature = self.entity_natures.create!(:name=>'Indéfini',:abbreviation=>'-', :in_name=>false)
    firm = self.entities.create!(:nature_id=>undefined_nature.id, :language_id=>language, :name=>self.name)
    self.entity_id = firm.id
    self.save
    self.payment_modes.create!(:name=>tc('default.check'), :company_id=>self.id)
    delays = []
    ['expiration', 'standard', 'immediate'].each do |d|
      delays << self.delays.create!(:name=>tc('default.delays.name.'+d), :expression=>tc('default.delays.expression.'+d), :active=>true)
    end
    self.entity_categories.create!(:name=>tc('default.category'))
    self.financialyears.create!(:started_on=>Date.today)
    self.sale_order_natures.create!(:name=>tc('default.sale_order_nature_name'), :expiration_id=>delays[0].id, :payment_delay_id=>delays[2].id, :downpayment=>false, :downpayment_minimum=>300, :downpayment_rate=>0.3)

    self.set_parameter('accountancy.default_journals.sales', self.journals.create!(:name=>tc('default.journals.sales'), :nature=>"sale", :currency_id=>currency.id))
    self.set_parameter('accountancy.default_journals.purchases', self.journals.create!(:name=>tc('default.journals.purchases'), :nature=>"purchase", :currency_id=>currency.id))
    self.set_parameter('accountancy.default_journals.bank', self.journals.create!(:name=>tc('default.journals.bank'), :nature=>"bank", :currency_id=>currency.id))
    self.set_parameter('management.invoicing.numeration', self.sequences.create!(:name=>tc('default.invoicing_numeration'), :format=>'F[year][month|2][number|6]', :period=>'month'))
                       
    tc('mini_accounting_system').to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}.each do |a|
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
    parameter = self.parameters.find_by_name(name)
    #parameter = self.parameters.build(:name=>name) if parameter.nil?
    parameter
  end

  def set_parameter(name, value)
    parameter = self.parameters.find_by_name(name)
    parameter = self.parameters.build(:name=>name) if parameter.nil?
    parameter.value = value
    parameter.save
  end

  def load_template(filename)
    f = File.open(filename,'rb')
    Template.create!(:name=>filename.simpleize,:company_id=>self.id, :content=>f.read)
    f.close
  end

  def admin_role
    self.roles.find(:first)#, :conditions=>"actions LIKE '%all%'")
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

  def invoice(records)
    Invoice.generate(self.id,records)
  end

  def current_financialyear
    self.financialyears.find(:last, :conditions => "closed = false", :order=>"started_on ASC")
  end

  def productable_products
    Product.find_by_sql ["SELECT * FROM products WHERE company_id = ? AND (supply_method = 'produce' OR id IN (SELECT product_id FROM product_components WHERE company_id = ?))", self.id, self.id ]
  end

  def imported_entity_nature(row)
    if row.blank?
      nature = self.entity_natures.find_by_abbreviation("-")
    else
      nature = EntityNature.find(:first, :conditions=>['company_id = ? AND name ILIKE ? ',self.id, row])
      #raise Exception.new nature.empty?.inspect
      #raise Exception.new nature.inspect if row == "SCEA"
      nature = EntityNature.find(:first, :conditions=>['company_id = ? AND abbreviation ILIKE ?', self.id, row]) if nature.nil?
      nature = EntityNature.create!(:name=>row, :abbreviation=>row[0..1], :in_name=>false, :physical=>true, :company_id=>self.id) if nature.nil? 
    end
    nature.id
  end 

  def checks_to_embank_on_update(embankment)
    checks = []
    for payment in self.payments
      checks << payment if ((payment.mode.mode == "check") and (payment.mode_id == embankment.mode_id) and (payment.embankment_id.nil? or payment.embankment_id == embankment.id) ) 
    end
    checks
  end
  
  def checks_to_embank(mode_id)
    checks = []
    #raise Exception.new self.payments.inspect
    for payment in self.payments
      if mode_id == 0
        checks << payment if ((payment.mode.mode == "check") and payment.embankment_id.nil?)
      elsif mode_id == -1
        checks << payment if ((payment.mode.mode == "check") and (payment.embankment_id.nil?) and Date.today >= (payment.to_bank_on+(15)) )
      else
        checks << payment if ((payment.mode.mode == "check") and (payment.mode_id == mode_id) and payment.embankment_id.nil?)
      end
    end
    checks
  end
  
  def embankments_to_lock
    embankments = []
    for embankment in self.embankments
      embankments << embankment if embankment.locked == false and embankment.created_on <= Date.today-(15)
    end
    embankments
  end

  def default_contact
    self.entity.default_contact
  end

  def find_sales_journal
    if self.sales_journal_id.nil?
      journal_id = self.journals.find_by_nature("sale")
      journal_id = Journal.create!(:company_id=>self.id, :nature=>"sale", :currency_id=>self.currencies(:first), :name=>tc(:sales), :code=>"V", :closed_on=>Date.today+(365)) if journal_id.nil?
    else
      journal_id = self.sales_journal_id
    end
    journal_id
  end

end
