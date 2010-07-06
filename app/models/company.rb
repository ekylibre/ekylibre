# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: companies
#
#  born_on          :date             
#  code             :string(16)       not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  entity_id        :integer          
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  locked           :boolean          not null
#  name             :string(255)      not null
#  sales_conditions :text             
#  updated_at       :datetime         not null
#  updater_id       :integer          
#

class Company < ActiveRecord::Base
  has_many :accounts, :order=>:number
  has_many :account_balances
  has_many :areas
  has_many :cashes
  has_many :bank_statements
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
  has_many :districts
  has_many :documents
  has_many :document_templates
  has_many :embankments
  has_many :entities
  has_many :entity_categories
  has_many :entity_link_natures
  has_many :entity_links
  has_many :entity_natures  
  has_many :establishments
  has_many :event_natures
  has_many :events
  has_many :financialyears, :order=>"started_on DESC"
  has_many :inventories
  has_many :inventory_lines
  has_many :invoices
  has_many :invoice_lines
  has_many :journals, :order=>:name
  has_many :journal_entries
  has_many :journal_records
  has_many :listings
  has_many :listing_nodes
  has_many :listing_node_items
  has_many :locations
  has_many :mandates
  has_many :observations
  has_many :operation_natures
  has_many :operations
  has_many :operation_lines
  has_many :parameters
  has_many :prices
  has_many :products, :order=>'active DESC, name'
  has_many :product_components
  has_many :professions
  has_many :purchase_orders
  has_many :purchase_order_lines
  has_many :purchase_payments
  has_many :purchase_payment_modes, :order=>:name
  has_many :purchase_payment_parts
  has_many :roles
  has_many :sale_orders
  has_many :sale_order_lines
  has_many :sale_order_natures
  has_many :sale_payments
  has_many :sale_payment_modes, :order=>:name
  has_many :sale_payment_parts
  has_many :sequences
  has_many :shapes, :order=>:name
  has_many :shelves, :order=>:name
  has_many :stocks, :order=>"location_id, product_id, tracking_id"
  has_many :stock_moves
  has_many :stock_transfers
  has_many :subscription_natures, :order=>:name
  has_many :subscriptions
  has_many :taxes, :order=>'amount'
  has_many :tax_declarations
  has_many :tool_uses
  has_many :tools, :order=>:name
  has_many :trackings
  has_many :transfers
  has_many :units, :order=>'base, coefficient, name'
  has_many :users, :order=>'last_name, first_name'
  belongs_to :entity


  # Specifics
  has_many :attorney_accounts, :class_name=>Account.name, :order=>:number, :conditions=>'number LIKE #{connection.quote(parameter(\'accountancy.accounts.third_attorneys\').value.to_s+\'%\')}'
  has_many :available_prices, :class_name=>Price.name, :conditions=>'prices.entity_id=#{self.entity_id} AND prices.active=#{connection.quoted_true} AND product_id IN (SELECT id FROM products WHERE company_id=#{id} AND active=#{connection.quoted_true})', :order=>"prices.amount"
  has_many :available_products, :class_name=>Product.name, :conditions=>{:active=>true}, :order=>:name
  has_many :bank_journals, :class_name=>Journal.name, :order=>:code, :conditions=>'nature LIKE \'bank\''
  has_many :banks_accounts, :class_name=>Account.name, :order=>:number, :conditions=>'number LIKE #{connection.quote(parameter(\'accountancy.accounts.financial_banks\').value.to_s+\'%\')}'
  has_many :cash_journals, :class_name=>Journal.name, :order=>:code, :conditions=>'nature LIKE \'cash\''
  has_many :cashes_accounts, :class_name=>Account.name, :order=>:number, :conditions=>'number LIKE #{connection.quote(parameter(\'accountancy.accounts.financial_cashes\').value.to_s+\'%\')}'
  has_many :charges_accounts, :class_name=>Account.name, :order=>:number, :conditions=>'number LIKE #{connection.quote(parameter(\'accountancy.accounts.charges\').value.to_s+\'%\')}'
  has_many :choice_complements, :class_name=>Complement.name, :conditions=>{:nature=>"choice"}, :order=>"name"
  has_many :client_accounts, :class_name=>Account.name, :order=>:number, :conditions=>'number LIKE #{connection.quote(parameter(\'accountancy.accounts.third_clients\').value.to_s+\'%\')}'
  has_many :employees, :class_name=>User.name, :conditions=>{:employed=>true}, :order=>'last_name, first_name'
  has_many :embankable_payments, :class_name=>SalePayment.name, :conditions=>'embankment_id IS NULL AND mode_id IN (SELECT id FROM sale_payment_modes WHERE company_id=#{id} AND with_embankment)'
  has_many :major_accounts, :class_name=>Account.name, :conditions=>["number LIKE '_'"], :order=>"number"
  has_many :payments_to_embank, :class_name=>SalePayment.name, :order=>"created_on", :conditions=>'embankment_id IS NULL AND mode_id IN (SELECT id FROM sale_payment_modes WHERE company_id=#{id} AND with_embankment) AND to_bank_on >= CURRENT_DATE-14'
  has_many :payments_to_embank_accounts, :class_name=>Account.name, :order=>:number, :conditions=>'number LIKE #{connection.quote(parameter(\'accountancy.accounts.financial_payments_to_embank\').value.to_s+\'%\')}'
  has_many :productable_products, :class_name=>Product.name, :conditions=>{:to_produce=>true}
  has_many :products_accounts, :class_name=>Account.name, :order=>:number, :conditions=>'number LIKE #{connection.quote(parameter(\'accountancy.accounts.products\').value.to_s+\'%\')}'
  has_many :self_cashes, :class_name=>Cash.name, :order=>:name, :conditions=>'entity_id=#{self.entity_id}'
  has_many :self_bank_accounts, :class_name=>Cash.name, :order=>:name, :conditions=>'entity_id=#{self.entity_id} AND nature=\'bank_account\''
  has_many :self_contacts, :class_name=>Contact.name, :conditions=>'deleted_at IS NULL AND entity_id = #{self.entity_id}', :order=>'address'
  has_many :stockable_products, :class_name=>Product.name, :conditions=>{:manage_stocks=>true}
  has_many :supplier_accounts, :class_name=>Account.name, :order=>:number, :conditions=>'number LIKE #{connection.quote(parameter(\'accountancy.accounts.third_suppliers\').value.to_s+\'%\')}'
  has_many :suppliers, :class_name=>Entity.name, :conditions=>{:supplier=>true}, :order=>'active DESC, last_name, first_name'
  has_many :surface_units, :class_name=>Unit.name, :conditions=>{:base=>"m2"}, :order=>'coefficient, name'
  has_many :transporters, :class_name=>Entity.name, :conditions=>{:transporter=>true}, :order=>'active DESC, last_name, first_name'
  has_many :usable_purchase_payments, :class_name=>PurchasePayment.name, :conditions=>'parts_amount < amount', :order=>'amount'
  has_many :usable_sale_payments, :class_name=>SalePayment.name, :conditions=>'parts_amount < amount', :order=>'amount'

  has_one :current_financialyear, :class_name=>Financialyear.name, :conditions=>{:closed=>false}
  has_one :default_currency, :class_name=>Currency.name, :conditions=>{:active=>true}, :order=>"id"


  validates_uniqueness_of :code

  attr_readonly :code

  require "#{RAILS_ROOT}/lib/models" unless defined?(EKYLIBRE_MODELS)
  
  @@rhm = Company.reflections.collect{|r,v| v.name.to_s.singularize.to_sym if v.macro==:has_many}.compact
  @@ehm = EKYLIBRE_MODELS.delete_if{|x| x==:company}
  #  raise Exception.new("Models and has_many are not corresponding in Company !!!\nUnwanted: #{(@@rhm-@@ehm).inspect}\nMissing:  #{(@@ehm-@@rhm).inspect}\n") if @@rhm-@@ehm!=@@ehm-@@rhm

  def before_validation_on_create
    self.code = self.name.to_s[0..7].simpleize if self.code.blank?
    self.code = rand.to_s[2..-1].to_i.to_s(36)[0..7] if self.code.blank?
    self.code = self.code.simpleize.upper
    while Company.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
      self.code.succ!
    end
  end

  def self.models
    Object.subclasses_of(ActiveRecord::Base).collect{|x| x.name}
  end

  def siren
    self.entity ? self.entity.siren : '000000000'
  end

  def company_id
    self.id
  end

  def accountizing?
    if parameter = self.parameter('accountancy.accountize.automatic')
      return true if parameter.value == true
    end
    return false
  end

  def draft_mode?
    if parameter = self.parameter('accountancy.accountize.draft_mode')
      return true if parameter.value == true
    end
    return false
  end



  def account(number, name=nil)
    number = number.to_s
    a = self.accounts.find_by_number(number)
    return a||self.accounts.create!(:number=>number, :name=>name||number.to_s)
  end


  def parameter(name)
    parameter = self.parameters.find_by_name(name)
    if parameter.nil? and Parameter.reference.keys.include? name
      parameter = self.parameters.new(:name=>name)
      parameter.value = Parameter.reference[name][:default]
      parameter.save!
    end
    parameter
  end


  def set_parameter(name, value)
    parameter = self.parameters.find_by_name(name)
    parameter = self.parameters.build(:name=>name) if parameter.nil?
    parameter.value = value
    parameter.save
  end

  def admin_role
    self.roles.find(:first)#, :conditions=>"actions LIKE '%all%'")
  end

  def available_entities(options={})
    #    options[:conditions]={:deleted=>false}
    self.entities.find(:all, options)
  end

  def available_link_natures(options={})
    array = self.entity_link_natures.find_all_by_symmetric(false).collect{|x| [x.name_1_to_2, x.id]}
    array += self.entity_link_natures.find_all_by_symmetric(false).collect{|x| [x.name_2_to_1, x.id.to_s+"-R"]}
    array += self.entity_link_natures.find_all_by_symmetric(true).collect{|x| [x.name_1_to_2, x.id]}
    array.sort!{|a,b| a[0]<=>b[0] }
    #raise Exception.new array.inspect
    array
  end

