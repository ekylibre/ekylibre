# == Schema Information
#
# Table name: companies
#
#  born_on          :date          
#  code             :string(8)     not null
#  created_at       :datetime      not null
#  creator_id       :integer       
#  deleted          :boolean       not null
#  entity_id        :integer       
#  id               :integer       not null, primary key
#  lock_version     :integer       default(0), not null
#  locked           :boolean       not null
#  name             :string(255)   not null
#  sales_conditions :text          
#  updated_at       :datetime      not null
#  updater_id       :integer       
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
  has_many :districts
  has_many :documents
  has_many :document_templates
  has_many :embankments
  has_many :employees
  has_many :entities
  has_many :entity_categories
  has_many :entity_link_natures
  has_many :entity_links
  has_many :entity_natures  
  has_many :entries
  has_many :establishments
  has_many :event_natures
  has_many :events
  has_many :financialyears
  has_many :inventories
  has_many :inventory_lines
  has_many :invoices
  has_many :invoice_lines
  has_many :journals
  has_many :journal_records
  has_many :languages
  has_many :listings
  has_many :listing_nodes
  has_many :listing_node_items
  has_many :mandates
  has_many :observations
  has_many :parameters
  has_many :payments
  has_many :payment_modes
  has_many :payment_parts
  has_many :prices
  has_many :price_taxes
  has_many :productions
  has_many :products
  has_many :product_components
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
  has_many :subscription_natures
  has_many :subscriptions
  has_many :taxes
  has_many :tax_declarations
  has_many :units
  has_many :users
  belongs_to :entity

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

  def after_create
    language = self.languages.create!(:name=>'Français', :native_name=>'Français', :iso2=>'fr', :iso3=>'fra')
    self.set_parameter('general.language', language)
    self.roles.create!(:name=>tc('default.role.name.admin'),  :rights=>User.rights_list.join(' '))
    self.roles.create!(:name=>tc('default.role.name.public'), :rights=>'')
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
    category = self.entity_categories.create!(:name=>'user')
    firm = self.entities.create!(:category_id=> category.id, :nature_id=>undefined_nature.id, :language_id=>language.id, :name=>self.name)
    self.entity_id = firm.id
    self.save ## TODO default_contact to create
    self.entity.contacts.create!(:company_id=>self.id, :line_2=>"XXXXXXXXXXXXXXXXXXX", :line_3=>"XXXXXXXXXXXXXXXXXXXX", :line_5=>"XXXXXXXXXXXXXXXXXXXX", :norm_id=>self.address_norms.first.id, :default=>true)
    
    # loading of all the templates
    #load_prints

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
    self.set_parameter('relations.entities.numeration', self.sequences.create!(:name=>tc('default.entities_numeration'), :format=>'[number|8]', :period=>'number'))
    
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
    self.stock_locations.create!(:name=>tc('default.stock_location'), :account_id=>self.accounts.find(:first, :conditions=>["number ILIKE ?", '3%' ], :order=>:number).id)
    self.event_natures.create!(:duration=>10, :usage=>"sale_order", :name=>tc(:sale_order_creation))
  end
  
  def parameter(name)
    parameter = self.parameters.find_by_name(name)
    if parameter.nil? and Parameter.reference.keys.include? name
      parameter = self.parameters.create!(:name=>name, :value=>Parameter.reference[name][:default])
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

  def available_products(options={})
    options[:conditions]={:active=>true}
    options[:order] ||= 'name'
    self.products.find(:all, options)
  end

  def available_prices(category_id=nil)
    conditions = ["entity_id=? AND p.active AND prices.active", self.entity_id]
    if category_id
      conditions[0] += " AND category_id=?"
      conditions << category_id
    end
    self.prices.find(:all, :joins=>"JOIN products p ON (p.id=product_id)", :conditions=>conditions, :order=>"p.name, prices.amount")
  end

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

