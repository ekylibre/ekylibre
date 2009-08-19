# == Schema Information
#
# Table name: companies
#
#  born_on      :date          
#  code         :string(8)     not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  deleted      :boolean       not null
#  entity_id    :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  locked       :boolean       not null
#  name         :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
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
  has_many :invoices
  has_many :invoice_lines
  has_many :journals
  has_many :journal_records
  has_many :languages
  has_many :mandates
  has_many :observations
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
  has_many :subscription_natures
  has_many :subscriptions
  has_many :taxes
  has_many :units
  has_many :users
  belongs_to :entity

  attr_readonly :code
  
  def before_validation_on_create
    self.code = self.name.to_s[0..7].simpleize if self.code.blank?
    self.code = rand.to_s[2..-1].to_i.to_s(36)[0..7] if self.code.blank?
    self.code = self.code.simpleize.upper
    while Company.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
      self.code.succ!
    end
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
    firm = self.entities.create!(:nature_id=>undefined_nature.id, :language_id=>language.id, :name=>self.name)
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
    self.products.find(:all, options)
  end

  def available_taxes(options={})
    #    options[:conditions]={:deleted=>false}
    self.taxes.find(:all, options)
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
    reflections = self.class.reflections
    for name in reflections.keys.collect{|x| x.to_s}.sort
      reflection = reflections[name.to_sym]
      if reflection.macro==:has_many
        rows = self.send(name.to_sym).find(:all, :order=>:id)
        rows_count = rows.size
        n += rows_count
        root << table = XML::Node.new('rows')
        {'reflection'=>name, 'records-count'=>rows_count.to_s}.each{|k,v| table[k]=v}
        #table = root.add_element('rows', )
        rows_count.times do |i|
          # puts i if i%200==0
          table << row = XML::Node.new('row')
          rows[i].attributes.each{|k,v| row[k] = v.to_s}
        end
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
      reflections = self.class.reflections
      for name in reflections.keys.collect{|x| x.to_s}.sort
        reflection = reflections[name.to_sym]
        if reflection.macro==:has_many
          other = reflection.class_name
          other_class = other.constantize
          ids[other] = {}
          keys[other] = {}
          for name, ref in other_class.reflections
            # Ex. : keys["User"]["role_id"] = "Role"
            keys[other][ref.primary_key_name] = (ref.options[:polymorphic] ? ref.options[:foreign_type].to_sym : ref.class_name) if ref.macro==:belongs_to and ref.class_name!=self.class.name
          end
          other_class.delete_all(:company_id=>self.id)
        elsif reflection.macro==:belongs_to
          keys[self.class.name] ||= {}
          keys[self.class.name][reflection.primary_key_name] = reflection.class_name
        end
      end


      # Chargement des données sauvegardées
      puts "R> Loading backup data..."
      data = []
      root.each_element do |table|
        reflection = self.class.reflections[table.attributes['reflection'].to_sym]
        start = Time.now.to_i
        puts('R> - '+reflection.name.to_s)
        code =  "x = 0\n"
        code += "table.each_element do |r|\n"
        code += "  x += 1\n"
        code += "  puts x.to_s if x.modulo(1000)==0\n"
        code += "  attributes = r.attributes\n"
        code += "  id = attributes['id']\n"
        code += "  record = self.#{reflection.name}.build("
        code += reflection.class_name.constantize.columns_hash.keys.delete_if{|x| [:company_id, :id].include? x}.collect do |col|
          ":#{col}=>attributes['#{col}']"
        end.join(", ")
        code += ")\n"
        code += "  record.send(:create_without_callbacks)\n"
        code += "  ids[#{reflection.class_name.inspect}][id] = record.id\n"
        code += "  data << record\n"
        code += "end"
        # puts code
        eval(code)
        duration = Time.now.to_i-start
        puts duration.to_s+' secondes' if duration > 5
#         table.each_element do |r|
#           attributes = r.attributes
#           id = attributes['id']
          

