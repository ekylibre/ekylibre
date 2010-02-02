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
#  code             :string(8)        not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  deleted          :boolean          not null
#  entity_id        :integer          
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  locked           :boolean          not null
#  name             :string(255)      not null
#  sales_conditions :text             
#  updated_at       :datetime         not null
#  updater_id       :integer          
#

# -*- coding: utf-8 -*-
class Company < ActiveRecord::Base
  has_many :accounts
  has_many :account_balances
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
  has_many :locations
  has_many :mandates
  has_many :observations
  has_many :operation_natures
  has_many :operations
  has_many :operation_lines
  has_many :parameters
  has_many :payments
  has_many :payment_modes
  has_many :payment_parts
  has_many :prices
  has_many :price_taxes
  has_many :products
  has_many :product_components
  has_many :professions
  has_many :purchase_orders
  has_many :purchase_order_lines
  has_many :roles
  has_many :sale_orders
  has_many :sale_order_lines
  has_many :sale_order_natures
  has_many :sequences
  has_many :shapes, :order=>:name
  has_many :shelves
  has_many :stocks
  has_many :stock_moves
  has_many :stock_transfers
  has_many :subscription_natures
  has_many :subscriptions
  has_many :taxes
  has_many :tax_declarations
  has_many :tool_uses
  has_many :tools
  has_many :trackings
  has_many :transfers
  has_many :units
  has_many :users
  belongs_to :entity


  # Specifics
  has_many :employees, :class_name=>User.name, :conditions=>{:employed=>true}
  has_many :productable_products, :class_name=>Product.name, :conditions=>{:to_produce=>true}
  has_many :embankable_payments, :class_name=>Payment.name, :conditions=>{:embankment_id=>nil}

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




  def account(tax_amount, tax_name, collected)
    if collected
      if tax_amount == 0.0210
        account = self.accounts.find_by_number("445711") || self.accounts.create!(:number=>"445711", :name=>tax_name) 
      elsif tax_amount == 0.0550
        account = self.accounts.find_by_number("445712") || self.accounts.create!(:number=>"445712", :name=>tax_name) 
      elsif tax_amount == 0.1960
        account = self.accounts.find_by_number("445713") || self.accounts.create!(:number=>"445713", :name=>tax_name)
      else
        tax = Tax.find(:first, :conditions=>["company_id = ? and amount = ? and account_collected_id IS NOT NULL", self.id, tax_amount])
        last = self.accounts.find(:first, :conditions=>["number like ?",'4457%'], :order=>"created_at desc")||self.accounts.create!(:number=>4457, :name=>tc(:taxes))
        account = tax.nil? ? Account.create!(:company_id=>self.id, :number=>last.number.succ, :name=>tax_name) : tax.account 
      end
    else
      account = self.accounts.find_by_number("44566") || self.accounts.create!(:number=>"44566", :name=>tc(:paid_taxes))
    end
    account.id
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

  def available_products(options={})
    options[:conditions] ||= {}
    options[:conditions].merge!(:active=>true)
    options[:order] ||= 'name'
    self.products.find(:all, options)
  end

  def available_prices(category_id=nil)
    #conditions = ["entity_id=? AND p.active AND prices.active", self.entity_id]
    conditions = {:entity_id=>self.entity_id, "p.active"=>true, "prices.active"=>true}
    if category_id
      conditions[:category_id] = category_id
      #conditions[0] += " AND category_id=?"
      #conditions << category_id
    end
    self.prices.find(:all, :joins=>"JOIN products AS p ON (p.id=product_id)", :conditions=>conditions, :order=>"p.name, prices.amount")
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
      nature = EntityCategory.create!(:name=>row, :default=>false, :company_id=>self.id) if nature.nil? 
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

  #def usable_payments
  # self.payments.find(:all, :conditions=>["COALESCE(parts_amount,0)<COALESCE(amount,0)"], :order=>"created_at desc")
  #end

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
      models = EKYLIBRE_MODELS # .delete_if{|x| x==:company}
      for model in models
        other_class = model.to_s.classify.constantize
        other_class.delete_all(:company_id=>self.id) if other_class != self.class
      end


      # Chargement des données sauvegardées
      puts "R> Loading backup data..."
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
        code += "puts('R> - #{model.name} (#{element[:attributes]['records-count']})')\n"
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
          code += "puts 'R>     T: '+duration.to_s[0..6]+' | TDB1: '+tdb1.to_s[0..6]+' | TDB2: '+tdb2.to_s[0..6]+' | RS: '+(duration-tdb2p).to_s[0..6]+' | AVG(TDB1): '+(tdb1/#{element[:attributes]['records-count']}).to_s[0..6]+' | AVG(TDB2): '+(tdb2/#{element[:attributes]['records-count']}).to_s[0..6]\n"
        end
      end
      File.open("/tmp/restore-1.rb", "wb") {|f| f.write(code)}
      eval(code)
      
      # raise Exception.new(data.inspect)
      # Réorganisation des clés étrangères
      puts "R> Redifining primary keys..."
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

      File.open("/tmp/restore-2.rb", "wb") {|f| f.write(code)}      
      start = Time.now
      eval(code)
      puts "R> Total: #{(Time.now-start)}s"



      # Chargement des paramètres de la société
      puts "R> Loading company data..."
      attrs = root.attributes.each do |attr|
        self.send(attr.name+'=', attr.value) unless ['id', 'lock_version', 'code'].include? attr.name
      end
      for key, target in EKYLIBRE_REFERENCES[self.class.name.underscore.to_sym]
        v = ids[target.to_s.classify][self[key].to_s]
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

  #
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
    elsif options[:nature]
      template = self.document_templates.find_by_code(options[:nature]) if options[:nature].is_a? String
      #raise Exception.new "ok "+template.inspect+options[:nature].inspect
    else
      template = self.document_templates.find_by_nature_and_default(object.class.to_s.underscore, true)
    end
    #raise Exception.new "ok "+template.inspect+" mmmm "+options[:nature].inspect
    return DocumentTemplate.error_document("Can't find any template to print") unless template
    # Printing
    # TODO: Cache printing method
    # raise Exception.new template.inspect+':'+options.size.to_s
    #args=[]
    #args << object
    #if options
    #  args << options 
    #raise Exception.new 'v:'+args.inspect
    #end
    
    return template.print(object)
  end


  def export_entities(find_options={})
    entities = self.entities.find(:all, find_options)
    csv_string = FasterCSV.generate do |csv|
      csv << ["Code", "Type", "Catégorie", "Nom", "Prénom", "Dest-Service", "Bat.-Res.-ZI", "N° et voie", "Lieu dit", "Code Postal", "Ville", "Téléphone", "Mobile", "Fax", "Email", "Site Web", "Taux de réduction", "Commentaire"]
      entities.each do |entity|
        contact = self.contacts.find(:first, :conditions=>{:entity_id=>entity.id, :default=>true, :deleted=>false})
        line = []
        line << ["'"+entity.code, entity.nature.name, entity.category.name,entity.name, entity.first_name]
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
  








  def self.create_with_data(company_attr=nil, user_attr=nil, demo_language_code=nil)
    company = Company.new(company_attr)
    user = User.new(user_attr)

    ActiveRecord::Base.transaction do
      company.save!
      language = company.languages.create!(:name=>'Français', :native_name=>'Français', :iso2=>'fr', :iso3=>'fra')
      company.roles.create!(:name=>tc('default.role.name.admin'),  :rights=>User.rights_list.join(' '))
      company.roles.create!(:name=>tc('default.role.name.public'), :rights=>'')
      user.company_id = company.id
      user.role_id = company.admin_role.id
      user.save!
      tc('mini_accounting_system').to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}.each do |a|
        begin
          account = company.accounts.find_by_number(a[0].to_s)
          if account 
            account.update_attributes!(:name=>a[1])
          else
            company.accounts.create!(:number=>a[0].to_s, :name=>a[1])
          end
        rescue Exception
          
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
      
      taxes = []
      taxes = {:name=>tc('default.tva000'),  :nature=>'percent', :amount=>0.00}, {:name=>tc('default.tva210'), :nature=>'percent', :amount=>0.021}, {:name=>tc('default.tva550'), :nature=>'percent', :amount=>0.055}, {:name=>tc('default.tva1960'),:nature=>'percent', :amount=>0.196} 
      taxes.each do |tax|
        company.taxes.create!(:name=>tax[:name], :nature=>tax[:nature], :amount=>tax[:amount], :account_collected_id=>company.account(tax[:amount],tax[:name],true), :account_paid_id=>company.account(tax[:amount], tax[:name],false) )
      end
      
      company.entity_natures.create!(:name=>'Monsieur', :abbreviation=>'M', :physical=>true)
      company.entity_natures.create!(:name=>'Madame', :abbreviation=>'Mme', :physical=>true)
      company.entity_natures.create!(:name=>'Société Anonyme', :abbreviation=>'SA', :physical=>false)
      undefined_nature = company.entity_natures.create!(:name=>'Indéfini',:abbreviation=>'-', :in_name=>false, :physical=>false)
      category = company.entity_categories.create!(:name=>tc('default.category'))
      firm = company.entities.create!(:category_id=> category.id, :nature_id=>undefined_nature.id, :language_id=>language.id, :name=>company.name)
      company.reload
      company.entity_id = firm.id
      company.save!
      company.entity.contacts.create!(:company_id=>company.id, :line_2=>"", :line_3=>"", :line_5=>"", :line_6=>'12345 MAVILLE', :default=>true)
      
      # loading of all the templates
      company.load_prints
      
      company.payment_modes.create!(:name=>tc('default.check'), :company_id=>company.id)
      delays = []
      ['expiration', 'standard', 'immediate'].each do |d|
        delays << company.delays.create!(:name=>tc('default.delays.name.'+d), :expression=>tc('default.delays.expression.'+d), :active=>true)
      end
      company.financialyears.create!(:started_on=>Date.today)
      company.sale_order_natures.create!(:name=>tc('default.sale_order_nature_name'), :expiration_id=>delays[0].id, :payment_delay_id=>delays[2].id, :downpayment=>false, :downpayment_minimum=>300, :downpayment_rate=>0.3)
      
      company.set_parameter('accountancy.default_journals.sales', company.journals.create!(:name=>tc('default.journals.sales'), :nature=>"sale", :currency_id=>currency.id))
      company.set_parameter('accountancy.default_journals.purchases', company.journals.create!(:name=>tc('default.journals.purchases'), :nature=>"purchase", :currency_id=>currency.id))
      company.set_parameter('accountancy.default_journals.bank', company.journals.create!(:name=>tc('default.journals.bank'), :nature=>"bank", :currency_id=>currency.id))

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
    prints_dir = "#{RAILS_ROOT}/app/views/prints"
    
    families = {}
    families[:management] = {'sale_order'=>{:to_archive=>false, :nature=>'sale_order', :filename=>I18n::t('models.company.default.document_templates_filenames.sale_order')}, 'invoice'=>{:to_archive=>true, :nature=>'invoice', :filename=>I18n::t('models.company.default.document_templates_filenames.invoice')}, 'inventory'=>{:to_archive=>false, :nature=>'inventory', :filename=>I18n::t('models.company.default.document_templates_filenames.inventory')}, 'transport'=>{:to_archive=>false, :nature=>'transport', :filename=>I18n::t('models.company.default.document_templates_filenames.transport')}, 'embankment'=>{:to_archive=>false, :nature=>'embankment', :filename=>I18n::t('models.company.default.document_templates_filenames.embankment')}, 'purchase_order'=>{:to_archive=>false, :nature=>'purchase_order', :filename=>I18n::t('models.company.default.document_templates_filenames.purchase_order')} }#, 'order_preparation'=>{:to_archive=>false, :nature=>'transport', :filename=>I18n::t('models.company.default.document_templates_filenames.order_preparation')}   }
    families[:relations] = {'entity'=>{:to_archive=>false, :nature=>'entity', :filename=>I18n::t('models.company.default.document_templates_filenames.entity')}}
    #families[:accountancy] = {'balance_sheet'=>{:to_archive=>false, :nature=>'balance_sheet', :filename=>I18n::t('models.company.default.document_templates_filenames.other')}}#, 'journal_by_id'=>{:to_archive=>false, :nature=>'other', :filename=>I18n::t('models.company.default.document_templates_filenames.other')}}
    families[:accountancy] = {'balance_sheet'=>{:to_archive=>false, :nature=>'financialyear', :filename=>I18n::t('models.company.default.document_templates_filenames.balance_sheet')}, 'income_statement'=>{:to_archive=>false, :nature=>'financialyear', :filename=>I18n::t('models.company.default.document_templates_filenames.income_statement') }}
    
    families.each do |family, templates|
      templates.each do |template, options|
        File.open("#{prints_dir}/#{template}.xml", 'rb') do |f|
          self.document_templates.create(:active=>true, :name=>I18n::t('models.company.default.document_templates.'+template.to_s), :language_id=>language.id, :country=>'fr', :source=>f.read, :to_archive=>options[:to_archive], :family=>family.to_s, :code=>I18n::t('models.company.default.document_templates.'+template).codeize[0..7], :nature=>options[:nature], :filename=>options[:filename], :default=>false )
        end
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
  
  def import_entities
  end