#   def checks_to_embank_on_update(embankment)
#     checks = []
#     for payment in self.payments
#       checks << payment if ((payment.mode.mode == "check") and (payment.mode_id == embankment.mode_id) and (payment.embankment_id.nil? or payment.embankment_id == embankment.id) ) 
#     end
#     checks
#   end
  
 #  def checks_to_embank(mode_id)
#     checks = []
#     #raise Exception.new self.payments.inspect
#     for payment in self.payments
#       if mode_id == 0
#         checks << payment if ((payment.mode.mode == "check") and payment.embankment_id.nil?)
#       elsif mode_id == -1
#         checks << payment if ((payment.mode.mode == "check") and (payment.embankment_id.nil?) and Date.today >= (payment.to_bank_on+(15)) )
#       else
#         checks << payment if ((payment.mode.mode == "check") and (payment.mode_id == mode_id) and payment.embankment_id.nil?)
#       end
#     end
#     checks
#   end

  def checks_to_embank(mode_id=0)
    checks = []
    finder = {:joins=>"INNER JOIN payment_modes p ON p.mode = 'check' AND p.id = payments.mode_id"}
    if mode_id == 0 
      checks = self.payments.find(:all, finder.merge(:conditions=>['embankment_id IS NULL'] ))
    elsif mode_id == -1
      checks = self.payments.find(:all, finder.merge(:conditions=>['embankment_id IS NULL AND current_date >= to_bank_on+14']))
    else
      checks = self.payments.find(:all, finder.merge(:conditions=>['embankment_id IS NULL AND mode_id = ?', mode_id]))
    end
    checks
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

  def find_sales_journal
    if self.sales_journal_id.nil?
      journal_id = self.journals.find_by_nature("sale")
      journal_id = Journal.create!(:company_id=>self.id, :nature=>"sale", :currency_id=>self.currencies(:first), :name=>tc(:sales), :code=>"V", :closed_on=>Date.today+(365)) if journal_id.nil?
    else
      journal_id = self.sales_journal_id
    end
    journal_id
  end

  def usable_payments
    self.payments.find(:all, :conditions=>["COALESCE(parts_amount,0)<COALESCE(amount,0)"], :order=>"created_at desc")
  end

  def backup(creator, with_prints=true)
    version = (ActiveRecord::Migrator.current_version rescue 0)
    filename = "backup-"+self.code.lower+"-"+Time.now.strftime("%Y%m%d-%H%M%S")
    file = "#{RAILS_ROOT}/tmp/#{filename}.zip"
    doc = LibXML::XML::Document.new
    # doc << REXML::XMLDecl.new
    doc.root = backup = XML::Node.new('backup')
    {'version'=>version, 'creation-date'=>Date.today, 'creator'=>creator.label}.each{|k,v| backup[k]=v.to_s}
    # backup = doc.add_element 'backup', 'version'=>version, 'creation-date'=>Date.today.to_s, 'creator'=>creator.label
    backup << root = XML::Node.new('company')
    self.attributes.each{|k,v| root[k] = v.to_s}
    n = 0
    start = Time.now.to_i
    models = EKYLIBRE_MODELS.delete_if{|x| x==:company}
    #reflections = self.class.reflections

    for name in models # reflections.keys.collect{|x| x.to_s}.sort
      # reflection = reflections[name.to_sym]
      # if reflection.macro==:has_many
      # rows = self.send(name.to_sym).find(:all, :order=>:id)
      rows = name.to_s.camelcase.constantize.find(:all, :conditions=>{:company_id=>self.id}, :order=>:id)
      rows_count = rows.size
      n += rows_count
      root << table = XML::Node.new('rows')
      {'reflection'=>name.pluralize, 'records-count'=>rows_count.to_s}.each{|k,v| table[k]=v}
      #table = root.add_element('rows', )
      rows_count.times do |i|
        # puts i if i%200==0
        table << row = XML::Node.new('row')
        rows[i].attributes.each{|k,v| row[k] = v.to_s}
      end
    end
    # backup.add_attributes('records-count'=>n.to_s, 'generation-duration'=>(Time.now.to_i-start).to_s)
    stream = doc.to_s

    Zip::ZipFile.open(file, Zip::ZipFile::CREATE) do |zile|
      zile.get_output_stream("backup.xml") { |f| f.puts(stream) }
      if with_prints
        prints_dir = "#{RAILS_ROOT}/private/#{self.code}"
        Dir.chdir(prints_dir) do
          for document in Dir["*/*/*.pdf"]
            zile.add("prints/"+document, prints_dir+'/'+document)
          end
        end
      end
    end
    # Zlib::GzipWriter.open(file) { |gz| gz.write(stream) }
    return file
  end


  # Restore database
  # with printed arhived documents if requested
  def restore(file)
    prints_dir = "#{RAILS_ROOT}/private/#{self.code}"
    # Décompression
    puts "R> Uncompressing backup..."
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
    puts "R> Parsing backup.xml (#{version})..."
    doc = LibXML::XML::Document.file(backup)
    backup = doc.root
    attr_version = backup.attributes['version']
    return false if not attr_version or (attr_version != version.to_s)

    root = backup.children[1]
    ActiveRecord::Base.transaction do
      # Suppression des données
      puts "R> Removing existing data..."
      ids  = {}
      keys = {}
      fkeys = {}
      reflections = self.class.reflections
      for name in reflections.keys.collect{|x| x.to_s}.sort
        reflection = reflections[name.to_sym]
        if reflection.macro==:has_many
          other = reflection.class_name
          other_class = other.constantize
          ids[other] = keys[other] = {}
          fkeys[other] = []
          for name, ref in other_class.reflections
            # Ex. : keys["User"]["role_id"] = "Role"
            keys[other][ref.primary_key_name] = (ref.options[:polymorphic] ? ref.options[:foreign_type].to_sym : ref.class_name) if ref.macro==:belongs_to and ref.class_name!=self.class.name
            fkeys[other] << ref.primary_key_name if ref.macro==:belongs_to and ref.class_name!=self.class.name
          end
          other_class.delete_all(:company_id=>self.id)
        elsif reflection.macro==:belongs_to
          keys[self.class.name] ||= {}
          keys[self.class.name][reflection.primary_key_name] = reflection.class_name
        end
      end


      # Chargement des données sauvegardées
      puts "R> Loading backup data..."
      data = {}
      children = root.children
      elements = []
      children.size.times{|i| elements << {:index=>i, :attributes=>children[i].attributes} if children[i].element? }
      code = ''
      for element in elements
        reflection = self.class.reflections[element[:attributes]['reflection'].to_sym]
        klass = reflection.class_name.constantize
        foreign_keys = keys[reflection.class_name].collect{|key, v| ":#{key}=>record.#{key}"}
        code += "puts('R> - #{reflection.name.to_s} (#{element[:attributes]['records-count']})')\n" 
        code += "start, tdb1, tdb2p = Time.now, 0, 0\n"
        code += "data['#{reflection.class_name}'] ||= []\n" if foreign_keys.size>0
        code += "children[#{element[:index]}].each_element do |r|\n"
        code += "  attributes = r.attributes.to_h\n"
        code += "  id = attributes['id']\n"
        code += "  dstart = Time.now\n"

        code += "  record = self.#{reflection.name}.new\n"
        klass.columns_hash.keys.delete_if{|k| k=='id' or k=='company_id'}.each do |attr|
          code += "  record.#{attr} = attributes['#{attr}']\n"
        end

        code += "  tdb1 += Time.now-dstart\n"
        code += "  record.send(:create_without_callbacks)\n"
        code += "  tdb2p += Time.now-dstart\n"
        code += "  ids['#{reflection.class_name}'][id] = record.id\n"
        code += "  data['#{reflection.class_name}'] << [record.id, #{fkeys[reflection.class_name].collect{|f| keys[reflection.class_name][f].is_a?(Symbol) ? '[record.'+keys[reflection.class_name][f].to_s+', record.'+f.to_s+']' : 'record.'+f.to_s}.join(', ')}]\n" if fkeys[reflection.class_name].size>0
        #code += "  data['#{reflection.class_name}'][record.id] = {#{foreign_keys.join(', ')}}\n" if foreign_keys.size>0
        code += "end\n"
        if element[:attributes]['records-count'].to_i>30
          code += "duration, tdb2 = Time.now-start, tdb2p-tdb1\n"
          code += "duration = Time.now-start\n"
          code += "puts 'R>     T: '+duration.to_s[0..6]+' | TDB1: '+tdb1.to_s[0..6]+' | TDB2: '+tdb2.to_s[0..6]+' | RS: '+(duration-tdb2p).to_s[0..6]+' | AVG(TDB1): '+(tdb1/#{element[:attributes]['records-count']}).to_s[0..6]+' | AVG(TDB2): '+(tdb2/#{element[:attributes]['records-count']}).to_s[0..6]\n"
          # code += "puts 'R>     *****************************' if (tdb1>tdb2)\n" 
        end
      end
      File.open("/tmp/restore-1.rb", "wb") {|f| f.write(code)}
      eval(code)