#           record = self.send(reflection.name).build
#           attributes.each do |attr|
#             record.send(attr.name+'=', attr.value) unless ['id', 'company_id'].include? attr.name
#           end
#           #attributes.each{|k,v| record.send(k+'=', v)}
#           record.send(:create_without_callbacks)
#           ids[reflection.class_name][id] = record.id
#           data << record
#         end
      end


      # Réorganisation des clés étrangères
      puts "R> Redifining primary keys..."
      for record in data
        for key, class_name in keys[record.class.name]
          # user[:role_id] = ids["Role"][user[:role_id].to_s]
          #raise Exception.new('>> '+class_name.inspect) if ids[class_name].nil?
          if record[key]
            klass = (class_name.is_a?(Symbol) ? record[class_name] : class_name)
            raise Exception.new([record.class.name, class_name, klass, record, key, ids[klass], record[key]].inspect) if ids[klass].nil? or record[key].nil?
            v = ids[klass][record[key].to_s]
            #             if class_name.is_a? Symbol
            #               v = ids[record[class_name]][record[key].to_s]
            #             else
            #               v = ids[class_name][record[key].to_s]
            #             end
            record[key] = v unless v.nil?
          end
        end
        record.send(:update_without_callbacks)
      end
      
      

      # Chargement des paramètres de la société
      puts "R> Loading company data..."
      attrs = root.attributes.each do |attr|
        self.send(attr.name+'=', attr.value) unless ['id', 'lock_version', 'code'].include? attr.name
      end
      for key, class_name in keys[self.class.name]
        v = ids[class_name][self[key].to_s]
        self[key] = v unless v.nil?
      end
      #      while self.class.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
      #        self.code.succ!
      #      end
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



  # Restore database
  # with printed arhived documents if requested
  def restore_sql(file)
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
    
    # Parsing
    version = (ActiveRecord::Migrator.current_version rescue 0)
    puts "R> Parsing backup.xml (#{version})..."
    backup = stream.split("\n")
#    doc = LibXML::XML::Document.file(backup)
#    backup = doc.root
#    attr_version = backup.attributes['version']
#    return false if not attr_version or (attr_version != version.to_s)