#   def available_products(options={})
#     options[:conditions] ||= {}
#     options[:conditions].merge!(:active=>true)
#     options[:order] ||= 'name'
#     self.products.find(:all, options)
#   end

#   def available_prices(category_id=nil)
#     conditions = {"prices.entity_id"=>self.entity_id, "products.active"=>true, "prices.active"=>true}
#     conditions[:category_id] = category_id if category_id
#     self.prices.find(:all, :joins=>"JOIN products ON (products.id=product_id)", :conditions=>conditions, :order=>"products.name, prices.amount")
#   end

  def available_taxes(options={})
    #    options[:conditions]={:deleted=>false}
    self.taxes.find(:all, options)
  end


  def available_users(options={})
    self.users.find(:all, :order=>:last_name, :conditions=>{:locked=>false})
  end

  def invoice(records)
    puts records.inspect+"                          ddddddddddddddddddddddddd "
    Invoice.generate(self.id,records)
  end

  def closable_financialyear
    return self.financialyears.find(:all, :order=>"started_on").select{|y| y.closable?}[0]
  end

  def current_financialyear
    self.financialyears.find(:last, :conditions => "closed = false", :order=>"started_on ASC")
  end

  #   def productable_products
  #     #Product.find_by_sql ["SELECT * FROM products WHERE company_id = ? AND (supply_method = 'produce' OR id IN (SELECT product_id FROM product_components WHERE company_id = ?))", self.id, self.id ]
  #     Product.find_by_sql ["SELECT * FROM products WHERE company_id = ? AND (to_produce OR id IN (SELECT product_id FROM product_components WHERE company_id = ?))", self.id, self.id ]
  #   end

  def imported_entity_nature(row)
    if row.blank?
      nature = self.entity_natures.find_by_abbreviation("-")
    else
      nature = EntityNature.find(:first, :conditions=>['company_id = ? AND LOWER(name) LIKE ? ',self.id, row.lower])
      #raise Exception.new nature.empty?.inspect
      #raise Exception.new nature.inspect if row == "SCEA"
      nature = EntityNature.find(:first, :conditions=>['company_id = ? AND LOWER(abbreviation) LIKE ?', self.id, row.lower]) if nature.nil?
      nature = EntityNature.create!(:name=>row, :abbreviation=>row[0..1], :in_name=>false, :physical=>true, :company_id=>self.id) if nature.nil? 
    end
    nature.id
  end 

  def imported_entity_category(row)
    if row.blank?
      nature = self.entity_categories.first
    else
      nature = EntityCategory.find(:first, :conditions=>['company_id = ? AND LOWER(name) LIKE ? ',self.id, row.lower])
      nature = EntityCategory.create!(:name=>row, :by_default=>false, :company_id=>self.id) if nature.nil? 
    end
    nature.id
  end 


  def reflection_options(options={})
    raise ArgumentError.new("Need :reflection option (#{options.inspect})") unless options[:reflection].to_s.size > 0
    reflection = self.class.reflections[options[:reflection].to_sym]
    raise ArgumentError.new("Unknown :reflection option with an existing reflection (#{options[:reflection].inspect})") unless reflection
    model = reflection.class_name.constantize
    available_methods = model.instance_methods+model.columns_hash.keys
    unless label = options[:label]
      label = [:label, :native_name, :name, :code, :inspect].detect{|x| available_methods.include?(x.to_s)}
      raise ArgumentError.new(":label option is needed (#{options.inspect})") if label.nil?
    end
    find_options = {} # :conditions=>"true"}
    if options[:order]
      find_options[:order] = options[:order] 
    elsif model.columns_hash.keys.include?(options[:label].to_s)
      find_options[:order] = options[:label]
    end
    list = (self.send(reflection.name).find(:all, find_options)||[]).collect do |record|
      [record.send(label), record.id]
    end
    if options[:include_blank].is_a? String
      list.insert(0, [options[:include_blank], '']) 
    elsif options[:include_blank].is_a? Array
      list.insert(0, *options[:include_blank])
    end
    return list
  end


  def embankments_to_lock
    embankments = []
    for embankment in self.embankments
      embankments << embankment if ( embankment.locked == false and embankment.created_on <= Date.today-(15) )
    end
    embankments
  end

  def default_contact
    self.entity.default_contact
  end

  # Returns the default journal from parameters
  # Creates the journal if not exists
  def journal(name)
    name = name.to_s
    param_name  = "accountancy.journals.#{name}"
    raise Exception.new("Unvalid journal name : #{name.inspect}") unless Parameter.reference.keys.include? param_name
    param = self.parameter(param_name)
    if (journal = param.value).nil?
      journal = self.journals.find_by_nature(name)
      journal = self.journals.create!(:name=>tc("default.journals.#{name}"), :nature=>name, :currency_id=>self.default_currency.id) unless journal
      param.value = journal
      param.save
    end
    return param.value
  end


  # Compute a balance with many options
  #  - :started_on Use journal record printed on after started_on
  #  - :stopped_on Use journal record printed on before stopped_on
  #  - :draft      Use draft journal entries
  #  - :confirmed  Use confirmed journal entries
  #  - :closed     Use closed journal entries
  #  - :accounts   Select ranges of accounts
  #  - :centralize Select account's prefixe which permits to centralize
  def balance(options={})
    conn = ActiveRecord::Base.connection
    entries_states  = " AND (false"
    entries_states += " OR (journal_entries.draft = #{conn.quoted_true})" if options[:draft] == "1"
    entries_states += " OR (journal_entries.draft = #{conn.quoted_false} AND journal_entries.closed = #{conn.quoted_false})" if options[:confirmed] == "1"
    entries_states += " OR (journal_entries.closed = #{conn.quoted_true})" if options[:closed] == "1"
    entries_states += ")"

    valid_expr = /^\d(\d(\d[0-9A-Z]*)?)?$/    
    accounts = " AND (false"
    if options[:accounts]
      expression = ""
      for expr in options[:accounts].split(/[^0-9A-Z\-\*]+/)
        if expr.match(/\-/)
          start, finish = expr.split(/\-+/)[0..1]
          next unless start < finish and start.match(valid_expr) and finish.match(valid_expr)
          max = [start.length, finish.length].max
          accounts += " OR SUBSTR(accounts.number, 1, #{max}) BETWEEN #{conn.quote(start.ljust(max, '0'))} AND #{conn.quote(finish.ljust(max, 'Z'))}"
          expression += " #{start}-#{finish}"
        else
          next unless expr.match(valid_expr)
          accounts += " OR accounts.number LIKE #{conn.quote(expr+'%')}"
          expression += " #{expr}"
        end
      end
      options[:accounts] = expression.strip
    end
    accounts += ")"

    # raise Exception.new(options[:centralize].to_s.strip.split(/[^A-Z0-9]+/).inspect)
    centralize = options[:centralize].to_s.strip.split(/[^A-Z0-9]+/) # .delete_if{|x| x.blank? or !expr.match(valid_expr)}
    options[:centralize] = centralize.join(" ")
    # centralized = "("+centralized.collect{|c| "SUBSTR(accounts.number, 1, #{c.length}) = #{conn.quote(c)}"}.join(" OR ")+")"
    centralized = "("+centralize.collect{|c| "accounts.number LIKE #{conn.quote(c+'%')}"}.join(" OR ")+")"

    from_where  = " FROM journal_entries JOIN accounts ON (account_id=accounts.id) JOIN journal_records ON (record_id=journal_records.id)"
    from_where += " WHERE printed_on BETWEEN #{conn.quote(options[:started_on].to_date)} AND #{conn.quote(options[:stopped_on].to_date)}"
    # Total
    lines = []
    query  = "SELECT '', -1, sum(COALESCE(journal_entries.debit, 0)), sum(COALESCE(journal_entries.credit, 0)), sum(COALESCE(journal_entries.debit, 0)) - sum(COALESCE(journal_entries.credit, 0)), '#{'Z'*16}' AS skey"
    query += from_where
    query += entries_states
    query += accounts
    lines += conn.select_rows(query)

    # Sub-totals
    for name, value in options.select{|k, v| k.to_s.match(/^level_\d+$/) and v.to_i == 1}
      level = name.split(/\_/)[-1].to_i
      query  = "SELECT SUBSTR(accounts.number, 1, #{level}) AS subtotal, -2, sum(COALESCE(journal_entries.debit, 0)), sum(COALESCE(journal_entries.credit, 0)), sum(COALESCE(journal_entries.debit, 0)) - sum(COALESCE(journal_entries.credit, 0)), SUBSTR(accounts.number, 1, #{level})||'#{'Z'*(16-level)}' AS skey"
      query += from_where
      query += entries_states
      query += accounts
      query += " AND LENGTH(accounts.number) >= #{level}"
      query += " GROUP BY subtotal"
      lines += conn.select_rows(query)
    end

    # NOT centralized accounts (default)
    query  = "SELECT accounts.number, accounts.id AS account_id, sum(COALESCE(journal_entries.debit, 0)), sum(COALESCE(journal_entries.credit, 0)), sum(COALESCE(journal_entries.debit, 0)) - sum(COALESCE(journal_entries.credit, 0)), accounts.number AS skey"
    query += from_where
    query += entries_states
    query += accounts
    query += " AND NOT #{centralized}" unless centralize.empty?
    query += " GROUP BY accounts.id, accounts.number"
    query += " ORDER BY accounts.number"
    lines += conn.select_rows(query)

    # Centralized accounts
    for prefix in centralize
      query  = "SELECT SUBSTR(accounts.number, 1, #{prefix.size}) AS centralize, -3, sum(COALESCE(journal_entries.debit, 0)), sum(COALESCE(journal_entries.credit, 0)), sum(COALESCE(journal_entries.debit, 0)) - sum(COALESCE(journal_entries.credit, 0)), #{conn.quote(prefix)} AS skey"
      query += from_where
      query += entries_states
      query += accounts
      query += " AND accounts.number LIKE #{conn.quote(prefix+'%')}"
      query += " GROUP BY centralize"
      lines += conn.select_rows(query)
    end

    return lines.sort{|a,b| a[5]<=>b[5]}
  end


  def backup(options={})
    creator, with_prints = options[:creator], options[:with_prints]
    version = (ActiveRecord::Migrator.current_version rescue 0)
    filename = "backup-"+self.code.lower+"-"+Time.now.strftime("%Y%m%d-%H%M%S")
    file = "#{RAILS_ROOT}/tmp/#{filename}.zip"
    doc = LibXML::XML::Document.new
    doc.root = backup = XML::Node.new('backup')
    {'version'=>version, 'creation-date'=>Date.today, 'creator'=>creator}.each{|k,v| backup[k]=v.to_s}
    backup << root = XML::Node.new('company')
    self.attributes.each{|k,v| root[k] = v.to_s}
    n = 0
    start = Time.now.to_i
    models = EKYLIBRE_MODELS.delete_if{|x| x==:company}
    for model in models
      rows = model.to_s.classify.constantize.find(:all, :conditions=>{:company_id=>self.id}, :order=>:id)
      rows_count = rows.size
      n += rows_count
      root << table = XML::Node.new('rows')
      {'model'=>model.to_s, 'records-count'=>rows_count.to_s}.each{|k,v| table[k]=v}
      rows_count.times do |i|
        table << row = XML::Node.new('row')
        rows[i].attributes.each{|k,v| row[k] = v.to_s}
      end
    end
    # backup.add_attributes('records-count'=>n.to_s, 'generation-duration'=>(Time.now.to_i-start).to_s)
    stream = doc.to_s

    Zip::ZipFile.open(file, Zip::ZipFile::CREATE) do |zile|
      zile.get_output_stream("backup.xml") { |f| f.puts(stream) }
      prints_dir = "#{RAILS_ROOT}/private/#{self.code}"
      if with_prints and File.exist?(prints_dir)
        Dir.chdir(prints_dir) do
          for document in Dir["*/*/*.pdf"]
            zile.add("prints/"+document, prints_dir+'/'+document)
          end
        end
      end
    end
    return file
  end


  # Restore backup with archived documents if requested
  # This system requires a database with no foreign key constraints
  # Steps of restoring
  #   - Removes all existing data
  #   - Add all backup records with bad IDs
  #   - Update all records with new ID using a big hash containing all the new IDs
  #   - Put in place the archived documents if present in backup
  def restore(file, options={})
    raise ArgumentError.new("Expecting String, #{file.class.name} instead") unless file.is_a? String
    verbose = options[:verbose]
    prints_dir = "#{RAILS_ROOT}/private/#{self.code}"
    # Décompression
    puts "R> Uncompressing backup..." if verbose
    backup = "#{RAILS_ROOT}/tmp/uncompressed-backup-"+self.code.lower+"-"+Time.now.strftime("%Y%m%d-%H%M%S")+".xml"
    stream = nil
    FileUtils.rm_rf(prints_dir+'.prints')
    Zip::ZipFile.open(file) do |zile|
      stream = zile.read("backup.xml")
      # zile.extract("backup.xml", backup)
      # File.open(file, 'wb') {|f| f.write(zile.read("backup.xml"))}
      zile.each do |entry|
        if entry.name.match(/^prints[\\\/]/)
          File.makedirs(File.join(prints_dir+"."+File.join(entry.name.split(/[\\\/]+/)[0..-2])))
          zile.extract(entry, "#{prints_dir}.#{entry.name}") 
        end
      end
    end
    File.open(backup, 'wb') {|f| f.write(stream)}
    
    # Parsing
    version = (ActiveRecord::Migrator.current_version rescue 0)
    puts "R> Parsing backup.xml (#{version})..."  if verbose
    doc = LibXML::XML::Document.file(backup)
    backup = doc.root
    attr_version = backup.attributes['version']
    return false if not attr_version or (attr_version != version.to_s)

    root = backup.children[1]
    ActiveRecord::Base.transaction do
      # Suppression des données
      puts "R> Removing existing data..."  if verbose
      ids  = {}
      models = EKYLIBRE_MODELS # .delete_if{|x| x==:company}
      for model in models
        other_class = model.to_s.classify.constantize
        other_class.delete_all(:company_id=>self.id) if other_class != self.class
      end


      # Chargement des données sauvegardées
      puts "R> Loading backup data..."  if verbose
      data = {}
      keys = {}
      children = root.children
      elements = []
      children.size.times{|i| elements << {:index=>i, :attributes=>children[i].attributes} if children[i].element? }
      code = ''
      timed = false
      for element in elements
        model_name = nil
        if element[:attributes]['reflection']
          model_name = element[:attributes]['reflection'].singularize.to_sym
        elsif EKYLIBRE_MODELS.include? element[:attributes]['model'].to_sym
          model_name = element[:attributes]['model'].to_sym
        else
          raise Exception.new("Unknown model #{element.inspect}")
        end
        model = model_name.to_s.classify.constantize
        keys[model.name] = EKYLIBRE_REFERENCES[model_name].select{|k,v| v != :company}.to_a
        code += "puts('R> - #{model.name} (#{element[:attributes]['records-count']})')\n"  if verbose
        code += "start, tdb1, tdb2p = Time.now, 0, 0\n" if timed
        code += "data['#{model.name}'] = []\n"
        code += "ids['#{model.name}'] = {}\n"
        code += "children[#{element[:index]}].each_element do |r|\n"
        code += "  attributes = r.attributes.to_h\n"
        code += "  id = attributes['id']\n"
        code += "  dstart = Time.now\n" if timed

        code += "  record = #{model.name}.new(:company_id=>#{self.id})\n"
        model.columns_hash.keys.delete_if{|k| k=='id' or k=='company_id'}.each do |attr|
          code += "  record.#{attr} = attributes['#{attr}']\n"
        end

        code += "  tdb1 += Time.now-dstart\n" if timed
        code += "  record.send(:create_without_callbacks)\n"
        code += "  tdb2p += Time.now-dstart\n" if timed
        code += "  ids['#{model.name}'][id] = record.id\n"
        # Load initial value of the keys to be renamed easily after.
        code += "  data['#{model.name}'] << [record.id, #{keys[model.name].collect{|key, target| target.is_a?(Symbol) ? 'record.'+key.to_s : '[record.'+target.to_s+', record.'+key.to_s+']'}.join(', ')}]\n"
        code += "end\n"
        if element[:attributes]['records-count'].to_i>30 and timed
          code += "duration, tdb2 = Time.now-start, tdb2p-tdb1\n"
          code += "duration = Time.now-start\n"
          code += "puts 'R>     T: '+duration.to_s[0..6]+' | TDB1: '+tdb1.to_s[0..6]+' | TDB2: '+tdb2.to_s[0..6]+' | RS: '+(duration-tdb2p).to_s[0..6]+' | AVG(TDB1): '+(tdb1/#{element[:attributes]['records-count']}).to_s[0..6]+' | AVG(TDB2): '+(tdb2/#{element[:attributes]['records-count']}).to_s[0..6]\n"  if verbose
        end
      end
      File.open("#{RAILS_ROOT}/tmp/restore-1.rb", "wb") {|f| f.write(code)}  if verbose
      eval(code)
      
      # raise Exception.new(data.inspect)
      # Réorganisation des clés étrangères
      puts "R> Redifining primary keys..."  if verbose
      code  = ''

      for model_name in EKYLIBRE_MODELS
        model = model_name.to_s.classify.constantize

        new_ids = "'"
        for i in 1..keys[model.name].size
          reference = keys[model.name][i-1]
          target = reference[1]
          new_ids += (i>1 ? "+', " : "")+"#{reference[0]}='+"
          if target.is_a? String # Polymorphic
            new_ids += "((ids[record[#{i}][0]] ? (ids[record[#{i}][0]][record[#{i}][1].to_s]) : nil)||record[#{i}][1]||'NULL').to_s"
          else # Classic reference
            new_ids += "((ids['#{target.to_s.classify}'][record[#{i}].to_s])||record[#{i}]||'NULL').to_s"
          end
        end
        code += "for record in data['#{model.name}']\n"
        code += "  #{model.name}.update_all(#{new_ids}, 'company_id=#{self.id} AND id='+record[0].to_s)\n"
        code += "end\n"
      end

      File.open("#{RAILS_ROOT}/tmp/restore-2.rb", "wb") {|f| f.write(code)} if verbose
      start = Time.now
      eval(code)
      puts "R> Total: #{(Time.now-start)}s" if verbose



      # Chargement des paramètres de la société
      puts "R> Loading company data..." if verbose
      attrs = root.attributes.each do |attr|
        self.send(attr.name+'=', attr.value) unless ['id', 'lock_version', 'code'].include? attr.name
      end
      for key, target in EKYLIBRE_REFERENCES[self.class.name.underscore.to_sym]
        v = ids[target.to_s.classify][self[key].to_s]
        self[key] = v unless v.nil?
      end
      self.send(:update_without_callbacks)
      self.reload
      # raise Active::Record::Rollback

      if File.exist?(prints_dir+".prints")
        puts "R> Replacing prints..." if verbose
        File.move prints_dir, prints_dir+'.old'
        File.move prints_dir+'.prints', prints_dir
        FileUtils.rm_rf(prints_dir+'.old')
      end
    end


    return true
  end


  # Search a document template and use it to compile document using parameters
  # options[:id] permits to identify the template 
  def print(options={})
    id = options.delete(:id)
    template = if id.is_a? DocumentTemplate
                 id
               elsif id.is_a? Integer
                 self.document_templates.find_by_id(id)
               elsif id.is_a? String or id.is_a? Symbol
                 self.document_templates.find_by_code(id.to_s) || self.document_templates.find_by_nature_and_by_default(id.to_s, true)
               end
    raise Exception.new(tc(:cant_find_document_template)) unless template
    return template.print!(options)
  end










  def self.create_with_data(company_attr=nil, user_attr=nil, demo_language_code=nil)
    company = Company.new(company_attr)
    user = User.new(user_attr)

    ActiveRecord::Base.transaction do
      company.save!
      language = 'fra'
      company.roles.create!(:name=>tc('default.role.name.admin'),  :rights=>User.rights_list.join(' '))
      company.roles.create!(:name=>tc('default.role.name.public'), :rights=>'')
      user.company_id = company.id
      user.role_id = company.admin_role.id
      user.save!
      tc('mini_accounting_system').to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}.each do |num, name|
        raise Exception.new("Shiiiitt (#{[num, name].inspect})") unless num.to_s.match(/^n_/) or num.to_s == "name"
        if num.to_s.match(/^n_/)
          number = num.to_s[2..-1]
          if account = company.accounts.find_by_number(number)
            account.update_attributes!(:name=>name)
          else
            company.accounts.create!(:number=>number, :name=>name)
          end
        end
      end

      company.set_parameter('general.language', language)
      company.departments.create!(:name=>tc('default.department_name'))
      establishment = company.establishments.create!(:name=>tc('default.establishment_name'), :nic=>"00000")
      currency = company.currencies.create!(:name=>'Euro', :code=>'EUR', :format=>'%f €', :rate=>1)
      company.shelves.create(:name=>tc('default.shelf_name'))
      company.load_units
      company.load_sequences

      user.reload
      user.attributes = {:employed=>true, :commercial=>true, :department_id=>company.departments.first.id, :establishment_id=>company.establishments.first.id, :employment=>'-'}
      user.save!
      
      for code, tax in tc("default.taxes")
        company.taxes.create!(:name=>tax[:name], :nature=>(tax[:nature]||"percent"), :amount=>tax[:amount].to_f, :account_collected_id=>company.account(tax[:collected], tax[:name]).id, :account_paid_id=>company.account(tax[:paid], tax[:name]).id)
      end
      
      company.entity_natures.create!(:name=>'Monsieur', :title=>'M', :physical=>true)
      company.entity_natures.create!(:name=>'Madame', :title=>'Mme', :physical=>true)
      company.entity_natures.create!(:name=>'Société Anonyme', :title=>'SA', :physical=>false)
      undefined_nature = company.entity_natures.create!(:name=>'Indéfini', :title=>'', :in_name=>false, :physical=>false)
      category = company.entity_categories.create!(:name=>tc('default.category'))
      firm = company.entities.create!(:category_id=> category.id, :nature_id=>undefined_nature.id, :language=>language, :last_name=>company.name)
      company.reload
      company.entity_id = firm.id
      company.save!
      company.entity.contacts.create!(:company_id=>company.id, :line_2=>"", :line_3=>"", :line_5=>"", :line_6=>'12345 MAVILLE', :by_default=>true)
      
      # loading of all the templates
      company.load_prints

      for journal in [:sales, :purchases, :bank, :various, :cash]
        company.set_parameter("accountancy.journals.#{journal}", company.journals.create!(:name=>tc("default.journals.#{journal}"), :nature=>journal.to_s, :currency_id=>currency.id))
      end
      
      cash = company.cashes.create!(:name=>tc('default.cash.name.cash_box'), :company_id=>company.id, :nature=>"cash_box", :account=>company.account("531101", "Caisse"), :journal_id=>company.journal(:cash))
      baac = company.cashes.create!(:name=>tc('default.cash.name.bank_account'), :company_id=>company.id, :nature=>"bank_account", :account=>company.account("512101", "Compte bancaire"), :journal_id=>company.journal(:bank), :iban=>"FR7611111222223333333333391", :mode=>"iban")
      company.sale_payment_modes.create!(:name=>tc('default.sale_payment_modes.cash.name'), :company_id=>company.id, :cash_id=>cash.id, :with_accounting=>true)
      company.sale_payment_modes.create!(:name=>tc('default.sale_payment_modes.check.name'), :company_id=>company.id, :cash_id=>baac.id, :with_accounting=>true, :with_embankment=>true, :embankables_account_id=>company.account("5112", "Chèques à encaisser").id)
      company.sale_payment_modes.create!(:name=>tc('default.sale_payment_modes.transfer.name'), :company_id=>company.id, :cash_id=>baac.id, :with_accounting=>true)

      company.purchase_payment_modes.create!(:name=>tc('default.purchase_payment_modes.cash.name'), :company_id=>company.id, :cash_id=>cash.id, :with_accounting=>true)
      company.purchase_payment_modes.create!(:name=>tc('default.purchase_payment_modes.check.name'), :company_id=>company.id, :cash_id=>baac.id, :with_accounting=>true)
      company.purchase_payment_modes.create!(:name=>tc('default.purchase_payment_modes.transfer.name'), :company_id=>company.id, :cash_id=>baac.id, :with_accounting=>true)

      delays = []
      ['expiration', 'standard', 'immediate'].each do |d|
        delays << company.delays.create!(:name=>tc('default.delays.name.'+d), :expression=>tc('default.delays.expression.'+d), :active=>true)
      end
      company.financialyears.create!(:started_on=>Date.today)
      company.sale_order_natures.create!(:name=>tc('default.sale_order_nature_name'), :expiration_id=>delays[0].id, :payment_delay_id=>delays[2].id, :downpayment=>false, :downpayment_minimum=>300, :downpayment_rate=>0.3)
      

      company.load_sequences
      
      company.locations.create!(:name=>tc('default.location'), :account_id=>company.accounts.find(:first, :conditions=>["LOWER(number) LIKE ?", '3%' ], :order=>:number).id, :establishment_id=>establishment.id)
      company.event_natures.create!(:duration=>10, :usage=>"sale_order", :name=>tc(:sale_order_creation))
      company.event_natures.create!(:duration=>10, :usage=>"invoice", :name=>tc(:invoice_creation))
      company.event_natures.create!(:duration=>10, :usage=>"purchase_order", :name=>tc(:purchase_order_creation))
      
      # Add complementary data to test
      company.load_demo_data unless demo_language_code.blank?
    end
    return company, user
  end
  







  # this method loads all the templates existing.
  def load_prints
    language = self.entity.language
    prints_dir = "#{RAILS_ROOT}/config/locales/#{::I18n.locale}/prints"
    for family, templates in ::I18n.translate('models.company.default.document_templates')
      for template, attributes in templates
        #begin
        File.open("#{prints_dir}/#{template}.xml", 'rb') do |f|
          attributes[:name] ||= I18n::t('models.document_template.natures.'+template.to_s)
          attributes[:name] = attributes[:name].to_s
          attributes[:nature] ||= template.to_s
          attributes[:filename] ||= "File"
          attributes[:to_archive] = true if attributes[:to_archive] == "true"
          code = attributes[:name].to_s.codeize[0..7]
          if doc = self.document_templates.find_by_code(code)
            doc.destroy
          end
          self.document_templates.create!({:active=>true, :language=>language, :country=>'fr', :source=>f.read, :family=>family.to_s, :code=>code, :by_default=>false}.merge(attributes))
        end
        #rescue
        #end
      end
    end
  end

  def load_units
    for name, desc in Unit.default_units
      unit = self.units.find_by_base_and_coefficient_and_start(desc[:base], desc[:coefficient], desc[:start])
      unless unit
        self.units.create(:name=>name.to_s, :label=>tc('default.units.'+name.to_s), :base=>desc[:base], :coefficient=>desc[:coefficient], :start=>desc[:start])
      end
    end
  end

  def load_sequences
    for part, sequences in tc('default.sequences')
      for sequence, attributes in sequences
        if self.parameter("#{part}.#{sequence}.numeration").value.nil?
          seq = self.sequences.create(attributes)
          self.set_parameter("#{part}.#{sequence}.numeration", seq) if seq
        end
      end
    end
  end
  