#       data = {}
#       root.each_element do |table|
#         reflection = self.class.reflections[table.attributes['reflection'].to_sym]
#         start = Time.now.to_i
#         puts('R> - '+reflection.name.to_s+' ('+table.attributes['records-count'].to_s+')')
#         klass = reflection.class_name.constantize
#         foreign_keys = keys[reflection.class_name].collect{|key| ":#{key}=>record.#{key}"}
#         code =  "x = 0\n"
#         code += "data[:#{reflection.name}] = []\n" if foreign_keys.size>0
#         code += "table.each_element do |r|\n"
#         code += "  x += 1\n"
#         code += "  puts x.to_s if x.modulo(1000)==0\n"
#         code += "  attributes = r.attributes\n"
#         code += "  id = attributes['id']\n"
#         unbuildable = (['company_id', 'id']+klass.protected_attributes.to_a)
#         code += "  record = self.#{reflection.name}.build("+klass.columns_hash.keys.delete_if{|x| unbuildable.include? x.to_s}.collect do |col|
#           ":#{col}=>attributes['#{col}']"
#         end.join(", ")+")\n"
#         klass.protected_attributes.to_a.each do |attr|
#           code += "  record.#{attr} = attributes['#{attr}']\n"
#         end
#         code += "  record.send(:create_without_callbacks)\n"
#         code += "  ids[#{reflection.class_name.inspect}][id] = record.id\n"
#         code += "  data[:#{reflection.name}] << {:id=>record.id#{foreign_keys}}\n" if foreign_keys.size>0
#         code += "end"
#         puts code
#         eval(code)
#         duration = Time.now.to_i-start
#         puts duration.to_s+' secondes' if duration > 5
#       end
      

      # Réorganisation des clés étrangères
      puts "R> Redifining primary keys..."
      code  = ''
      for reflection in data.keys
        # klass = Company.reflections[reflection].class_name
        klass = reflection


        new_ids = "'"
        for i in 1..fkeys[klass].size
          key = fkeys[klass][i-1]
          class_name = keys[klass][key]
          new_ids += (i>1 ? "+', " : "")+"#{key}='+"
          if class_name.is_a? Symbol
            new_ids += "((ids[record[#{i}][0]][record[#{i}][1].to_s])||record[#{i}][1]||'NULL').to_s"
          else
            new_ids += "((ids['#{class_name}'][record[#{i}].to_s])||record[#{i}]||'NULL').to_s"
          end
        end

