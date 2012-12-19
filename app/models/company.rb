# -*- coding: utf-8 -*-

# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
#  code :string(16)       not null
#  id   :integer          not null, primary key
#  log  :text
#


class Company < ActiveRecord::Base
  # include Ekylibre::Record::Preference

  # has_many :accounts, :order=>:number
  # has_many :account_balances
  # has_many :areas
  # has_many :assets
  # has_many :asset_depreciations
  # has_many :cashes, :order=>:name
  # has_many :cash_transfers
  # has_many :bank_statements
  # has_many :contacts
  # has_many :custom_fields
  # has_many :custom_field_choices
  # has_many :custom_field_data
  # has_many :delays
  # has_many :departments
  # has_many :deposits
  # has_many :districts
  # has_many :documents
  # has_many :document_templates
  # has_many :entities
  # has_many :entity_categories
  # has_many :entity_link_natures
  # has_many :entity_links
  # has_many :entity_natures
  # has_many :establishments
  # has_many :event_natures, :order=>"name"
  # has_many :events
  # has_many :financial_years, :order=>"started_on DESC"
  # has_many :incoming_deliveries
  # has_many :incoming_delivery_lines
  # has_many :incoming_delivery_modes
  # has_many :incoming_payments
  # has_many :incoming_payment_modes, :order=>:name
  # has_many :incoming_payment_uses
  # has_many :inventories
  # has_many :inventory_lines
  # has_many :journals, :order=>:name
  # has_many :journal_entries
  # has_many :journal_entry_lines
  # has_many :land_parcels, :order=>:name
  # has_many :land_parcel_groups, :order=>:name
  # has_many :land_parcel_kinships
  # has_many :listings
  # has_many :listing_nodes
  # has_many :listing_node_items
  # has_many :mandates
  # has_many :observations
  # has_many :operation_natures, :order=>:name
  # has_many :operations
  # has_many :operation_lines
  # has_many :operation_uses
  # has_many :outgoing_deliveries
  # has_many :outgoing_delivery_lines
  # has_many :outgoing_delivery_modes
  # has_many :outgoing_payments
  # has_many :outgoing_payment_modes, :order=>:name
  # has_many :outgoing_payment_uses
  # has_many :preferences, :conditions=>{:user_id=>nil}, :order=>:name
  # has_many :prices
  # has_many :products, :order=>'active DESC, name'
  # has_many :product_categories, :order=>:name
  # has_many :product_components
  # has_many :production_chains
  # has_many :production_chain_work_centers, :order=>:name
  # has_many :production_chain_work_center_lines
  # has_many :production_chain_work_center_uses
  # has_many :professions
  # has_many :purchases
  # has_many :purchase_lines
  # has_many :purchase_natures
  # has_many :roles
  # has_many :sales
  # has_many :sale_lines
  # has_many :sale_natures
  # has_many :sequences
  # has_many :stocks, :order=>"warehouse_id, product_id, tracking_id"
  # has_many :stock_moves
  # has_many :stock_transfers
  # has_many :subscription_natures, :order=>:name
  # has_many :subscriptions
  # has_many :taxes, :order=>'amount'
  # has_many :tax_declarations
  # has_many :tools, :order=>:name
  # has_many :trackings
  # has_many :transfers
  # has_many :transports
  # has_many :units, :order=>'base, coefficient, name'
  # has_many :users, :order=>'last_name, first_name'
  # has_many :warehouses

  # # Sequences
  # # preference :assets_sequence, 'Sequence'
  # # preference :cash_transfers_sequence, 'Sequence'
  # # preference :deposits_sequence, 'Sequence'
  # # preference :entities_sequence, 'Sequence'
  # # preference :incoming_deliveries_sequence, 'Sequence'
  # # preference :incoming_payments_sequence, 'Sequence'
  # # preference :outgoing_deliveries_sequence, 'Sequence'
  # # preference :outgoing_payments_sequence, 'Sequence'
  # # preference :purchases_sequence, 'Sequence'
  # # preference :sales_invoices_sequence, 'Sequence'
  # # preference :sales_sequence, 'Sequence'
  # # preference :stock_transfers_sequence, 'Sequence'
  # # preference :subscriptions_sequence, 'Sequence'
  # # preference :transports_sequence, 'Sequence'
  # # Behaviours
  # preference :bookkeep_automatically, 'Boolean', :default=>true
  # preference :bookkeep_in_draft, 'Boolean', :default=>true
  # # preference :detail_payments_in_deposit_bookkeeping, 'Boolean', :default=>true
  # preference :use_entity_codes_for_account_numbers, 'Boolean', :default=>true
  # # Journals
  # # preference :bank_journal, 'Journal'
  # # preference :cash_journal, 'Journal'
  # # preference :forward_journal, 'Journal'
  # # preference :purchases_journal, 'Journal'
  # # preference :sales_journal, 'Journal'
  # # preference :various_journal, 'Journal'
  # # Accounts
  # # preference :capital_gains_accounts, 'Integer', :default=>120
  # # preference :capital_losses_accounts, 'Integer', :default=>129
  # # preference :charges_accounts, 'Integer', :default=>6
  # # preference :financial_banks_accounts, 'Integer', :default=>51
  # # preference :financial_cashes_accounts, 'Integer', :default=>53
  # # preference :financial_internal_transfers_accounts, 'Integer', :default=>58
  # # preference :financial_payments_to_deposit_accounts, 'Integer', :default=>511
  # # preference :products_accounts, 'Integer', :default=>7
  # # preference :taxes_acquisition_accounts, 'Integer', :default=>4452
  # # preference :taxes_assimilated_accounts, 'Integer', :default=>447
  # # preference :taxes_balance_accounts, 'Integer', :default=>44567
  # # preference :taxes_payback_accounts, 'Integer', :default=>44583
  # # preference :taxes_collected_accounts, 'Integer', :default=>4457
  # # preference :taxes_paid_accounts, 'Integer', :default=>4456
  # # preference :third_attorneys_accounts, 'Integer', :default=>467
  # # preference :third_clients_accounts, 'Integer', :default=>411
  # # preference :third_suppliers_accounts, 'Integer', :default=>401


  def self.conditions_proc(string)
    if Rails.version.match(/^3\./)
      eval('proc{"'+string.gsub('"', '\\"')+'"}')
    else
      string
    end
  end

  # Specifics
  ### has_many :attorney_accounts, :class_name=>"Account", :order=>:number, :conditions=>conditions_proc('number LIKE #{connection.quote(self.preferred_third_attorneys_accounts.to_s+\'%\')}')
  has_many :available_prices, :class_name=>"Price", :conditions=>conditions_proc('prices.entity_id=#{self.entity_id} AND prices.active=#{connection.quoted_true} AND product_id IN (SELECT id FROM #{Product.table_name} WHERE company_id=#{id} AND active=#{connection.quoted_true})'), :order=>"prices.amount"
  ### has_many :available_products, :class_name=>"Product", :conditions=>{:active=>true}, :order=>:name
  has_many :bank_journals, :class_name=>"Journal", :order=>:code, :conditions=>conditions_proc('nature LIKE \'bank\'')
  has_many :banks_accounts, :class_name=>"Account", :order=>:number, :conditions=>conditions_proc('number LIKE #{connection.quote(self.preferred_financial_banks_accounts.to_s+\'%\')}')
  has_many :buildings, :class_name=>"Warehouse", :conditions=>{:reservoir=>false}, :order=>:name
  has_many :cash_journals, :class_name=>"Journal", :order=>:code, :conditions=>conditions_proc('nature LIKE \'cash\'')
  has_many :cashes_accounts, :class_name=>"Account", :order=>:number, :conditions=>conditions_proc('number LIKE #{connection.quote(self.preferred_financial_cashes_accounts.to_s+\'%\')}')
  has_many :charges_accounts, :class_name=>"Account", :order=>:number, :conditions=>conditions_proc('number LIKE #{connection.quote(self.preferred_charges_accounts.to_s+\'%\')}')
  has_many :choice_custom_fields, :class_name=>"CustomField", :conditions=>{:nature=>"choice"}, :order=>"name"
  ### has_many :client_accounts, :class_name=>"Account", :order=>:number, :conditions=>conditions_proc('number LIKE #{connection.quote(self.preferred_third_clients_accounts.to_s+\'%\')}')
  ### has_many :critic_stocks, :class_name=>"Stock", :conditions=>['virtual_quantity <= quantity_min AND NOT (virtual_quantity=0 AND quantity=0 AND tracking_id IS NOT NULL)']
  has_many :employees, :class_name=>"Entity", :conditions=>{:employed=>true}, :order=>'last_name, first_name'
  ### has_many :depositable_payments, :class_name=>"IncomingPayment", :conditions=>conditions_proc('deposit_id IS NULL AND mode_id IN (SELECT id FROM #{IncomingPaymentMode.table_name} WHERE company_id=#{id} AND with_deposit=#{connection.quoted_true})')
  ### has_many :major_accounts, :class_name=>"Account", :conditions=>["number LIKE '_'"], :order=>"number"
  ### has_many :payments_to_deposit, :class_name=>"IncomingPayment", :order=>"created_on", :conditions=>conditions_proc('deposit_id IS NULL AND mode_id IN (SELECT id FROM #{IncomingPaymentMode.table_name} WHERE company_id=#{id} AND with_deposit=#{connection.quoted_true}) AND to_bank_on >= #{connection.quote(Date.today-14)}')
  has_many :payments_to_deposit_accounts, :class_name=>"Account", :order=>:number, :conditions=>conditions_proc('number LIKE #{connection.quote(self.preferred_financial_payments_to_deposit_accounts.to_s+\'%\')}')
  has_many :productable_products, :class_name=>"Product", :conditions=>{:to_produce=>true}
  has_many :products_accounts, :class_name=>"Account", :order=>:number, :conditions=>conditions_proc('number LIKE #{connection.quote(self.preferred_products_accounts.to_s+\'%\')}')
  has_many :self_cashes, :class_name=>"Cash", :order=>:name, :conditions=>conditions_proc('entity_id=#{self.entity_id}')
  ### has_many :self_bank_accounts, :class_name=>"Cash", :order=>:name, :conditions=>conditions_proc('(entity_id IS NULL OR entity_id=#{self.entity_id}) AND nature=\'bank_account\'')
  has_many :self_contacts, :class_name=>"Contact", :conditions=>conditions_proc('deleted_at IS NULL AND entity_id = #{self.entity_id}'), :order=>'address'
  ### has_many :stockable_products, :class_name=>"Product", :conditions=>{:stockable=>true}
  ### has_many :supplier_accounts, :class_name=>"Account", :order=>:number, :conditions=>conditions_proc('number LIKE #{connection.quote(self.preferred_third_suppliers_accounts.to_s+\'%\')}')
  has_many :suppliers, :class_name=>"Entity", :conditions=>{:supplier=>true}, :order=>'active DESC, last_name, first_name'
  has_many :surface_units, :class_name=>"Unit", :conditions=>{:base=>"m2"}, :order=>'coefficient, name'
  has_many :transporters, :class_name=>"Entity", :conditions=>{:transporter=>true}, :order=>'active DESC, last_name, first_name'
  ### has_many :unconfirmed_stock_transfers, :class_name=>"StockTransfer", :conditions=>{:moved_on=>nil}
  ### has_many :undelivered_incoming_deliveries, :class_name=>"IncomingDelivery", :conditions=>{:moved_on=>nil}
  ### has_many :undelivered_outgoing_deliveries, :class_name=>"OutgoingDelivery", :conditions=>{:moved_on=>nil}
  has_many :unpaid_responsibles, :class_name=>"Entity", :conditions=>conditions_proc('id in (SELECT responsible_id FROM #{Sale.table_name} WHERE company_id=#{id} AND state IN (\'order\', \'invoice\') AND paid_amount < amount AND lost = #{connection.quoted_false})')
  ### has_many :untransportered_deliveries, :class_name=>"OutgoingDelivery", :conditions=>{:moved_on=>nil, :transporter_id=>nil} # without_transporter
  has_many :usable_incoming_payments, :class_name=>"IncomingPayment", :conditions=>conditions_proc('used_amount < amount'), :order=>'amount'
  has_many :usable_outgoing_payments, :class_name=>"OutgoingPayment", :conditions=>conditions_proc('used_amount < amount'), :order=>'amount'
  ### has_many :waiting_transporters, :class_name=>"Entity", :conditions=>["id IN (SELECT transporter_id FROM #{OutgoingDelivery.table_name} WHERE (moved_on IS NULL AND planned_on <= CURRENT_DATE) OR transport_id IS NULL)"]

  has_one :first_financial_year, :class_name => "FinancialYear", :order => "started_on"
  has_one :current_financial_year, :class_name=>"FinancialYear", :conditions=>{:closed => false}, :order => "ABS(CURRENT_DATE - started_on) DESC"
  has_one :closable_financial_year, :class_name=>"FinancialYear", :conditions=>["closed = ? AND stopped_on < CURRENT_DATE", false], :order => "started_on"

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :code, :allow_nil => true, :maximum => 16
  validates_presence_of :code
  #]VALIDATORS]
  validates_uniqueness_of :code
  validates_length_of :code, :in => 4..16
  # validates_presence_of :currency

  attr_readonly :code

  before_validation do
    if self.code.blank?
      self.code = self.name.to_s[0..7].simpleize
      self.code = rand.to_s[2..-1].to_i.to_s(36)[0..7] if self.code.blank?
      self.code = self.code.simpleize.upper
      while Company.count(:conditions=>["code=? AND id!=?",self.code, self.id])>0 do
        self.code.succ!
      end
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

  def to_param
    self.code
  end

  def account(number, name=nil)
    number = number.to_s
    a = self.accounts.find_by_number(number)
    return a||self.accounts.create!(:number=>number, :name=>name||number.to_s)
  end


  def preference(name)
    preference = self.preferences.find_by_name(name)
    if preference.nil? and ref = self.class.preferences_reference[name.to_s]
      preference = self.preferences.new(:name=>name, :nature=>ref[:nature], :record_value_type=>ref[:record_value_type])
      preference.value = ref[:default]
      preference.save!
    end
    preference
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


  def available_taxes(options={})
    #    options[:conditions]={:deleted=>false}
    self.taxes.find(:all, options)
  end


  def available_users(options={})
    self.users.find(:all, :order=>:last_name, :conditions=>{:locked=>false})
  end

  # def financial_year_at(searched_on=Date.today)
  #   year = self.financial_years.where("? BETWEEN started_on AND stopped_on", searched_on).order("started_on DESC").first
  #   unless year
  #     # First
  #     first = self.first_financial_year
  #     unless first
  #       started_on = Date.today
  #       first = self.financial_years.create(:started_on => started_on, :stopped_on => (started_on >> 12).end_of_month)
  #     end
  #     return nil if first.started_on > searched_on

  #     # Next years
  #     other = first
  #     while searched_on > other.stopped_on
  #       other = other.find_or_create_next
  #     end
  #     return other
  #   end
  #   return year
  # end

  # Return the default currency
  def default_currency
    self.currency # || 'EUR'
  end

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


  # def reflection_options(options={})
  #   raise ArgumentError.new("Need :reflection option (#{options.inspect})") unless options[:reflection].to_s.size > 0
  #   reflection = self.class.reflections[options[:reflection].to_sym]
  #   raise ArgumentError.new("Unknown :reflection option with an existing reflection (#{options[:reflection].inspect})") unless reflection
  #   model = reflection.class_name.constantize
  #   available_methods = (model.instance_methods+model.columns_hash.keys).collect{|x| x.to_s}
  #   unless label = options[:label]
  #     label = [:label, :native_name, :name, :code, :number, :inspect].detect{|x| available_methods.include?(x.to_s)}
  #     raise ArgumentError.new(":label option is needed (#{model.name}(#{available_methods.inspect}):#{options.inspect})") if label.nil?
  #   end
  #   find_options = {} # :conditions=>"true"}
  #   if options[:order]
  #     find_options[:order] = options[:order]
  #   elsif model.columns_hash.keys.include?(options[:label].to_s)
  #     find_options[:order] = options[:label]
  #   end
  #   find_options[:conditions] = options[:conditions] if options[:conditions]
  #   list = (self.send(reflection.name).find(:all, find_options)||[]).collect do |record|
  #     [record.send(label), record.id]
  #   end
  #   if options[:include_blank].is_a? String
  #     list.insert(0, [options[:include_blank], ''])
  #   elsif options[:include_blank].is_a? Array
  #     list.insert(0, *options[:include_blank])
  #   end
  #   return list
  # end


  def deposits_to_lock
    deposits = []
    for deposit in self.deposits
      deposits << deposit if ( deposit.locked == false and deposit.created_on <= Date.today-(15) )
    end
    deposits
  end

  def default_contact
    self.entity.default_contact
  end

  # Returns the default journal from preferences
  # Creates the journal if not exists
  def journal(name)
    name = name.to_s
    pref_name  = "#{name}_journal"
    raise ArgumentError.new("Unvalid journal name: #{name.inspect}") unless self.class.preferences_reference.has_key? pref_name
    unless journal = self.preferred(pref_name)
      journal = self.journals.find_by_nature(name)
      journal = self.journals.create!(:name=>tc("default.journals.#{name}"), :nature=>name, :currency=>self.default_currency) unless journal
      self.prefer!(pref_name, journal)
    end
    return journal
  end



  def private_directory
    File.join(Ekylibre.private_directory, self.code)
  end


  def backup(options={})
    creator, with_files = options[:creator], options[:with_prints]
    version = (ActiveRecord::Migrator.current_version rescue 0)
    temporary_dir = Rails.root.join("tmp", "backups")
    FileUtils.mkdir_p(temporary_dir)
    file = temporary_dir.join("backup-#{self.code.lower}-#{Time.now.strftime('%Y%m%d-%H%M%S')}.zip")
    doc = LibXML::XML::Document.new
    doc.root = backup = LibXML::XML::Node.new('backup')
    {'version'=>version, 'creation-date'=>Date.today, 'creator'=>creator}.each{|k,v| backup[k]=v.to_s}
    backup << root = LibXML::XML::Node.new('company')
    self.attributes.each{|k,v| root[k] = v.to_s}
    n = 0
    start = Time.now.to_i
    models = Ekylibre.models.delete_if{|x| x==:company}
    for model in models
      rows = model.to_s.classify.constantize.find(:all, :conditions=>{:company_id=>self.id}, :order=>:id)
      rows_count = rows.size
      n += rows_count
      root << table = LibXML::XML::Node.new('rows')
      {'model'=>model.to_s, 'records-count'=>rows_count.to_s}.each{|k,v| table[k]=v}
      rows_count.times do |i|
        table << row = LibXML::XML::Node.new('row')
        rows[i].attributes.each{|k,v| row[k] = v.to_s}
      end
    end
    # backup.add_attributes('records-count'=>n.to_s, 'generation-duration'=>(Time.now.to_i-start).to_s)
    stream = doc.to_s

    Zip::ZipFile.open(file, Zip::ZipFile::CREATE) do |zile|
      zile.get_output_stream("backup.xml") { |f| f.puts(stream) }
      files_dir = self.private_directory
      if with_files and File.exist?(files_dir)
        Dir.chdir(files_dir) do
          for document in Dir.glob(File.join("**", "*"))
            zile.add("Files/#{document}", File.join(files_dir, document))
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
    raise ArgumentError.new("Expecting String, #{file.class.name} instead") unless file.is_a? String or file.is_a? Pathname
    verbose = options[:verbose]
    files_dir = self.private_directory
    # Décompression
    puts "R> Uncompressing archive..." if verbose
    temporary_dir = Rails.root.join("tmp", "backups")
    FileUtils.mkdir_p(temporary_dir)
    archive = temporary_dir.join("uncompressed-backup-#{self.code}-#{Time.now.strftime('%Y%m%d-%H%M%S')}")
    stream = nil

    # Extract all files in archive
    Zip::ZipFile.open(file) do |zile|
      zile.each do |entry|
        FileUtils.mkdir_p(File.join(archive, entry.name.split(/[\\\/]+/)[0..-2]))
        zile.extract(entry, File.join(archive, entry.name))
      end
    end

    # Parsing
    version = (ActiveRecord::Migrator.current_version rescue 0)
    puts "R> Parsing backup.xml (#{version})..."  if verbose
    doc = LibXML::XML::Document.file(File.join(archive, "backup.xml"))
    backup = doc.root
    attr_version = backup.attributes['version']
    return false if not attr_version or (attr_version != version.to_s)

    root = backup.children[1]
    ActiveRecord::Base.transaction do
      # Suppression des données
      puts "R> Removing existing data..."  if verbose
      ids  = {}
      models = Ekylibre.models # .delete_if{|x| x==:company}
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
        elsif Ekylibre.models.include? element[:attributes]['model'].to_sym
          model_name = element[:attributes]['model'].to_sym
        else
          raise Exception.new("Unknown model #{element.inspect}")
        end
        model = model_name.to_s.classify.constantize
        keys[model.name] = Ekylibre.references[model_name].select{|k,v| v != :company}.to_a
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
        # code += "  record.send(:create_without_callbacks)\n"
        # code += "  record.create_without_callbacks\n"
        # code += "  record.save(:validate=>false, :callbacks=>false)\n"
        code += "  record.send(:create_strictly)\n"
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
      File.open(temporary_dir.join("restore-1.rb"), "wb") {|f| f.write(code)}  if verbose
      # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
      eval(code)

      # raise Exception.new(data.inspect)
      # Réorganisation des clés étrangères
      puts "R> Redifining primary keys..."  if verbose
      code  = ''

      for model_name in Ekylibre.models
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

      File.open(temporary_dir.join("restore-2.rb"), "wb") {|f| f.write(code)} if verbose
      start = Time.now
      eval(code)
      puts "R> Total: #{(Time.now-start)}s" if verbose



      # Chargement des paramètres de la société
      puts "R> Loading company data..." if verbose
      attrs = root.attributes.each do |attr|
        self.send(attr.name+'=', attr.value) unless ['id', 'lock_version', 'code'].include? attr.name
      end
      for key, target in Ekylibre.references[self.class.name.underscore.to_sym]
        v = ids[target.to_s.classify][self[key].to_s]
        self[key] = v unless v.nil?
      end
      # self.send(:update_without_callbacks)
      self.send(:update_strictly)
      self.reload
      # raise Active::Record::Rollback

      backup_files = File.join(archive, "Files")
      if File.exist?(backup_files)
        puts "R> Replacing files..." if verbose
        FileUtils.mv files_dir, files_dir+'.old'
        FileUtils.mv backup_files, files_dir
        FileUtils.rm_rf(files_dir+'.old')
      end
    end

    # Clean temporary directory by removing backup data
    FileUtils.rm_rf(archive)
    return true
  end


  # # Search a document template and use it to compile document using preferences
  # # options[:id] permits to identify the template
  # def print(options={})
  #   id = options.delete(:id)
  #   template = if id.is_a? DocumentTemplate
  #                id
  #              elsif id.is_a? Integer
  #                self.document_templates.find_by_id(id)
  #              elsif id.is_a? String or id.is_a? Symbol
  #                self.document_templates.find_by_code(id.to_s) || self.document_templates.find_by_nature_and_by_default(id.to_s, true)
  #              end
  #   raise Exception.new(I18n.translate("notifications.cannot_find_document_template")) unless template
  #   return template.print!(options)
  # end




  # def self.create_with_data(company_attr=nil, user_attr=nil, demo_language_code=nil)
  #   language = 'fra'
  #   currency = 'EUR'
  #   user = Entity.new(user_attr)
  #   code = company_attr[:code]

  #   ActiveRecord::Base.transaction do
  #     Sequence.load_defaults
  #     Unit.load_defaults

  #     EntityNature.create!(:name=>'Monsieur', :title=>'M', :physical=>true)
  #     EntityNature.create!(:name=>'Madame', :title=>'Mme', :physical=>true)
  #     EntityNature.create!(:name=>'Société Anonyme', :title=>'SA', :physical=>false)
  #     undefined_nature = EntityNature.create!(:name=>'Indéfini', :title=>'', :in_name=>false, :physical=>false)
  #     category = EntityCategory.create!(:name=>tc('default.category'))
  #     firm = Entity.create!(:category_id=> category.id, :nature_id=>undefined_nature.id, :language=>language, :last_name=>code, :currency => currency, :of_company => true)
  #     firm.contacts.create!(:line_2 => "", :line_3 => "", :line_5 => "", :line_6 => "", :by_default => true)

  #     user.admin = true
  #     user.role = Role.create!(:name=>tc('default.role.name.admin'),  :rights => Entity.rights_list.join(' '))
  #     Role.create!(:name=>tc('default.role.name.public'), :rights => '')
  #     user.save!

  #     Account.load_chart(:accounting_system)

  #     Department.create!(:name=>tc('default.department_name'))
  #     establishment = Establishment.create!(:name=>tc('default.establishment_name'), :nic=>"00000")
  #     #   # currency = company.currency || 'EUR' # company.currencies.create!(:name=>'Euro', :code=>'EUR', :value_format=>'%f €', :rate=>1)
  #     ProductCategory.create(:name=>tc('default.product_category_name'))

  #     for code, tax in tc("default.taxes")
  #       Tax.create!(:name=>tax[:name], :nature=>(tax[:nature]||"percent"), :amount=>tax[:amount].to_f, :collected_account_id=>Account.get(tax[:collected], tax[:name]).id, :paid_account_id=>Account.get(tax[:paid], tax[:name]).id)
  #     end

  #     # loading of all the templates
  #     DocumentTemplate.load_defaults

  #     journals = {}
  #     for journal in [:sales, :purchases, :bank, :various, :cash]
  #       j = Journal.create!(:name=>tc("default.journals.#{journal}"), :nature=>journal.to_s, :currency=>currency)
  #       # company.prefer!("#{journal}_journal", j)
  #       journals[journal] = j
  #       # company.prefer!("#{journal}_journal", company.journals.create!(:name=>tc("default.journals.#{journal}"), :nature=>journal.to_s, :currency=>currency))
  #     end

  #     cash = Cash.create!(:name => tc('default.cash.name.cash_box'), :nature => "cash_box", :account => Account.get("531101", "Caisse"), :journal_id => journals[:cash].id)
  #     baac = Cash.create!(:name => tc('default.cash.name.bank_account'), :nature => "bank_account", :account => Account.get("512101", "Compte bancaire"), :journal_id => journals[:bank].id, :iban => "FR7611111222223333333333391", :mode => "iban")
  #     IncomingPaymentMode.create!(:name => tc('default.incoming_payment_modes.cash.name'), :cash_id => cash.id, :with_accounting => true, :attorney_journal => journals[:various])
  #     IncomingPaymentMode.create!(:name => tc('default.incoming_payment_modes.check.name'), :cash_id => baac.id, :with_accounting => true, :with_deposit => true, :depositables_account_id => Account.get("5112", "Chèques à encaisser").id, :depositables_journal_id => journals[:various].id, :attorney_journal => journals[:various])
  #     IncomingPaymentMode.create!(:name => tc('default.incoming_payment_modes.transfer.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal => journals[:various])

  #     OutgoingPaymentMode.create!(:name => tc('default.outgoing_payment_modes.cash.name'), :cash_id => cash.id, :with_accounting => true, :attorney_journal => journals[:various])
  #     OutgoingPaymentMode.create!(:name => tc('default.outgoing_payment_modes.check.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal => journals[:various])
  #     OutgoingPaymentMode.create!(:name => tc('default.outgoing_payment_modes.transfer.name'), :cash_id => baac.id, :with_accounting => true, :attorney_journal => journals[:various])

  #     delays = []
  #     ['expiration', 'standard', 'immediate'].each do |d|
  #       delays << Delay.create!(:name => tc('default.delays.name.'+d), :expression => tc('default.delays.expression.'+d), :active => true)
  #     end
  #     FinancialYear.create!(:started_on => Date.today.beginning_of_month)
  #     SaleNature.create!(:name => tc('default.sale_nature_name'), :expiration_id => delays[0].id, :payment_delay_id => delays[2].id, :downpayment => false, :downpayment_minimum => 300, :downpayment_rate => 0.3, :currency => currency, :with_accounting => true, :journal => journals[:sales])
  #     PurchaseNature.create!(:name => tc('default.purchase_nature_name'), :currency => currency, :with_accounting => true, :journal => journals[:purchases])


  #     Warehouse.create!(:name => tc('default.warehouse_name'), :establishment_id => establishment.id)
  #     for nature in [:sale, :sales_invoice, :purchase]
  #       EventNature.create!(:duration => 10, :usage => nature.to_s, :name => tc("default.event_natures.#{nature}"))
  #     end

  #     #   # Add custom_fieldary data to test
  #     #   company.load_demo_data unless demo_language_code.blank?
  #   end
  #   return
  # end





  # def self.create_with_data(company_attr=nil, user_attr=nil, demo_language_code=nil)
  #   language = 'fra'
  #   # company = Company.new({:language=>language}.merge(company_attr))
  #   # company = Company.new(company_attr)
  #   user = Entity.new(user_attr)

  #   ActiveRecord::Base.transaction do
  #     company.save!
  #     company.roles.create!(:name=>tc('default.role.name.admin'),  :rights=>Entity.rights_list.join(' '))
  #     company.roles.create!(:name=>tc('default.role.name.public'), :rights=>'')
  #     user.company_id = company.id
  #     user.role_id = company.admin_role.id
  #     user.save!

  #     company.load_accounts(:accounting_system)

  #     company.departments.create!(:name=>tc('default.department_name'))
  #     establishment = company.establishments.create!(:name=>tc('default.establishment_name'), :nic=>"00000")
  #     currency = company.currency || 'EUR' # company.currencies.create!(:name=>'Euro', :code=>'EUR', :value_format=>'%f €', :rate=>1)
  #     company.product_categories.create(:name=>tc('default.product_category_name'))
  #     company.load_units
  #     company.load_sequences

  #     user.reload
  #     user.attributes = {:employed=>true, :commercial=>true, :department_id=>company.departments.first.id, :establishment_id=>company.establishments.first.id, :employment=>'-'}
  #     user.save!

  #     for code, tax in tc("default.taxes")
  #       company.taxes.create!(:name=>tax[:name], :nature=>(tax[:nature]||"percent"), :amount=>tax[:amount].to_f, :collected_account_id=>company.account(tax[:collected], tax[:name]).id, :paid_account_id=>company.account(tax[:paid], tax[:name]).id)
  #     end

  #     company.entity_natures.create!(:name=>'Monsieur', :title=>'M', :physical=>true)
  #     company.entity_natures.create!(:name=>'Madame', :title=>'Mme', :physical=>true)
  #     company.entity_natures.create!(:name=>'Société Anonyme', :title=>'SA', :physical=>false)
  #     undefined_nature = company.entity_natures.create!(:name=>'Indéfini', :title=>'', :in_name=>false, :physical=>false)
  #     category = company.entity_categories.create!(:name=>tc('default.category'))
  #     firm = company.entities.create!(:category_id=> category.id, :nature_id=>undefined_nature.id, :language=>language, :last_name=>company.name)
  #     company.reload
  #     company.entity_id = firm.id
  #     company.save!
  #     company.entity.contacts.create!(:company_id=>company.id, :line_2=>"", :line_3=>"", :line_5=>"", :line_6=>'12345 MAVILLE', :by_default=>true)

  #     # loading of all the templates
  #     company.load_prints

  #     journals = {}
  #     for journal in [:sales, :purchases, :bank, :various, :cash]
  #       j = company.journals.create!(:name=>tc("default.journals.#{journal}"), :nature=>journal.to_s, :currency=>currency)
  #       # company.prefer!("#{journal}_journal", j)
  #       journals[journal] = j
  #       # company.prefer!("#{journal}_journal", company.journals.create!(:name=>tc("default.journals.#{journal}"), :nature=>journal.to_s, :currency=>currency))
  #     end

  #     cash = company.cashes.create!(:name=>tc('default.cash.name.cash_box'), :company_id=>company.id, :nature=>"cash_box", :account=>company.account("531101", "Caisse"), :journal_id=>journals[:cash].id)
  #     baac = company.cashes.create!(:name=>tc('default.cash.name.bank_account'), :company_id=>company.id, :nature=>"bank_account", :account=>company.account("512101", "Compte bancaire"), :journal_id=>journal[:bank].id, :iban=>"FR7611111222223333333333391", :mode=>"iban")
  #     company.incoming_payment_modes.create!(:name=>tc('default.incoming_payment_modes.cash.name'), :company_id=>company.id, :cash_id=>cash.id, :with_accounting=>true)
  #     company.incoming_payment_modes.create!(:name=>tc('default.incoming_payment_modes.check.name'), :company_id=>company.id, :cash_id=>baac.id, :with_accounting=>true, :with_deposit=>true, :depositables_account_id=>company.account("5112", "Chèques à encaisser").id, :depositables_journal_id=>company.preferred_various_journal)
  #     company.incoming_payment_modes.create!(:name=>tc('default.incoming_payment_modes.transfer.name'), :company_id=>company.id, :cash_id=>baac.id, :with_accounting=>true)

  #     company.outgoing_payment_modes.create!(:name=>tc('default.outgoing_payment_modes.cash.name'), :company_id=>company.id, :cash_id=>cash.id, :with_accounting=>true)
  #     company.outgoing_payment_modes.create!(:name=>tc('default.outgoing_payment_modes.check.name'), :company_id=>company.id, :cash_id=>baac.id, :with_accounting=>true)
  #     company.outgoing_payment_modes.create!(:name=>tc('default.outgoing_payment_modes.transfer.name'), :company_id=>company.id, :cash_id=>baac.id, :with_accounting=>true)

  #     delays = []
  #     ['expiration', 'standard', 'immediate'].each do |d|
  #       delays << company.delays.create!(:name=>tc('default.delays.name.'+d), :expression=>tc('default.delays.expression.'+d), :active=>true)
  #     end
  #     company.financial_years.create!(:started_on=>Date.today)
  #     company.sale_natures.create!(:name=>tc('default.sale_nature_name'), :expiration_id=>delays[0].id, :payment_delay_id=>delays[2].id, :downpayment=>false, :downpayment_minimum=>300, :downpayment_rate=>0.3, :currency=>currency, :with_accounting=>true, :journal=>company.preferred_sales_journal)
  #     company.purchase_natures.create!(:name=>tc('default.purchase_nature_name'), :currency=>currency, :with_accounting=>true, :journal=>company.preferred_purchases_journal)


  #     company.load_sequences

  #     company.warehouses.create!(:name=>tc('default.warehouse_name'), :establishment_id=>establishment.id)
  #     for nature in [:sale, :sales_invoice, :purchase]
  #       company.event_natures.create!(:duration=>10, :usage=>nature.to_s, :name=>tc("default.event_natures.#{nature}"))
  #     end

  #     # Add custom_fieldary data to test
  #     company.load_demo_data unless demo_language_code.blank?
  #   end
  #   return company, user
  # end








  # this method loads all the templates existing.
  # def load_prints
  #   language = self.entity.language
  #   files_dir = Rails.root.join("config", "locales", ::I18n.locale.to_s, "prints")
  #   for family, templates in ::I18n.translate('models.company.default.document_templates')
  #     for template, attributes in templates
  #       next unless File.exist? files_dir.join("#{template}.xml")
  #       #begin
  #       File.open(files_dir.join("#{template}.xml"), "rb:UTF-8") do |f|
  #         attributes[:name] ||= I18n::t('models.document_template.natures.'+template.to_s)
  #         attributes[:name] = attributes[:name].to_s
  #         attributes[:nature] ||= template.to_s
  #         attributes[:filename] ||= "File"
  #         attributes[:to_archive] = true if attributes[:to_archive] == "true"
  #         if RUBY_VERSION =~ /^1\.9/
  #           attributes[:source] = f.read.force_encoding('UTF-8')
  #         else
  #           attributes[:source] = f.read
  #         end
  #         code = attributes[:name].to_s.codeize[0..7]
  #         doc = self.document_templates.find_by_code(code)
  #         doc ||= self.document_templates.new
  #         doc.attributes = HashWithIndifferentAccess.new(:active=>true, :language=>language, :country=>'fr', :family=>family.to_s, :code=>code, :by_default=>false).merge(attributes)
  #         # doc["source"].force_encoding!('UTF-8') if RUBY_VERSION =~ /^1\.9/
  #         doc.save!
  #       end
  #       #rescue
  #       #end
  #     end
  #   end
  # end

  # def load_units
  #   for name, desc in Unit.default_units
  #     # unit = self.units.find_by_base_and_coefficient_and_start(desc[:base], desc[:coefficient], desc[:start])
  #     unless self.units.find_by_name(name.to_s)
  #       self.units.create!(:name=>name.to_s, :label=>tc('default.units.'+name.to_s), :base=>desc[:base], :coefficient=>desc[:coefficient], :start=>desc[:start])
  #     end
  #   end
  # end


  # # Create unexistent sequences
  # def load_sequences
  #   for sequence, attributes in tc('default.sequences')
  #     unless self.preferred("#{sequence}_sequence")
  #       seq = self.sequences.create(attributes)
  #       self.prefer!("#{sequence}_sequence", seq) if seq
  #     end
  #   end
  # end

  # def load_accounts(name, options={})
  #   locale = options[:locale]
  #   if (plan = ::I18n.translate("accounting_systems.#{name}", :locale=>locale)).is_a? Hash
  #     ActiveRecord::Base.transaction do
  #       # Destroy unused existing accounts
  #       self.accounts.destroy_all

  #       regexp = Account.reconcilable_regexp

  #       # Existing accounts
  #       for account in self.reload.accounts
  #         account.update_column(:reconcilable, true) if account.number.match(regexp)
  #       end if options[:reconcilable]

  #       # Create new accounts
  #       for num, name in plan.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}.select{|k, v| k.to_s.match(/^n\_/)}
  #         number = num.to_s[2..-1]
  #         if account = self.accounts.find_by_number(number)
  #           account.update_attributes!(:name=>name, :reconcilable=>(options[:reconcilable] and number.match(regexp)))
  #         else
  #           raise number.inspect unless self.accounts.create(:number=>number, :name=>name, :reconcilable=>(number.match(regexp) ? true : false))
  #         end
  #       end

  #     end
  #   end
  # end



  def load_demo_data(language_code=nil)
    self.entity_natures.create!(:name=>"Société A Responsabilité Limitée", :title=>"SARL", :in_name=>true)
    last_name = ["MARTIN", "DUPONT", "DURAND", "LABAT", "VILLENEUVE", "SICARD", "FRERET", "FOUCAULT", "DUPEYRON", "BORGÈS", "DUBOIS", "LEROY", "MOREL", "GUERIN", "MORIN", "ROUSSEAU", "LEMAIRE", "DUVAL", "BRUN", "FERNANDEZ", "BRETON", "LEBLANC", "DA SILVA", "CORDIER", "BRIAND", "CAMUS", "VOISIN", "LELIEVRE", "GONZALEZ"]
    first_name = ["Benoît", "Stéphane", "Marine", "Roger", "Céline", "Bertrand", "Camille", "Dominique", "Julie", "Kévin", "Maxime", "Vincent", "Claire", "Marie-France", "Jean-Marie", "Anne-Marie", "Dominique", "Hakim", "Alain", "Daniel", "Sylvie", "Fabrice", "Nathalie", "Véronique", "Jeanine", "Edouard", "Colette", "Sébastien", "Rémi", "Joseph", "Baptiste", "Manuel", "Sofia", "Indira", "Martine", "Guy"]
    streets = ["Cours Xavier Arnozan", "Cours du général de Gaulle", "Route pavée", "Avenue Thiers", "Rue Gambetta", "5th Avenue", "rue Louis La Brocante", "Rue Léon Blum", "Avenue des Champs Élysées", "Cours de la marne"]
    cities = ["33000 Bordeaux", "33170 Gradignan", "40600 Biscarosse", "33400 Talence", "75001 Paris", "13000 Marseille", "33600 Pessac", "47000 Agen", "33710 Pugnac", "33700 Mérignac", "40000 Mont de Marsan"]
    entity_natures = self.entity_natures.collect{|x| x.id.to_s}
    indifferent_attributes = {:category_id=>self.entity_categories.first.id, :language=>self.entity.language}
    products = ["Salades", "Bouteille en verre 75 cl", "Bouchon liège", "Capsule CRD", "Capsule", "Étiquette", "Vin Quillet-Bont 2005", "Caisse Bois 6 btles", "Bouteille Quillet-Bont 2005 75 cl", "Caisse 6 b. Quillet-Bont 2005", "Pommes de terre", "Séjour 1 nuit", "Séjour 1 semaine 1/2 pension", "Fongicide", "Insecticide"]
    product_category_id = self.product_categories.first.id
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
    taxes = self.taxes
    for product_name in products
      product = self.products.create!(:nature=>"product", :name=>product_name, :for_sales=>true, :for_productions=>true, :category_id=>product_category_id, :unit=>units[rand(units.size)], :deliverable=>true, :stockable=>true, :weight=>rand(3), :sales_account_id=>product_account.id)
      product.reload
      product.prices.create!(:amount=>rand(100), :company_id=>self.id, :use_range=>false, :tax_id=>taxes[rand(taxes.size)].id, :category_id=>category_id, :entity_id=>product.name.include?("icide") ? self.entities.find(:first, :conditions=>{:supplier=>true}).id : self.entity_id)
    end

    product = self.products.find_by_name("Caisse 6 b. Quillet-Bont 2005")
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Bouteille Quillet-Bont 2005 75 cl").id, :quantity=>6, :warehouse_id=>self.warehouses.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Caisse Bois 6 btles").id, :quantity=>1, :warehouse_id=>self.warehouses.first.id)

    product = self.products.find_by_name("Bouteille Quillet-Bont 2005 75 cl")
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Bouchon liège").id, :quantity=>1, :warehouse_id=>self.warehouses.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Étiquette").id, :quantity=>1, :warehouse_id=>self.warehouses.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Bouteille en verre 75 cl").id, :quantity=>1, :warehouse_id=>self.warehouses.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Vin Quillet-Bont 2005").id, :quantity=>0.75, :warehouse_id=>self.warehouses.first.id)
    self.product_components.create!(:active=>true, :product_id=>product.id, :component_id=>self.products.find_by_name("Capsule CRD").id, :quantity=>1, :warehouse_id=>self.warehouses.first.id)

    self.subscriptions.create!(:nature_id=>self.subscription_natures.first.id, :started_on=>Date.today, :stopped_on=>Date.today+(365), :entity_id=>self.entities.find(:first, :conditions=>{:client=>true}).id, :suspended=>false)

    product = self.products.find_by_name("Vin Quillet-Bont 2005")
    self.warehouses.create!(:name=>"Cuve Jupiter", :product_id=>product.id, :quantity_max=>1000, :number=>1, :reservoir=>true, :establishment_id=>self.establishments.first.id)


    units = self.units.find(:all, :conditions=>{:base =>'m2'})
    group = self.land_parcel_groups.create!(:name=>"General")
    for land_parcel in ["Milou", "Rantanplan", "Idéfix", "Cubitus", "Snoopy"]
      self.land_parcels.create!(:name=>land_parcel, :area_measure=>rand(1000)+10, :area_unit=>units[rand(units.size)], :group_id=>group.id)
    end
    for nature in ["Palissage", "Récolte", "Traitements", "Labour", "Vendange", "Épandange", "Éclaircissage"]
      self.operation_natures.create!(:name=>nature, :target_type=>"LandParcel")
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

  # def journal_entry_lines_between(started_on, stopped_on)
  #   self.journal_entry_lines.find(:all, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on], :order=>"printed_on, journal_entries.id, journal_entry_lines.id")
  # end

  def journal_entry_lines_calculate(column, started_on, stopped_on, operation=:sum)
    column = (column == :balance ? "#{JournalEntryLine.table_name}.original_debit - #{JournalEntryLine.table_name}.original_credit" : "#{JournalEntryLine.table_name}.original_#{column}")
    self.journal_entry_lines.calculate(operation, column, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on])
  end



end