#    root = backup.children[1]
    ActiveRecord::Base.transaction do
      # Suppression des données
      puts "R> Removing existing data..."
      ids  = {}
      keys = {}
      reflections = self.class.reflections
      for name in reflections.keys.collect{|x| x.to_s}.sort
        reflection = reflections[name.to_sym]
        if reflection.macro==:has_many
          other = reflection.class_name
          other_class = other.constantize
          ids[other] = {}
          keys[other] = {}
          for name, ref in other_class.reflections
            # Ex. : keys["User"]["role_id"] = "Role"
            keys[other][ref.primary_key_name] = (ref.options[:polymorphic] ? ref.options[:foreign_type].to_sym : ref.class_name) if ref.macro==:belongs_to and ref.class_name!=self.class.name
          end
          other_class.delete_all(:company_id=>self.id)
        elsif reflection.macro==:belongs_to
          keys[self.class.name] ||= {}
          keys[self.class.name][reflection.primary_key_name] = reflection.class_name
        end
      end


      # Chargement des données sauvegardées
      puts "R> Loading backup data..."
      data = []
      backup.size.times do |i|
        line = backup[i]
        if line.match(/^\s*COPY\s+/)
          line = line.strip
          reflection = self.class.reflections[line.split(/[\s+\(]/)[1].to_sym]
          puts('R> - '+reflection.name.to_s)
          columns = {}
          cols = line.split(/\(/)[1].split(/\)/)[0].split(',').collect{|c| c.strip.to_sym}
          cols.size.times do |i|
            columns[cols[i]] = {:index=>i} unless [:id, :company_id].include?(cols[i])
          end
          code  = "while backup[i]!='\\.' do\n"
          code += "  puts i\n"
          code += "  puts i.to_s if i.modulo(100)==0\n"
          code += "  values = backup[i].split(/\\t/).collect{|v| (v=='\\N' ? '\\N' : v.gsub(/\\\\n/, \"\\n\").gsub(/\\\\t/, \"\\t\"))}\n"
          code += "  ActiveRecord::Base.connection.execute('INSERT INTO #{reflection.name} (#{columns.keys.join(',')}) VALUES ('+values.inspect+')')\n"
          code += "  record = self.#{reflection.name}.build("+columns.collect do |column, params|
            ":#{column}=>values[#{params[:index]}]"
          end.compact.join(", ")+")\n"
          code += "  record.send(:create_without_callbacks)\n"
          code += "  ids[#{reflection.class_name.inspect}][values[#{columns.index(:id)}]] = record.id\n"
          code += "  data << record\n"
          code += "  i += 1\n"
          code += "end\n"
          i += 1
          puts code  # if reflection.name==:areas
          eval(code) # if reflection.name==:areas
        elsif line.match(/^\s+$/) or line.match(/^\-\-/)
          next
        else
          next
          raise Exception.new("Malformation: line #{i}: "+line)
        end
      end

#       data = []
#       root.each_element do |table|
#         reflection = self.class.reflections[table.attributes['reflection'].to_sym]
#         puts('R> - '+reflection.name.to_s)
#         code =  "x = 0\n"
#         code += "table.each_element do |r|\n"
#         code += "  x += 1\n"
#         code += "  puts x.to_s if x.modulo(100)==0\n"
#         code += "  attributes = r.attributes\n"
#         code += "  id = attributes['id']\n"
#         code += "  record = self.#{reflection.name}.build("
#         code += reflection.class_name.constantize.columns_hash.keys.delete_if{|x| [:company_id, :id].include? x}.collect do |col|
#           ":#{col}=>attributes['#{col}']"
#         end.join(", ")
#         code += ")\n"
#         code += "  record.send(:create_without_callbacks)\n"
#         code += "  ids[#{reflection.class_name.inspect}][id] = record.id\n"
#         code += "  data << record\n"
#         code += "end"
#         puts code
#         eval(code)
#       end


#       # Réorganisation des clés étrangères
#       puts "R> Redifining primary keys..."
#       for record in data
#         for key, class_name in keys[record.class.name]
#           # user[:role_id] = ids["Role"][user[:role_id].to_s]
#           #raise Exception.new('>> '+class_name.inspect) if ids[class_name].nil?
#           if record[key]
#             v = ids[class_name.is_a?(Symbol) ? record[class_name] : class_name][record[key].to_s]
#             #             if class_name.is_a? Symbol
#             #               v = ids[record[class_name]][record[key].to_s]
#             #             else
#             #               v = ids[class_name][record[key].to_s]
#             #             end
#             record[key] = v unless v.nil?
#           end
#         end
#         record.send(:update_without_callbacks)
#       end
      
      

#       # Chargement des paramètres de la société
#       puts "R> Loading company data..."
#       attrs = root.attributes.each do |attr|
#         self.send(attr.name+'=', attr.value) unless ['id', 'lock_version', 'code'].include? attr.name
#       end
#       for key, class_name in keys[self.class.name]
#         v = ids[class_name][self[key].to_s]
#         self[key] = v unless v.nil?
#       end
#       #      while self.class.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
#       #        self.code.succ!
#       #      end
#       self.send(:update_without_callbacks)
#       # raise Active::Record::Rollback

#       if File.exist?(prints_dir+".prints")
#         puts "R> Replacing prints..."
#         File.move prints_dir, prints_dir+'.old'
#         File.move prints_dir+'.prints', prints_dir
#         FileUtils.rm_rf(prints_dir+'.old')
#       end
    end

    return true
  end




  def backup_rexml(creator, with_prints=true)
    version = (ActiveRecord::Migrator.current_version rescue 0)
    filename = "backup-"+self.code.lower+"-"+Time.now.strftime("%Y%m%d-%H%M%S")
    file = "#{RAILS_ROOT}/tmp/#{filename}.zip"
    doc = REXML::Document.new
    doc << REXML::XMLDecl.new
    backup = doc.add_element 'backup', 'version'=>version, 'creation-date'=>Date.today.to_s, 'creator'=>creator.label
    root = backup.add_element 'company', self.attributes
    n = 0
    start = Time.now.to_i
    reflections = self.class.reflections
    for name in reflections.keys.collect{|x| x.to_s}.sort
      reflection = reflections[name.to_sym]
      if reflection.macro==:has_many
        rows = self.send(name.to_sym).find(:all, :order=>:id)
        rows_count = rows.size
        n += rows_count
        table = root.add_element('rows', 'reflection'=>name, 'records-count'=>rows_count.to_s)
        rows_count.times do |i|
          # puts i if i%200==0
          table.add_element('row', rows[i].attributes)
        end
      end
    end
    backup.add_attributes('records-count'=>n.to_s, 'generation-duration'=>(Time.now.to_i-start).to_s)
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
  def restore_rexml(file)
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
    File.open(file, 'wb') {|f| f.write(stream)}
    
    
    # Zlib::GzipReader.open(file) { |gz| stream = gz.read }
    puts "R> Parsing backup.xml..."
    doc = REXML::Document.new(File.new(file))
    backup = doc.root
    version = (ActiveRecord::Migrator.current_version rescue 0)
    return false if backup.attribute('version').value != version.to_s

    root = backup.elements[1]
    ActiveRecord::Base.transaction do
      # Suppression des données
      puts "R> Removing existing data..."
      ids  = {}
      keys = {}
      reflections = self.class.reflections
      for name in reflections.keys.collect{|x| x.to_s}.sort
        reflection = reflections[name.to_sym]
        if reflection.macro==:has_many
          other = reflection.class_name
          other_class = other.constantize
          ids[other] = {}
          keys[other] = {}
          for name, ref in other_class.reflections
            # Ex. : keys["User"]["role_id"] = "Role"
            keys[other][ref.primary_key_name] = (ref.options[:polymorphic] ? ref.options[:foreign_type].to_sym : ref.class_name) if ref.macro==:belongs_to and ref.class_name!=self.class.name
          end
          other_class.delete_all(:company_id=>self.id)
        elsif reflection.macro==:belongs_to
          keys[self.class.name] ||= {}
          keys[self.class.name][reflection.primary_key_name] = reflection.class_name
        end
      end


      # Chargement des données sauvegardées
      puts "R> Loading backup data..."
      data = []
      for table in root.elements
        reflection = self.class.reflections[table.attributes['reflection'].to_sym]
        puts('>> '+reflection.name.to_s)
        for r in table.elements
          attributes = r.attributes
          id = attributes['id']
          attributes.delete('id')
          attributes.delete('company_id')
          record = self.send(reflection.name).build
          attributes.each{|k,v| record.send(k+'=', v)}
          record.send(:create_without_callbacks)
          ids[reflection.class_name][id] = record.id
          data << record
        end
      end


      # Réorganisation des clés étrangères
      puts "R> Redifining primary keys..."
      for record in data
        for key, class_name in keys[record.class.name]
          # user[:role_id] = ids["Role"][user[:role_id].to_s]
          #raise Exception.new('>> '+class_name.inspect) if ids[class_name].nil?
          if record[key]
            v = ids[class_name.is_a?(Symbol) ? record[class_name] : class_name][record[key].to_s]
            #             if class_name.is_a? Symbol
            #               v = ids[record[class_name]][record[key].to_s]
            #             else
            #               v = ids[class_name][record[key].to_s]
            #             end
            record[key] = v unless v.nil?
          end
        end
        record.send(:update_without_callbacks)
      end
      
      

      # Chargement des paramètres de la société
      puts "R> Loading company data..."
      attrs = root.attributes
      attrs.delete('id')
      attrs.delete('lock_version') # StaleObjectError solution
      attrs.delete('code')
      attrs.each{|k,v| self.send(k+'=', v)}
      for key, class_name in keys[self.class.name]
        v = ids[class_name][self[key].to_s]
        self[key] = v unless v.nil?
      end
      #      while self.class.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
      #        self.code.succ!
      #      end
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
    archive  = options[:archive]
    template = options[:template]
    if object.class.ancestors.include?(ActiveRecord::Base)
      template ||= object.class.name.underscore.to_sym
      archive = true if archive.nil?
    else
      raise Exception.new("The parameter object must be an ActiveRecord::Base descendant object")
    end

    # Try to find an existing archive
    pdf = nil
    document = nil
    if archive
      documents = self.documents.find_all_by_owner_id_and_owner_type(object.id, object.class.name)
      if documents.size == 1
        document = documents.first
        pdf = document.data
      elsif documents.size > 1
        raise Exception.new("Many archives are existing for one record")
      end
    end

    # Printing
    # TODO: Cache printing method
    if pdf.nil?
      source = ''
      template_file = "#{RAILS_ROOT}/app/views/prints/#{template}.rpdf"
      raise Exception.new("Unfound template: #{template_file}") unless File.exist? template_file
      File.open(template_file, 'rb') do |file|
        source = file.read
      end
      doc = Ibeh.document(Hebi::Document.new, options[:view]) do
        eval(source)
      end
      pdf = doc.generate
      #pdf = source
    end
    
    # Create the archive
    if archive and document.nil?
      document = Document.archive(object, pdf, :template=>template.to_s, :extension=>'pdf')
    end
    
    # Return the doc
    return document||pdf
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



  def import_entities
    
  end



end