#         new_ids = "'"+fkeys[klass].collect do |key|
#           class_name = keys[klass][key]
#           "#{key}='+((ids[#{class_name.is_a?(Symbol) ? 'record[\''+class_name.to_s+'\']' : class_name.inspect}][record['#{key}'].to_s])||record['#{key}']||'NULL').to_s"
#         end.join("+', ")
        #         new_ids = "'"+keys[klass].collect do |key, class_name|
        #           "#{key}='+((ids[#{class_name.is_a?(Symbol) ? 'record[\''+class_name.to_s+'\']' : class_name.inspect}][record['#{key}'].to_s])||record['#{key}']||'NULL').to_s"
        #         end.join("+', ")
        code += "for record in data['#{reflection}']\n"
        code += "  #{klass}.update_all(#{new_ids}, 'id='+record[0].to_s)\n"
        code += "end\n"
#        klass = Company.reflections[reflection].class_name
#        new_ids = "'"+keys[klass].collect do |key, class_name|
#          "#{key}='+((ids[#{class_name.is_a?(Symbol) ? 'record[\''+class_name.to_s+'\']' : class_name.inspect}][record['#{key}'].to_s])||record['#{key}']||'NULL').to_s"
#        end.join("+', ")
#        code += "for record in data[:#{reflection}]\n"
#        code += "  #{klass}.update_all(#{new_ids}, 'id='+record.id.to_s)\n"
#        code += "end\n"
      end
      File.open("/tmp/restore-2.rb", "wb") {|f| f.write(code)}      