#   def self.load_demo_data(locale="fr-FR", company=nil)
#     company.load_demo_data(company) if company
#   end
  
  def load_demo_data(language_code=nil)
    self.entity_natures.create!(:name=>"Société A Responsabilité Limitée", :abbreviation=>"SARL", :in_name=>true)
    last_name = ["MARTIN", "DUPONT", "DURAND", "LABAT", "VILLENEUVE", "SICARD", "FRERET", "FOUCAULT", "DUPEYRON", "BORGÈS", "DUBOIS", "LEROY", "MOREL", "GUERIN", "MORIN", "ROUSSEAU", "LEMAIRE", "DUVAL", "BRUN", "FERNANDEZ", "BRETON", "LEBLANC", "DA SILVA", "CORDIER", "BRIAND", "CAMUS", "VOISIN", "LELIEVRE", "GONZALEZ"]
    first_name = ["Benoît", "Stéphane", "Marine", "Roger", "Céline", "Bertrand", "Camille", "Dominique", "Julie", "Kévin", "Maxime", "Vincent", "Claire", "Marie-France", "Jean-Marie", "Anne-Marie", "Dominique", "Hakim", "Alain", "Daniel", "Sylvie", "Fabrice", "Nathalie", "Véronique", "Jeanine", "Edouard", "Colette", "Sébastien", "Rémi", "Joseph", "Baptiste", "Manuel", "Sofia", "Indira", "Martine", "Guy"]
    streets = ["Cours Xavier Arnozan", "Cours du général de Gaulle", "Route pavée", "Avenue Thiers", "Rue Gambetta", "5th Avenue", "rue Louis La Brocante", "Rue Léon Blum", "Avenue des Champs Élysées", "Cours de la marne"]
    cities = ["33000 Bordeaux", "33170 Gradignan", "40600 Biscarosse", "33400 Talence", "75001 Paris", "13000 Marseille", "33600 Pessac", "47000 Agen", "33710 Pugnac", "33700 Mérignac", "40000 Mont de Marsan"]
    entity_natures = self.entity_natures.collect{|x| x.id.to_s}
    indifferent_attributes = {:category_id=>self.entity_categories.first.id, :language_id=>self.languages.first.id}
    products = ["Salades","Bouteille en verre 75 cl","Bouchon liège","Capsule CRD", "Capsule", "Étiquette", "Vin Quillet-Bont 2005", "Caisse Bois 6 btles", "Bouteille Quillet-Bont 2005 75 cl", "Caisse 6 b. Quillet-Bont 2005", "patates", "Séjour 1 nuit", "Séjour 1 semaine 1/2 pension", "Fongicide", "Insecticide"]
    shelf_id = self.shelves.first.id
    category_id = self.entity_categories.first.id
    
    for x in 0..60
      entity = self.entities.new(indifferent_attributes)
      entity.name = last_name[rand(last_name.size)]
      entity.first_name = first_name[rand(first_name.size)] if 
        entity.nature_id = entity_natures[rand(entity_natures.size).to_i]
      entity.name = entity.nature.abbreviation+" "+entity.name if entity.nature.in_name 
      entity.client = (rand() > 0.5 or rand() > 0.8)
      entity.supplier = (rand() > 0.75 or x == 0)
      entity.transporter = rand() > 0.9
      entity.first_name = '' unless entity.nature.physical
      entity.save! 
      contact = entity.contacts.create!(:company_id=>self.id, :line_4=>rand(100).to_s+" "+streets[rand(streets.size)], :line_6=>cities[rand(cities.size)], :default=>true)
    end
    self.entity_link_natures.create!(:name=>"Gérant - Société", :name_1_to_2=>"gère la société", :name_2_to_1=>"est une société qui a pour associé", :propagate_contacts=>true, :symmetric=>false)
    self.subscription_natures.create!(:name=>"Abonnement annuel", :nature=>"period", :reduction_rate=>0.1)
    self.event_natures.create!(:name=>"Conversation téléphonique", :duration=>10, :usage=>"manual")
    
    # charge_account  = self.accounts.find_by_number("60")
    product_account = self.accounts.find_by_number("7")
    units = self.units.find(:all, :conditions=>"base IS NULL OR base in ('', 'kg', 'm3')")
    for product_name in products
      product = self.products.create!(:nature=>"product", :name=>product_name, :to_sale=>true, :to_produce=>true, :shelf_id=>shelf_id, :unit_id=>units.rand.id, :manage_stocks=>true, :weight=>rand(3), :product_account_id=>product_account.id)
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
      result =  self.entries.sum(field, :conditions=>conditions, :joins=>"inner join accounts a on a.id=entries.account_id inner join journal_records r on r.id=entries.record_id")
    end

    if [:all, :first].include? field
      result =  self.entries.find(field, :conditions=>conditions, :joins=>"inner join accounts a on a.id=entries.account_id inner join journal_records r on r.id=entries.record_id", :order=>"r.created_on ASC")
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
    return self.entries.find(:all, :conditions=>conditions, :joins=>"inner join journal_records r on r.id=entries.record_id", :order=>"r.number ASC")
  end

end