#   def self.load_demo_data(locale="fr-FR", company=nil)
#     company.load_demo_data(company) if company
#   end
  
  def load_demo_data(language_code=nil)
    self.entity_natures.create!(:name=>"Société A Responsabilité Limitée", :title=>"SARL", :in_name=>true)
    last_name = ["MARTIN", "DUPONT", "DURAND", "LABAT", "VILLENEUVE", "SICARD", "FRERET", "FOUCAULT", "DUPEYRON", "BORGÈS", "DUBOIS", "LEROY", "MOREL", "GUERIN", "MORIN", "ROUSSEAU", "LEMAIRE", "DUVAL", "BRUN", "FERNANDEZ", "BRETON", "LEBLANC", "DA SILVA", "CORDIER", "BRIAND", "CAMUS", "VOISIN", "LELIEVRE", "GONZALEZ"]
    first_name = ["Benoît", "Stéphane", "Marine", "Roger", "Céline", "Bertrand", "Camille", "Dominique", "Julie", "Kévin", "Maxime", "Vincent", "Claire", "Marie-France", "Jean-Marie", "Anne-Marie", "Dominique", "Hakim", "Alain", "Daniel", "Sylvie", "Fabrice", "Nathalie", "Véronique", "Jeanine", "Edouard", "Colette", "Sébastien", "Rémi", "Joseph", "Baptiste", "Manuel", "Sofia", "Indira", "Martine", "Guy"]
    streets = ["Cours Xavier Arnozan", "Cours du général de Gaulle", "Route pavée", "Avenue Thiers", "Rue Gambetta", "5th Avenue", "rue Louis La Brocante", "Rue Léon Blum", "Avenue des Champs Élysées", "Cours de la marne"]
    cities = ["33000 Bordeaux", "33170 Gradignan", "40600 Biscarosse", "33400 Talence", "75001 Paris", "13000 Marseille", "33600 Pessac", "47000 Agen", "33710 Pugnac", "33700 Mérignac", "40000 Mont de Marsan"]
    entity_natures = self.entity_natures.collect{|x| x.id.to_s}
    indifferent_attributes = {:category_id=>self.entity_categories.first.id, :language=>self.entity.language}
    products = ["Salades","Bouteille en verre 75 cl","Bouchon liège","Capsule CRD", "Capsule", "Étiquette", "Vin Quillet-Bont 2005", "Caisse Bois 6 btles", "Bouteille Quillet-Bont 2005 75 cl", "Caisse 6 b. Quillet-Bont 2005", "patates", "Séjour 1 nuit", "Séjour 1 semaine 1/2 pension", "Fongicide", "Insecticide"]
    shelf_id = self.shelves.first.id
    category_id = self.entity_categories.first.id
    
    for x in 0..60
      entity = self.entities.new(indifferent_attributes)
      entity.nature_id = entity_natures[rand(entity_natures.size).to_i]
      entity.last_name = last_name[rand(last_name.size)]
      entity.last_name = entity.nature.title.to_s+" "+entity.last_name if entity.nature.in_name 
      entity.first_name = first_name[rand(first_name.size)] if entity.nature.physical
      entity.client = (rand() > 0.5 or rand() > 0.8)
      entity.supplier = (rand() > 0.75 or x == 0)
      entity.transporter = rand() > 0.9
      entity.save! 
      contact = entity.contacts.create!(:company_id=>self.id, :line_4=>rand(100).to_s+" "+streets[rand(streets.size)], :line_6=>cities[rand(cities.size)], :by_default=>true)
    end
    self.entity_link_natures.create!(:name=>"Gérant - Société", :name_1_to_2=>"gère la société", :name_2_to_1=>"est une société qui a pour associé", :propagate_contacts=>true, :symmetric=>false)
    self.subscription_natures.create!(:name=>"Abonnement annuel", :nature=>"period", :reduction_rate=>0.1)
    self.event_natures.create!(:name=>"Conversation téléphonique", :duration=>10, :usage=>"manual")
    
    # charge_account  = self.accounts.find_by_number("60")
    product_account = self.accounts.find_by_number("7")
    units = self.units.find(:all, :conditions=>"base IS NULL OR base in ('', 'kg', 'm3')")
    for product_name in products
      product = self.products.create!(:nature=>"product", :name=>product_name, :for_sales=>true, :for_productions=>true, :shelf_id=>shelf_id, :unit_id=>units.rand.id, :manage_stocks=>true, :weight=>rand(3), :sales_account_id=>product_account.id)
      product.reload
      product.prices.create!(:amount=>rand(100), :company_id=>self.id, :use_range=>false, :tax_id=>self.taxes.rand.id, :category_id=>category_id, :entity_id=>product.name.include?("icide") ? self.entities.find(:first, :conditions=>{:supplier=>true}).id : self.entity_id)
    end
    
    product = self.products.find_by_name("Caisse 6 b. Quillet-Bont 2005")
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Bouteille Quillet-Bont 2005 75 cl").id, :quantity=>6, :location_id=>self.locations.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Caisse Bois 6 btles").id, :quantity=>1, :location_id=>self.locations.first.id)

    product = self.products.find_by_name("Bouteille Quillet-Bont 2005 75 cl")
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Bouchon liège").id, :quantity=>1, :location_id=>self.locations.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Étiquette").id, :quantity=>1, :location_id=>self.locations.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Bouteille en verre 75 cl").id, :quantity=>1, :location_id=>self.locations.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Vin Quillet-Bont 2005").id, :quantity=>0.75, :location_id=>self.locations.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Capsule CRD").id, :quantity=>1, :location_id=>self.locations.first.id)
    
    self.subscriptions.create!(:nature_id=>self.subscription_natures.first.id, :started_on=>Date.today, :stopped_on=>Date.today+(365), :entity_id=>self.entities.find(:first, :conditions=>{:client=>true}).id, :suspended=>false)
    
    product = self.products.find_by_name("Vin Quillet-Bont 2005")
    self.locations.create!(:name=>"Cuve Jupiter", :product_id=>product.id, :quantity_max=>1000, :number=>1, :reservoir=>true, :account_id=>self.accounts.find(:first, :conditions=>["LOWER(number) LIKE ?", '3%' ], :order=>:number).id, :establishment_id=>self.establishments.first.id)


    units = self.units.find(:all, :conditions=>{:base =>'m2'})
    for shape in ["Milou", "Rantanplan", "Idéfix", "Cubitus", "Snoopy"]
      self.shapes.create!(:name=>shape, :area_measure=>rand(1000)+10, :area_unit_id=>units.rand.id)
    end
    for nature in ["Palissage", "Récolte", "Traitements", "Labour", "Vendange", "Épandange", "Éclaircissage"]
      self.operation_natures.create!(:name=>nature, :target_type=>"Shape")
    end
    for nature in ["Fabrication", "Transformation", "Ouillage"]
      self.operation_natures.create!(:name=>nature, :target_type=>"Stock")
    end
    for tool in ["Tracteur MF", "Renault 50"]
      self.tools.create!(:name=>tool, :nature=>"tractor")
    end
    for tool in ["Semoire en ligne", "Pulvérisateur porté", "Herse rotative", "Charrue"]
      self.tools.create!(:name=>tool, :nature=>"towed")
    end
    for tool in ["Embouteilleuse", "Pétrin"]
      self.tools.create!(:name=>tool, :nature=>"other")
    end
  end






  def journal_entries_between(started_on, stopped_on)
    self.journal_entries.find(:all, :joins=>"JOIN journal_records ON (journal_records.id=record_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on], :order=>"printed_on, journal_records.id, journal_entries.id")
  end

  def journal_entries_calculate(column, started_on, stopped_on, operation=:sum)
    column = (column == :balance ? "currency_debit - currency_credit" : "currency_#{column}")
    self.journal_entries.calculate(operation, column, :joins=>"JOIN journal_records ON (journal_records.id=record_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on])
  end


  # this method allows to make operations (such as sum of credits) in the entries, according to a list of accounts.
  def filtering_entries(field, list_accounts=[], period=[])
    #list_accounts.match(//) 
    # if not period.empty?
    #      period.each do |p|
    #        raise Exception.new("Invalid date "+p.to_s) unless p.class.eql? String
    #      end
    #    end
    
    conditions = "draft=false "
    if not list_accounts.empty?
      conditions += "AND "
      conditions += list_accounts.collect do |account|
        "a.number LIKE '"+account.gsub('*', '%').gsub('?', '_').to_s+"'"
      end.join(" OR ")
    end  
    
    conditions += " AND CAST(r.created_on AS DATE) BETWEEN '"+period[0].to_s+"' AND '"+period[1].to_s+"'" if not period.empty?
    
    if [:credit, :debit].include? field
      result =  self.journal_entries.sum(field, :conditions=>conditions, :joins=>"inner join accounts a on a.id=journal_entries.account_id inner join journal_records r on r.id=journal_entries.record_id")
    end

    if [:all, :first].include? field
      result =  self.journal_entries.find(field, :conditions=>conditions, :joins=>"inner join accounts a on a.id=journal_entries.account_id inner join journal_records r on r.id=journal_entries.record_id", :order=>"r.created_on ASC")
    end

    return result
    
  end

  # this method displays all the records matching to a given period.
  def records(from, to, id=nil)
    conditions = ["r.created_on between ? and ?", from, to]
    if id
      conditions[0] += " and r.journal_id = ?"
      conditions << id.to_s
    end
    return self.journal_entries.find(:all, :conditions=>conditions, :joins=>"inner join journal_records r on r.id=journal_entries.record_id", :order=>"r.number ASC")
  end


  def importable_columns
    columns = []
    columns << [tc("import.dont_use"), "special-dont_use"]
    columns << [tc("import.generate_string_complement"), "special-generate_string_complement"]
    # columns << [tc("import.generate_choice_complement"), "special-generate_choice_complement"]
    cols = Entity.content_columns.delete_if{|c| [:active, :full_name, :soundex, :lock_version, :updated_at, :created_at].include?(c.name.to_sym) or c.type == :boolean}.collect{|c| c.name}
    columns += cols.collect{|c| [Entity.human_name+"/"+Entity.human_attribute_name(c), "entity-"+c]}.sort
    cols = Contact.content_columns.collect{|c| c.name}.delete_if{|c| [:code, :started_at, :stopped_at, :deleted, :address, :by_default, :closed_on, :lock_version, :active,  :updated_at, :created_at].include?(c.to_sym)}+["line_6_city", "line_6_code"]
    columns += cols.collect{|c| [Contact.human_name+"/"+Contact.human_attribute_name(c), "contact-"+c]}.sort
    columns += ["name", "abbreviation"].collect{|c| [EntityNature.human_name+"/"+EntityNature.human_attribute_name(c), "entity_nature-"+c]}.sort
    columns += ["name"].collect{|c| [EntityCategory.human_name+"/"+EntityCategory.human_attribute_name(c), "entity_category-"+c]}.sort
    columns += self.complements.find(:all, :conditions=>["nature in ('string')"]).collect{|c| [Complement.human_name+"/"+c.name, "complement-id"+c.id.to_s]}.sort
    return columns
  end


  def exportable_columns
    columns = []
    columns += Entity.content_columns.collect{|c| [Entity.human_name+"/"+Entity.human_attribute_name(c.name), "entity-"+c.name]}.sort
    columns += Contact.content_columns.collect{|c| [Contact.human_name+"/"+Contact.human_attribute_name(c.name), "contact-"+c.name]}.sort
    columns += EntityNature.content_columns.collect{|c| [EntityNature.human_name+"/"+EntityNature.human_attribute_name(c.name), "entity_nature-"+c.name]}.sort
    columns += EntityCategory.content_columns.collect{|c| [EntityCategory.human_name+"/"+EntityCategory.human_attribute_name(c.name), "entity_category-"+c.name]}.sort
    columns += self.complements.collect{|c| [Complement.human_name+"/"+c.name, "complement-id"+c.id.to_s]}.sort
    return columns
  end


  def import_entities(file, cols, options={})
    sheet = FasterCSV.open(file)
    header = sheet.shift # header
    problems = {}
    line_index = 1
    code  = "ActiveRecord::Base.transaction do\n"
    unless cols[:entity_nature].is_a? Hash
      code += "  nature = self.entity_natures.find(:first, :conditions=>['abbreviation=? OR name=?', '-', '-'])\n"
      code += "  nature = self.entity_natures.create!(:abbreviation=>'-', :name=>'-', :physical=>false, :in_name=>false, :active=>true) unless nature\n"
    end
    unless cols[:entity_category].is_a? Hash
      code += "  category = self.entity_categories.find(:first, :conditions=>['name=? or code=?', '-', '-'])\n"
      code += "  category = self.entity_categories.create!(:name=>'-', :by_default=>false) unless category\n"
    end
    for k, v in (cols[:special]||{}).select{|k, v| v == :generate_string_complement}
      code += "  complement_#{k} = self.complements.create!(:name=>#{header[k.to_i].inspect}, :active=>true, :length_max=>65536, :nature=>'string', :required=>false)\n"
    end
    code += "  while line = sheet.shift\n"
    code += "    line_index += 1\n"
    code += "    next if #{options[:ignore].collect{|x| x.to_i}.inspect}.include?(line_index)\n" if options[:ignore]
    if cols[:entity_nature].is_a? Hash
      code += "    nature = self.entity_natures.find(:first, :conditions=>{"+cols[:entity_nature].collect{|k,v| ":#{v}=>line[#{k}]"}.join(', ')+"})\n"
      code += "    begin\n"
      code += "      nature = self.entity_natures.create!("+cols[:entity_nature].collect{|k,v| ":#{v}=>line[#{k}]"}.join(', ')+")\n"
      code += "    rescue\n"
      code += "      nature = self.entity_natures.find(:first, :conditions=>['abbreviation=? OR name=?', '-', '-'])\n"
      code += "      nature = self.entity_natures.create!(:abbreviation=>'-', :name=>'-', :physical=>false, :in_name=>false, :active=>true) unless nature\n"
      code += "    end unless nature\n"
    end
    if cols[:entity_category].is_a? Hash
      code += "    category = self.entity_categories.find(:first, :conditions=>{"+cols[:entity_category].collect{|k,v| ":#{v}=>line[#{k}]"}.join(', ')+"})\n"
      code += "    begin\n"
      code += "      category = self.entity_categories.create!("+cols[:entity_category].collect{|k,v| ":#{v}=>line[#{k}]"}.join(', ')+")\n"
      code += "    rescue\n"
      code += "      category = self.entity_categories.find(:first, :conditions=>['name=? or code=?', '-', '-'])\n"
      code += "      category = self.entity_categories.create!(:name=>'-', :by_default=>false) unless category\n"
      code += "    end unless category\n"
    end

    code += "    puts [nature, category].inspect\n"

    code += "    entity = self.entities.build("+cols[:entity].collect{|k,v| ":#{v}=>line[#{k}]"}.join(', ')+", :nature_id=>nature.id, :category_id=>category.id, :language=>#{self.entity.language}, :client=>true)\n"
    code += "    if entity.save\n"
    if cols[:contact].is_a? Hash
      code += "      contact = entity.contacts.build("+cols[:contact].collect{|k,v| ":#{v}=>line[#{k}]"}.join(', ')+")\n" 
      code += "      unless contact.save\n" 
      code += "        problems[line_index.to_s] ||= []\n"
      code += "        problems[line_index.to_s] += contact.errors.full_messages\n"
      code += "      end\n" 
    end
    for k, v in (cols[:special]||{}).select{|k,v| v == :generate_string_complement}
      code += "      datum = entity.complement_data.build(:company_id=>#{self.id}, :complement_id=>complement_#{k}.id, :string_value=>line[#{k}])\n"
      code += "      unless datum.save\n" 
      code += "        problems[line_index.to_s] ||= []\n"
      code += "        problems[line_index.to_s] += datum.errors.full_messages\n"
      code += "      end\n" 
    end
    for k, v in cols[:complement]||{}
      if complement = self.complements.find_by_id(k.to_s[2..-1].to_i)
        if complement.nature == 'string'
          code += "      datum = entity.complement_data.build(:complement_id=>#{complement.id}, :string_value=>line[#{k}])\n"
          code += "      unless datum.save\n" 
          code += "        problems[line_index.to_s] ||= []\n"
          code += "        problems[line_index.to_s] += datum.errors.full_messages\n"
          code += "      end\n" 
          # elsif complement.nature == 'choice'
          #   code += "    co = entity.contacts.create("+cols[:contact].collect{|k,v| ":#{v}=>line[#{k}]"}.join(', ')+")\n" if cols[:contact].is_a? Hash              
        end
      end
    end
    code += "    else\n"
    code += "      problems[line_index.to_s] ||= []\n"
    code += "      problems[line_index.to_s] += entity.errors.full_messages\n"
    code += "    end\n"
    code += "  end\n"
    code += "  raise ActiveRecord::Rollback\n" unless options[:no_simulation]
    code += "end\n"
    list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    eval(code)
    return {:errors=>problems, :lines_count=>line_index-1}
  end



  def export_entities(find_options={})
    entities = self.entities.find(:all, find_options)
    csv_string = FasterCSV.generate do |csv|
      csv << ["Code", "Type", "Catégorie", "Nom", "Prénom", "Dest-Service", "Bat.-Res.-ZI", "N° et voie", "Lieu dit", "Code Postal", "Ville", "Téléphone", "Mobile", "Fax", "Email", "Site Web", "Taux de réduction", "Commentaire"]
      entities.each do |entity|
        contact = self.contacts.find(:first, :conditions=>{:entity_id=>entity.id, :by_default=>true, :deleted_at=>nil})
        line = []
        line << ["'"+entity.code.to_s, entity.nature.name, entity.category.name, entity.name, entity.first_name]
        if !contact.nil?
          line << [contact.line_2, contact.line_3, contact.line_4, contact.line_5, contact.line_6_code, contact.line_6_city, contact.phone, contact.mobile, contact.fax ,contact.email, contact.website]  
        else
          line << [ "", "", "", "", "", "", "", "", "", "", ""]
        end
        line << [ entity.reduction_rate.to_s.gsub(/\./,","), entity.comment]
        csv << line.flatten
      end
    end
    return csv_string
  end
  


end