#      raise Exception.new
      start = Time.now
      eval(code)
      puts "R> Total: #{(Time.now-start)}s"

      # Chargement des paramètres de la société
      puts "R> Loading company data..."
      attrs = root.attributes.each do |attr|
        self.send(attr.name+'=', attr.value) unless ['id', 'lock_version', 'code'].include? attr.name
      end
      for key, class_name in keys[self.class.name]
        v = ids[class_name][self[key].to_s]
        self[key] = v unless v.nil?
      end
      self.send(:update_without_callbacks)
      # raise Active::Record::Rollback

      if File.exist?(prints_dir+".prints")
        puts "R> Replacing prints..."
        File.move prints_dir, prints_dir+'.old'
        File.move prints_dir+'.prints', prints_dir
        FileUtils.rm_rf(prints_dir+'.old')
      end
    end

    return true
  end






  def print(object, options={})
    unless object.class.ancestors.include?(ActiveRecord::Base)
      raise Exception.new("The parameter object must be an ActiveRecord::Base descendant object")
    end

    # Finding template
    template = nil
    if options[:template]
      template = options[:template] if options[:template].is_a? DocumentTemplate
      template = self.document_templates.find_by_id(options[:template]) if options[:template].is_a? Integer
      template = self.document_templates.find_by_code(options[:template]) if options[:template].is_a? String
    elsif
      template = self.document_templates.find_by_code(object.class.to_s.underscore)
    end
    return DocumentTemplate.error_document("Can't find any template to print") unless template
      
    # Printing
    # TODO: Cache printing method
    return template.print(object)
  end


  def export_entities(find_options={})
    entities = self.entities.find(:all, find_options)
    csv_string = FasterCSV.generate do |csv|
      csv << ["Code", "Type", "Nom", "Prénom","Dest-Service","Bat.-Res.-ZI","N° voie","Libelle voie","Lieu dit","Code Postal","Ville",  "Téléphone", "Mobile", "Fax","Email","Site Web", "Taux de réduction", "Commentaire" ]
      entities.each do |entity|
        contact = self.contacts.find(:first, :conditions=>{:entity_id=>entity.id, :default=>true, :deleted=>false})
        line = []
        line << [entity.code, entity.nature.name, entity.name, entity.first_name]
        if !contact.nil?
          line << [contact.line_2, contact.line_3, contact.line_4_number, contact.line_4_street, contact.line_5, contact.line_6_code, contact.line_6_city, contact.phone, contact.mobile, contact.fax ,contact.email, contact.website]  
        else
          line << [ "", "", "", "", "", "", "", "", "", "", "", ""]
        end
        line << [ entity.reduction_rate.to_s.gsub(/\./,","), entity.comment]
        csv << line.flatten
      end
    end
    return csv_string
  end
  
  # this method loads all the templates existing.
  def load_prints
    language = @current_company.entity.language
    prints_dir = "#{RAILS_ROOT}/app/views/prints"
 
    families = {}
    families[:management] ={'sale_order'=>{:to_archive=>false}, 'invoice'=>{:to_archive=>true}}
    families[:accountancy] ={'journal'=>{:to_archive=>false}, 'journal_by_id'=>{:to_archive=>false}}
  
    families.each do |family, templates|
      templates.each do |template, options|
        File.open("#{prints_dir}/#{template}.xml", 'rb') do |f|
          @current_company.document_templates.create(:active=>true, :name=>t('models.company.default.document_templates.'+template.to_s), :language_id=>language.id, :country=>'fr', :source=>f.read, :to_archive=>options[:to_archive], :family=>family.to_s, :code=>template)
        end
      end
    end
  end
  
  def import_entities
  end

  def self.load_demo_data(locale="fr-FR", company=nil)
    company.load_demo_data(company) if company
  end
  
  def load_demo_data(company)
    company.entity_natures.create!(:name=>"Société A Responsabilité Limitée", :abbreviation=>"SARL", :in_name=>true)
    last_name = ["MARTIN","DUPONT","DURAND","CHIRAC", "LABAT", "VILLENEUVE", "SICARD", "FRERET", "FOUCAULT", "DUPEYRON", "BORGÈS", "DUBOIS", "LEROY", "MOREL", "GUERIN", "MORIN", "ROUSSEAU", "LEMAIRE", "DUVAL", "BRUN", "FERNANDEZ", "BRETON", "LEBLANC", "DA SILVA", "CORDIER", "BRIAND", "CAMUS", "VOISIN", "LELIEVRE", "GONZALEZ"]
    first_name = ["Benoit", "Stéphane", "Marine", "Roger", "Céline", "Bertrand", "Julie", "Kévin", "Maxime", "Vincent", "Claire", "Marie-France", "Jean-Marie", "Anne-Marie", "Dominique", "Alain", "Daniel", "Sylvie", "Fabrice", "Nathalie", "Véronique", "Jeanine", "Edouard", "Colette", "Sébastien", "Rémi", "Joseph", "Baptiste", "Martine", "Guy"]
    streets = ["Cours Xavier Arnozan", "Cours du général de Gaulle", "Route pavée", "Avenue Thiers", "Rue Gambetta", "5th Avenue", "rue Louis La Brocante", "Rue Léon Blum", "Avenue François Mittérand", "Cours de la marne"]
    cities = ["33000 Bordeaux", "33170 Gradignan", "40600 Biscarosse", "33400 Talence", "75001 Paris", "13000 Marseille", "33600 Pessac", "47000 Agen", "33710 Pugnac", "33700 Mérignac", "40000 Mont de Marsan"]
    entity_natures = company.entity_natures.collect{|x| x.id.to_s}
    indifferent_attributes = {:category_id=>company.entity_categories.first.id, :language_id=>company.languages.first.id}
    products = ["Salades","Bouteille en verre 75 cl","Bouchon liège","Capsule CRD", "Capsule", "Étiquette", "Vin Saint-Emilion 2005", "Caisse Bois 6 btles", "Bouteille Saint-Emilion 2005 75 cl", "Caisse 6 b. Saint-Emilion 2005", "patates", "Séjour 1 nuit", "Séjour 1 semaine 1/2 pension", "Fongicide", "Insecticide"]
    shelf_id = company.shelves.first.id
    unit_id  = company.units.find(:first, :conditions=>{:label=>"Unité"}).id
    category_id = company.entity_categories.first.id
    taxes = company.taxes.collect{|x| x.id.to_s}
    
    for x in 0..30
      entity = company.entities.new(indifferent_attributes)
      entity.name = last_name[rand(last_name.size)]
      entity.first_name = first_name[rand(first_name.size)]
      entity.nature_id = entity_natures[rand(entity_natures.size).to_i]
      entity.name = entity.nature.abbreviation+" "+entity.name if entity.nature.in_name 
      entity.client = (rand() > 0.5 or rand() > 0.8)
      entity.supplier = (rand() > 0.75 or x == 0)
      entity.transporter = rand() > 0.9
      entity.save! 
      contact = entity.contacts.create!(:company_id=>company.id, :line_4_number=>rand(100), :line_4_street=>streets[rand(streets.size)], :norm_id=>entity.company.address_norms.first.id, :line_6=>cities[rand(cities.size)], :default=>true)
    end
    company.entity_link_natures.create!(:name=>"Gérant - Société", :name_1_to_2=>"gère la société", :name_2_to_1=>"est une société qui a pour associé", :propagate_contacts=>true, :symmetric=>false)
    company.subscription_natures.create!(:name=>"Abonement annuel", :nature=>"period", :reduction_rate=>0.1)
    company.event_natures.create!(:name=>"Conversation téléphonique", :duration=>10, :usage=>"manual")
    
    for product_name in products
      product = company.products.create(:nature=>"product", :name=>product_name, :to_sale=>true, :supply_method=>"produce", :shelf_id=>shelf_id, :unit_id=>unit_id, :manage_stocks=>true, :weight=>rand(3)) 
      product.reload
      product.prices.create!(:amount=>rand(100), :company_id=>company.id, :use_range=>false, :tax_id=>taxes[rand(taxes.size).to_i], :category_id=>category_id, :entity_id=>product.name.include?("icide") ? company.entities.find(:first, :conditions=>{:supplier=>true}).id : company.entity_id)
    end
    
    product = company.products.find_by_name("Caisse 6 b. Saint-Emilion 2005")
    company.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>company.products.find_by_name("Bouteille Saint-Emilion 2005 75 cl").id, :quantity=>6, :location_id=>company.stock_locations.first.id)
    company.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>company.products.find_by_name("Caisse Bois 6 btles").id, :quantity=>1, :location_id=>company.stock_locations.first.id)

    product = company.products.find_by_name("Bouteille Saint-Emilion 2005 75 cl")
    company.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>company.products.find_by_name("Bouchon liège").id, :quantity=>1, :location_id=>company.stock_locations.first.id)
    company.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>company.products.find_by_name("Étiquette").id, :quantity=>1, :location_id=>company.stock_locations.first.id)
    company.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>company.products.find_by_name("Bouteille en verre 75 cl").id, :quantity=>1, :location_id=>company.stock_locations.first.id)
    company.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>company.products.find_by_name("Vin Saint-Emilion 2005").id, :quantity=>0.75, :location_id=>company.stock_locations.first.id)
    company.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>company.products.find_by_name("Capsule CRD").id, :quantity=>1, :location_id=>company.stock_locations.first.id)
    
    company.subscriptions.create!(:nature_id=>company.subscription_natures.first.id, :started_on=>Date.today, :stopped_on=>Date.today+(365), :entity_id=>company.entities.find(:first, :conditions=>{:client=>true}).id, :suspended=>false)
  end
<<<<<<< .mine

  # this method allows to make operations (such as sum of credits) in the entries, according to a list of accounts.
 def filtering_entries(field, list_accounts=[], period=[])
   #list_accounts.match(//) 
   # if not period.empty?
#      period.each do |p|
#        raise Exception.new("Invalid date "+p.to_s) unless p.class.eql? String
#      end
#    end
   
   
   conditions = ""#"company_id = "+self.id.to_s
   if not list_accounts.empty?
     conditions += list_accounts.collect do |account|
       "a.number LIKE '"+account.gsub('*', '%').gsub('?', '_').to_s+"'"
     end.join(" OR ")
   end  
   
   conditions += " AND CAST(r.created_on AS DATE) BETWEEN '"+period[0].to_s+"' AND '"+period[1].to_s+"'" if not period.empty?
  
   if [:credit, :debit].include? field
      result =  self.entries.sum(field, :conditions=>conditions, :joins=>"inner join accounts a on a.id=entries.account_id inner join journal_records r on r.id=entries.record_id")
   end

   if [:all, :first].include? field
     result =  self.entries.find(field, :conditions=>conditions, :joins=>"inner join accounts a on a.id=entries.account_id inner join journal_records r on r.id=entries.record_id", :order=>"r.created_on ASC")
   end

   return result
                            
 end


end
