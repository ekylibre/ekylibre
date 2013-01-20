# -*- coding: utf-8 -*-
# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: entities
#
#  active                                 :boolean          default(TRUE), not null
#  activity_code                          :string(32)       
#  admin                                  :boolean          not null
#  attorney                               :boolean          not null
#  attorney_account_id                    :integer          
#  authorized_payments_count              :integer          
#  born_on                                :date             
#  category_id                            :integer          
#  client                                 :boolean          not null
#  client_account_id                      :integer          
#  code                                   :string(64)       
#  comment                                :text             
#  connected_at                           :datetime         
#  country                                :string(2)        
#  created_at                             :datetime         not null
#  creator_id                             :integer          
#  currency                               :string(255)      not null
#  dead_on                                :date             
#  deliveries_conditions                  :string(60)       
#  department_id                          :integer          
#  ean13                                  :string(13)       
#  employed                               :boolean          not null
#  employment                             :string(255)      
#  establishment_id                       :integer          
#  first_met_on                           :date             
#  first_name                             :string(255)      
#  full_name                              :string(255)      not null
#  hashed_password                        :string(64)       
#  id                                     :integer          not null, primary key
#  invoices_count                         :integer          
#  language                               :string(3)        default("???"), not null
#  last_name                              :string(255)      not null
#  left_on                                :date             
#  lock_version                           :integer          default(0), not null
#  locked                                 :boolean          not null
#  loggable                               :boolean          not null
#  maximal_grantable_reduction_percentage :decimal(19, 4)   
#  nature_id                              :integer          not null
#  of_company                             :boolean          not null
#  office                                 :string(255)      
#  origin                                 :string(255)      
#  payment_delay_id                       :integer          
#  payment_mode_id                        :integer          
#  photo                                  :string(255)      
#  profession_id                          :integer          
#  proposer_id                            :integer          
#  prospect                               :boolean          not null
#  recruited_on                           :date             
#  reduction_percentage                   :decimal(19, 4)   
#  reflation_submissive                   :boolean          not null
#  responsible_id                         :integer          
#  rights                                 :text             
#  role_id                                :integer          
#  salt                                   :string(64)       
#  siren                                  :string(9)        
#  soundex                                :string(4)        
#  supplier                               :boolean          not null
#  supplier_account_id                    :integer          
#  transporter                            :boolean          not null
#  updated_at                             :datetime         not null
#  updater_id                             :integer          
#  user_name                              :string(32)       
#  vat_number                             :string(15)       
#  vat_submissive                         :boolean          default(TRUE), not null
#  webpass                                :string(255)      
#

require "digest/sha2"

class Entity < CompanyRecord
  acts_as_numbered :code
  attr_accessible :active, :activity_code, :attorney, :attorney_account_id, :authorized_payments_count, :born_on, :category_id, :client, :client_account_id, :code, :comment, :country, :currency, :dead_on, :deliveries_conditions, :department_id, :ean13, :employed, :employment, :establishment_id, :first_met_on, :first_name, :full_name, :language, :last_name, :left_on, :loggable, :maximal_grantable_reduction_percentage, :nature_id, :office, :origin, :payment_delay_id, :payment_mode_id, :photo, :profession_id, :proposer_id, :prospect, :recruited_on, :reduction_percentage, :reflation_submissive, :responsible_id, :role_id, :siren, :supplier, :supplier_account_id, :transporter, :user_name, :vat_number, :vat_submissive
  attr_accessor :password_confirmation, :old_password
  attr_protected :hashed_password, :salt, :locked, :rights
  belongs_to :attorney_account, :class_name => "Account"
  belongs_to :category, :class_name => "EntityCategory"
  belongs_to :client_account, :class_name => "Account"
  belongs_to :department
  belongs_to :establishment
  belongs_to :nature, :class_name => "EntityNature"
  belongs_to :payment_delay, :class_name => "Delay"
  belongs_to :payment_mode, :class_name => "IncomingPaymentMode"
  belongs_to :profession
  belongs_to :proposer, :class_name => "Entity"
  belongs_to :responsible, :class_name => "Entity"
  belongs_to :role
  belongs_to :supplier_account, :class_name => "Account"
  has_many :clients, :class_name => "Entity", :foreign_key => :responsible_id, :dependent => :nullify
  has_many :addresses, :conditions => {:deleted_at => nil}, :class_name => "EntityAddress", :inverse_of => :entity
  has_many :mails,     :conditions => {:canal => "mail",    :deleted_at => nil}, :class_name => "EntityAddress", :inverse_of => :entity
  has_many :emails,    :conditions => {:canal => "email",   :deleted_at => nil}, :class_name => "EntityAddress", :inverse_of => :entity
  has_many :phones,    :conditions => {:canal => "phone",   :deleted_at => nil}, :class_name => "EntityAddress", :inverse_of => :entity
  has_many :mobiles,   :conditions => {:canal => "mobile",  :deleted_at => nil}, :class_name => "EntityAddress", :inverse_of => :entity
  has_many :faxes,     :conditions => {:canal => "fax",     :deleted_at => nil}, :class_name => "EntityAddress", :inverse_of => :entity
  has_many :websites,  :conditions => {:canal => "website", :deleted_at => nil}, :class_name => "EntityAddress", :inverse_of => :entity
  has_many :auto_updateable_addresses, :conditions => {:deleted_at => nil, :mail_auto_update => true}, :class_name => "EntityAddress"
  has_many :direct_links, :class_name => "EntityLink", :foreign_key => :entity_1_id
  has_many :events, :class_name => "Event"
  has_many :product_events, :class_name => "Log", :foreign_key => :watcher_id
  has_many :managed_events, :foreign_key => :responsible_id # as Responsible
  has_many :future_events, :class_name => "Event", :foreign_key => :responsible_id, :conditions => ["started_at >= CURRENT_TIMESTAMP"]
  has_many :godchildren, :class_name => "Entity", :foreign_key => "proposer_id"
  has_many :incoming_payments, :foreign_key => :payer_id, :inverse_of => :payer
  has_many :indirect_links, :class_name => "EntityLink", :foreign_key => :entity_2_id
  has_many :mandates
  has_many :observations
  has_many :preferences, :dependent => :destroy, :foreign_key => :user_id
  has_many :prices
  has_many :purchase_invoices, :class_name => "Purchase", :foreign_key => :supplier_id, :order => "created_on desc", :conditions => {:state => "invoice"}
  has_many :purchases, :foreign_key => :supplier_id
  has_many :operations, :foreign_key => :responsible_id
  has_many :outgoing_deliveries, :foreign_key => :transporter_id
  has_many :outgoing_payments, :foreign_key => :payee_id
  has_many :sales_invoices, :class_name => "Sale", :foreign_key => :client_id, :order => "created_on desc", :conditions => {:state => "invoice"}
  has_many :managed_sales_invoices, :foreign_key => :responsible_id, :class_name => "Sale", :conditions => {:state => :invoice}
  has_many :sales, :foreign_key => :client_id, :order => "created_on desc"
  has_many :managed_sales, :foreign_key => :responsible_id
  has_many :sale_lines, :class_name => "SaleItem"
  has_many :subscriptions
  has_many :trackings, :foreign_key => :producer_id
  has_many :transfers, :foreign_key => :supplier_id
  has_many :transports, :foreign_key => :transporter_id
  has_many :managed_transports, :foreign_key => :responsible_id
  has_many :transporter_sales, :foreign_key => :transporter_id, :order => "created_on desc", :class_name => "Sale"
  has_many :prescriptions, :class_name => "AnimalPrescription", :foreign_key => :prescriptor_id
  has_many :managed_unpaid_sales, :class_name => "Sale", :foreign_key => :responsible_id, :order => "created_on", :conditions => ["state IN ('order', 'invoice') AND paid_amount < amount AND lost = ? ", false]
  has_many :usable_incoming_payments, :conditions => ["used_amount < amount"], :class_name => "IncomingPayment", :foreign_key => :payer_id
  has_many :waiting_deliveries, :class_name => "OutgoingDelivery", :foreign_key => :transporter_id, :conditions => ["moved_on IS NULL AND planned_on <= CURRENT_DATE"]
  has_one :default_mail_address, :class_name => "EntityAddress", :conditions => {:by_default => true, :canal => :mail}

  accepts_nested_attributes_for :mails,    :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :emails,   :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :phones,   :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :mobiles,  :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :faxes,    :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :websites, :reject_if => :all_blank, :allow_destroy => true

  def self.of_company
    self.where(:of_company => true).first
  end

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :maximal_grantable_reduction_percentage, :reduction_percentage, :allow_nil => true
  validates_length_of :country, :allow_nil => true, :maximum => 2
  validates_length_of :language, :allow_nil => true, :maximum => 3
  validates_length_of :soundex, :allow_nil => true, :maximum => 4
  validates_length_of :siren, :allow_nil => true, :maximum => 9
  validates_length_of :ean13, :allow_nil => true, :maximum => 13
  validates_length_of :vat_number, :allow_nil => true, :maximum => 15
  validates_length_of :activity_code, :user_name, :allow_nil => true, :maximum => 32
  validates_length_of :deliveries_conditions, :allow_nil => true, :maximum => 60
  validates_length_of :code, :hashed_password, :salt, :allow_nil => true, :maximum => 64
  validates_length_of :currency, :employment, :first_name, :full_name, :last_name, :office, :origin, :photo, :webpass, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :admin, :attorney, :client, :employed, :locked, :loggable, :of_company, :prospect, :reflation_submissive, :supplier, :transporter, :vat_submissive, :in => [true, false]
  validates_presence_of :currency, :full_name, :language, :last_name, :nature
  #]VALIDATORS]
  validates_presence_of :category
  validates_presence_of :password, :password_confirmation, :if => Proc.new{|e| e.hashed_password.blank? and e.loggable?}
  validates_confirmation_of :password
  validates_numericality_of :maximal_grantable_reduction_percentage, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100
  validates_presence_of   :user_name, :if => :loggable?
  validates_uniqueness_of :user_name
  validates_format_of     :user_name, :with => /^[a-z0-9][a-z0-9\.\_]+[a-z0-9]$/, :if => lambda{|e| !e.user_name.blank?}
  validates_length_of     :user_name, :in => 3..32, :if => lambda{|e| !e.user_name.blank?}
  # validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :if => lambda{|r| !r.email.blank?}

  # default_scope order(:last_name, :first_name)
  scope :necessary_transporters, -> { where("id IN (SELECT transporter_id FROM #{OutgoingDelivery.table_name} WHERE (moved_on IS NULL AND planned_on <= CURRENT_DATE) OR transport_id IS NULL)").order(:last_name, :first_name) }
  scope :employees, -> { where(:employed => true) }
  scope :suppliers,    -> { where(:supplier => true) }
  scope :transporters, -> { where(:transporter => true) }
  scope :clients,      -> { where(:client => true) }

  # Needed to stamp all records
  model_stamper

  class << self
    def rights_file; Rails.root.join("config", "rights.yml"); end
    def minimum_right; :__minimum__; end
    def rights; @@rights; end
    def rights_list; @@rights_list; end
    def useful_rights; @@useful_rights; end
  end


  before_validation do
    self.webpass = Entity.give_password(8, :normal) if self.webpass.blank?
    self.soundex = self.last_name.soundex2 if !self.last_name.nil?
    self.first_name = self.first_name.to_s.strip
    self.last_name  = self.last_name.to_s.strip
    self.full_name = (self.last_name.to_s+" "+self.first_name.to_s)
    unless self.nature.nil?
      self.full_name = (self.nature.title+' '+self.full_name).strip unless self.nature.in_name # or self.nature.abbreviation == "-")
    end
    self.full_name.strip!
    # self.name = self.name.to_s.strip.downcase.gsub(/[^a-z0-9\.\_]/,'')
    if entity = Entity.of_company
      self.language = entity.language if self.language.blank?
      self.currency = entity.currency if self.currency.blank?
    end
    unless self.category
      self.category = EntityCategory.where(:by_default => true).first
    end
    if self.user_name.blank? and not self.last_name.blank?
      self.user_name = ""
      unless self.first_name.blank?
        self.user_name << self.first_name.to_s.ascii.downcase.gsub(/[^a-z0-9]/, '') + "."
      end
      self.user_name << self.last_name.to_s.ascii.downcase.gsub(/[^a-z0-9]/, '')
      base_name, base_number = self.user_name, 0
      while Entity.where("id != ?", self.id || 0).where(:user_name => self.user_name).count > 0
        base_number += 1
        self.user_name = base_name + base_number.to_s
      end
    end
    self.maximal_grantable_reduction_percentage ||= 0
    # self.admin = true if self.rights.nil?
    self.rights_array = self.rights_array # Clean the rights
    return true
  end

  validate do
    if self.nature
      if self.nature.in_name and not self.last_name.match(/( |^)#{self.nature.title}( |$)/i)
        errors.add(:last_name, :missing_title, :title => self.nature.title)
      end
    end
  end

  after_save do
    self.auto_updateable_addresses.find_each do |a|
      a.mail_line_1 = self.full_name
      a.save
    end
  end

  protect(:on => :destroy) do
    return false if self.id == self.of_company? or self.sales_invoices.count > 0 or self.events.count > 0 and self.sales.count > 0 and self.operations.count > 0 and self.transports.count > 0
    return true
  end


  def self.exportable_columns
    self.content_columns.delete_if{|c| [:active, :lock_version, :webpass, :soundex, :photo, :deliveries_conditions].include?(c.name.to_sym)}
  end

  # Returns an entity scope for all other entities
  def others
    self.class.where("id != ?", (self.id || 0))
  end

  def label
    self.code.to_s + '. ' + self.full_name.to_s
  end

  #
  def created_on
    self.created_at.to_date
  end


  def last_incoming_payment
    self.incoming_payments.find(:first, :order => "updated_at DESC")
  end

  #
  def balance
    amount = 0.0
    amount += self.incoming_payments.sum(:amount)
    amount -= self.sales_invoices.sum(:amount)
    amount -= self.outgoing_payments.sum(:amount)
    amount += self.purchase_invoices.sum(:amount)
    return amount
  end

  def has_another_tracking?(serial, product_id)
    self.trackings.find(:all, :conditions => ["serial=? AND product_id!=? ", serial, product_id]).size > 0
  end


  # This method creates automatically an account for the entity for its usage (client, supplier...)
  def account(nature)
    natures = {:client => :client_account, :supplier => :supplier_account, :attorney => :attorney_account}
    raise ArgumentError.new("Unknown nature #{nature.inspect} (#{natures.keys.to_sentence} are accepted)") unless natures.keys.include? nature
    valid_account = self.send(natures[nature])
    if valid_account.nil?
      prefix = Account.find_in_chart("#{nature}_thirds").number
      if Preference[:use_entity_codes_for_account_numbers]
        number = prefix.to_s+self.code.to_s
        valid_account = Account.find_by_number(number)
        valid_account = Account.create(:number => number, :name => self.full_name, :reconcilable => true) unless valid_account
      else
        suffix = "1"
        suffix = suffix.upper_ascii[0..5].rjust(6, '0')
        account = 1
        #x=Time.now
        i = 0
        while not account.nil? do
          account = Account.where("number LIKE ?", prefix.to_s+suffix.to_s).first
          suffix.succ! unless account.nil?
          i=i+1
        end
        # puts "Find entity (#{x-Time.now}s) :"+i.to_s
        valid_account = Account.create(:number => prefix.to_s+suffix.to_s, :name => self.full_name, :reconcilable => true)
      end
      self.reload.update_column("#{natures[nature]}_id", valid_account.id)
    end
    return valid_account
  end

  def warning
    count = self.observations.find_all_by_importance("important").size
    #count += self.balance<0 ? 1 : 0
  end

  def add_event(usage, user_id)
    if user = Entity.find_by_id(user_id)
      EventNature.find_all_by_usage(usage).each do |nature|
        nature.events.create!(:started_at => Time.now, :duration => event_nature.duration, :entity_id => self.id, :responsible_id => user.id)
      end
    end
  end

  def default_mail_coordinate
    self.default_address ? self.default_address.coordinate : '[NoDefaultEntityAddressError]'
  end

  def maximal_reduction_percentage(computed_on = Date.today)
    return Subscription.maximum(:reduction_percentage, :joins => "JOIN #{SubscriptionNature.table_name} AS sn ON (#{Subscription.table_name}.nature_id = sn.id) LEFT JOIN #{EntityLink.table_name} AS el ON (el.nature_id = sn.entity_link_nature_id AND #{Subscription.table_name}.entity_id IN (entity_1_id, entity_2_id))", :conditions => ["? IN (#{Subscription.table_name}.entity_id, entity_1_id, entity_2_id) AND ? BETWEEN #{Subscription.table_name}.started_on AND #{Subscription.table_name}.stopped_on AND COALESCE(#{Subscription.table_name}.sale_id, 0) NOT IN (SELECT id FROM #{Sale.table_name} WHERE state='estimate')", self.id, computed_on]).to_f || 0.0
  end

  def description
    desc = self.code+". "+self.full_name
    c = self.default_address
    desc += " ("+c.line_6.to_s+")" unless c.nil?
    desc
  end

  def merge_with(entity)
    raise Exception.new("Company entity is not mergeable") if entity.of_company?
    Ekylibre::Record::Base.transaction do
      # Classics
      for many in [:direct_links, :events, :godchildren, :indirect_links, :mandates, :observations, :prices, :purchases, :outgoing_deliveries, :outgoing_payments, :sales, :sale_lines, :incoming_payments, :subscriptions, :trackings, :transfers, :transports, :transporter_sales]
        ref = self.class.reflections[many]
        ref.class_name.constantize.update_all({ref.foreign_key => self.id}, {ref.foreign_key => entity.id})
      end
      # EntityAddress
      EntityAddress.update_all(["code = '0'||SUBSTR(code, 2, 3), entity_id=?, by_default=? ", self.id, false], {:entity_id => entity.id})

      # Add observation
      observation = "Merged entity (ID=#{entity.id}) :\n"
      for attr, value in entity.attributes.sort
        observation += " - #{Entity.human_attribute_name(attr)} : #{entity.send(attr).to_s}\n"
      end
      for custom_field_datum in entity.custom_field_data
        observation += " * #{custom_field_datum.custom_field.name} : #{custom_field_datum.value.to_s}\n"
        custom_field_datum.destroy
      end
      self.observations.create!(:description => observation, :importance => "normal")

      # Remove doublon
      entity.destroy
    end
  end





  def self.importable_columns
    columns = []
    columns << [tc("import.dont_use"), "special-dont_use"]
    columns << [tc("import.generate_string_custom_field"), "special-generate_string_custom_field"]
    # columns << [tc("import.generate_choice_custom_field"), "special-generate_choice_custom_field"]
    cols = Entity.content_columns.delete_if{|c| [:active, :full_name, :soundex, :lock_version, :updated_at, :created_at].include?(c.name.to_sym) or c.type == :boolean}.collect{|c| c.name}
    columns += cols.collect{|c| [Entity.model_name.human+"/"+Entity.human_attribute_name(c), "entity-"+c]}.sort
    cols = EntityAddress.content_columns.collect{|c| c.name}.delete_if{|c| [:code, :started_at, :stopped_at, :deleted, :address, :by_default, :closed_on, :lock_version, :active,  :updated_at, :created_at].include?(c.to_sym)}+["line_6_city", "line_6_code"]
    columns += cols.collect{|c| [EntityAddress.model_name.human+"/"+EntityAddress.human_attribute_name(c), "address-"+c]}.sort
    columns += ["name", "abbreviation"].collect{|c| [EntityNature.model_name.human+"/"+EntityNature.human_attribute_name(c), "entity_nature-"+c]}.sort
    columns += ["name"].collect{|c| [EntityCategory.model_name.human+"/"+EntityCategory.human_attribute_name(c), "entity_category-"+c]}.sort
    columns += CustomField.find(:all, :conditions => ["nature in ('string')"]).collect{|c| [CustomField.model_name.human+"/"+c.name, "custom_field-id"+c.id.to_s]}.sort
    return columns
  end


  # def self.exportable_columns
  #   columns = []
  #   columns += Entity.content_columns.collect{|c| [Entity.model_name.human+"/"+Entity.human_attribute_name(c.name), "entity-"+c.name]}.sort
  #   columns += EntityAddress.content_columns.collect{|c| [EntityAddress.model_name.human+"/"+EntityAddress.human_attribute_name(c.name), "address-"+c.name]}.sort
  #   columns += EntityNature.content_columns.collect{|c| [EntityNature.model_name.human+"/"+EntityNature.human_attribute_name(c.name), "entity_nature-"+c.name]}.sort
  #   columns += EntityCategory.content_columns.collect{|c| [EntityCategory.model_name.human+"/"+EntityCategory.human_attribute_name(c.name), "entity_category-"+c.name]}.sort
  #   columns += CustomField.all.collect{|c| [CustomField.model_name.human+"/"+c.name, "custom_field-id"+c.id.to_s]}.sort
  #   return columns
  # end


  def self.import(file, cols, options={})
    sheet = Ekylibre::CSV.open(file)
    header = sheet.shift # header
    problems = {}
    line_index = 1
    code  = "ActiveRecord::Base.transaction do\n"
    unless cols[:entity_nature].is_a? Hash
      code += "  nature = EntityNature.where('title=? OR name=?', '-', '-').first\n"
      code += "  nature = EntityNature.create!(:title => '', :name => '-', :physical => false, :in_name => false, :active => true) unless nature\n"
    end
    unless cols[:entity_category].is_a? Hash
      code += "  category = EntityCategory.where('name=? or code=?', '-', '-').first\n"
      code += "  category = EntityCategory.create!(:name => '-', :by_default => false) unless category\n"
    end
    for k, v in (cols[:special]||{}).select{|k, v| v == :generate_string_custom_field}
      code += "  custom_field_#{k} = CustomField.create!(:name => #{header[k.to_i].inspect}, :active => true, :length_max => 65536, :nature => 'string', :required => false)\n"
    end
    code += "  while line = sheet.shift\n"
    code += "    line_index += 1\n"
    code += "    next if #{options[:ignore].collect{|x| x.to_i}.inspect}.include?(line_index)\n" if options[:ignore]
    if cols[:entity_nature].is_a? Hash
      code += "    nature = EntityNature.where("+cols[:entity_nature].collect{|k,v| ":#{v} => line[#{k}]"}.join(', ')+").first\n"
      code += "    begin\n"
      code += "      nature = EntityNature.create!("+cols[:entity_nature].collect{|k,v| ":#{v} => line[#{k}]"}.join(', ')+")\n"
      code += "    rescue\n"
      code += "      nature = EntityNature.where('abbreviation=? OR name=?', '-', '-').first\n"
      code += "      nature = EntityNature.create!(:abbreviation => '-', :name => '-', :physical => false, :in_name => false, :active => true) unless nature\n"
      code += "    end unless nature\n"
    end
    if cols[:entity_category].is_a? Hash
      code += "    category = EntityCategory.where("+cols[:entity_category].collect{|k,v| ":#{v} => line[#{k}]"}.join(', ')+").first\n"
      code += "    begin\n"
      code += "      category = EntityCategory.create!("+cols[:entity_category].collect{|k,v| ":#{v} => line[#{k}]"}.join(', ')+")\n"
      code += "    rescue\n"
      code += "      category = EntityCategory.where('name=? or code=?', '-', '-').first\n"
      code += "      category = EntityCategory.create!(:name => '-', :by_default => false) unless category\n"
      code += "    end unless category\n"
    end

    # code += "    puts [nature, category].inspect\n"

    code += "    entity = Entity.build("+cols[:entity].collect{|k,v| ":#{v} => line[#{k}]"}.join(', ')+", :nature_id => nature.id, :category_id => category.id, :language => #{self.of_company.language.inspect}, :client => true)\n"
    code += "    if entity.save\n"
    if cols[:address].is_a? Hash
      code += "      address = entity.addresses.build("+cols[:address].collect{|k,v| ":#{v} => line[#{k}]"}.join(', ')+")\n"
      code += "      unless address.save\n"
      code += "        problems[line_index.to_s] ||= []\n"
      code += "        problems[line_index.to_s] += address.errors.full_messages\n"
      code += "      end\n"
    end
    for k, v in (cols[:special]||{}).select{|k,v| v == :generate_string_custom_field}
      code += "      datum = entity.custom_field_data.build(:custom_field_id => custom_field_#{k}.id, :string_value => line[#{k}])\n"
      code += "      unless datum.save\n"
      code += "        problems[line_index.to_s] ||= []\n"
      code += "        problems[line_index.to_s] += datum.errors.full_messages\n"
      code += "      end\n"
    end
    for k, v in cols[:custom_field]||{}
      if custom_field = CustomField.find_by_id(k.to_s[2..-1].to_i)
        if custom_field.nature == 'string'
          code += "      datum = entity.custom_field_data.build(:custom_field_id => #{custom_field.id}, :string_value => line[#{k}])\n"
          code += "      unless datum.save\n"
          code += "        problems[line_index.to_s] ||= []\n"
          code += "        problems[line_index.to_s] += datum.errors.full_messages\n"
          code += "      end\n"
          # elsif custom_field.nature == 'choice'
          #   code += "    co = entity.addresses.create("+cols[:address].collect{|k,v| ":#{v} => line[#{k}]"}.join(', ')+")\n" if cols[:address].is_a? Hash
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
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    eval(code)
    return {:errors => problems, :lines_count => line_index-1}
  end



  def self.export(find_options={})
    entities = Entity.find(:all, find_options)
    csv_string = Ekylibre::CSV.generate do |csv|
      csv << ["Code", "Type", "Catégorie", "Nom", "Prénom", "Dest-Service", "Bat.-Res.-ZI", "N° et voie", "Lieu dit", "Code Postal", "Ville", "Téléphone", "Mobile", "Fax", "Email", "Site Web", "Taux de réduction", "Commentaire"]
      entities.each do |entity|
        address = EntityAddress.where(:entity_id => entity.id, :by_default => true, :deleted_at => nil).first
        line = []
        line << ["'"+entity.code.to_s, entity.nature.name, entity.category.name, entity.name, entity.first_name]
        if !address.nil?
          line << [address.line_2, address.line_3, address.line_4, address.line_5, address.line_6_code, address.line_6_city, address.phone, address.mobile, address.fax ,address.email, address.website]
        else
          line << [ "", "", "", "", "", "", "", "", "", "", ""]
        end
        line << [ entity.reduction_percentage.to_s.gsub(/\./,","), entity.comment]
        csv << line.flatten
      end
    end
    return csv_string
  end



  def preference(name, value = nil, nature = :string)
    p = self.preferences.find(:first, :order => :id, :conditions => {:name => name})
    if p.nil?
      p = self.preferences.build
      p.name   = name
      p.nature = nature.to_s
      p.value  = value
      p.save!
    end
    return p
  end


  def rights_array
    self.rights.to_s.split(/\s+/).collect{|x| x.to_sym}
  end

  def rights_array=(array)
    narray = array.select{|x| Entity.rights_list.include? x.to_sym}.collect{|x| x.to_sym}
    self.rights = narray.join(" ")
    return narray
  end

  def diff_more(right_markup = 'div', separator='')
    return '<div>&infin;</div>'.html_safe if self.admin?
    (self.rights_array-self.role.rights_array).select{|x| Entity.rights_list.include?(x)}.collect{|x| "<#{right_markup}>"+::I18n.t("rights.#{x}")+"</#{right_markup}>"}.join(separator).html_safe
  end


  def diff_less(right_markup = 'div', separator='')
    return '' if self.admin?
    (self.role.rights_array-self.rights_array).select{|x| Entity.rights_list.include?(x)}.collect{|x| "<#{right_markup}>"+::I18n.t("rights.#{x}")+"</#{right_markup}>"}.join(separator).html_safe
  end

  def password
    @password
  end

  def password=(passwd)
    @password = passwd
    unless self.password.blank?
      self.salt = Entity.generate_password(64)
      self.hashed_password = Entity.encrypted_password(self.password, self.salt)
    end
  end

  # Find and check user account
  def self.authenticate(user_name, password)
    if user = self.find_by_user_name_and_loggable(user_name.to_s.downcase, true)
      if user.locked or !user.authenticated?(password.to_s)
        user = nil
      end
    end
    return user
  end

  def authorization(controller_name, action_name, rights_list=nil)
    rights_list = self.rights_array if rights_list.blank?
    message = nil
    if Entity.rights[controller_name.to_sym].nil?
      message = tc(:no_right_defined_for_this_part_of_the_application, :controller => controller_name, :action => action_name)
    elsif (rights = Entity.rights[controller_name.to_sym][action_name.to_sym]).nil?
      message = tc(:no_right_defined_for_this_part_of_the_application, :controller => controller_name, :action => action_name)
    elsif (rights & [:__minimum__, :__public__]).empty? and (rights_list & rights).empty? and not self.admin?
      message = tc(:no_right_defined_for_this_part_of_the_application_and_this_user)
    end
    return message
  end

  def can?(right)
    self.admin? or self.rights.match(/(^|\s)#{right}(\s|$)/)
  end

  protect(:on => :destroy) do
    Entity.count > 1
  end

  def authenticated?(password)
    self.hashed_password == Entity.encrypted_password(password, self.salt)
  end

  # Used for generic password creation
  def self.give_password(length=8, mode=:complex)
    Entity.generate_password(length, mode)
  end

  private

  def self.encrypted_password(password, salt)
    string_to_hash = "<"+password.to_s+":"+salt.to_s+"/>"
    Digest::SHA256.hexdigest(string_to_hash)
  end

  def self.generate_password(password_length=8, mode=:normal)
    return '' if password_length.blank? or password_length<1
    case mode
    when :dummy then
      letters = %w(a b c d e f g h j k m n o p q r s t u w x y 3 4 6 7 8 9)
    when :simple then
      letters = %w(a b c d e f g h j k m n o p q r s t u w x y A B C D E F G H J K M N P Q R T U W Y X 3 4 6 7 8 9)
    when :normal then
      letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9)
    else
      letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9 _ = + - * | [ ] { } . : ; ! ? , § µ % / & < >)
    end
    letters_length = letters.length
    password = ''
    password_length.times{password+=letters[(letters_length*rand).to_i]}
    password
  end


  def self.initialize_rights
    definition = YAML.load_file(Entity.rights_file)
    # Expand actions
    for right, attributes in definition
      if attributes
        attributes['actions'].each_index do |index|
          unless attributes['actions'][index].match(/\:\:/)
            attributes['actions'][index] = attributes['controller'].to_s+"::"+attributes['actions'][index]
          end
        end if attributes['actions'].is_a? Array
      end
    end
    definition.delete_if{|k, v| k == "__not_used__" }
    @@rights_list = definition.keys.sort.collect{|x| x.to_sym}.delete_if{|k, v| k.to_s.match(/^__.*__$/)}
    @@rights = {}
    @@useful_rights = {}
    for right, attributes in definition
      if attributes.is_a? Hash
        unless attributes["controller"].blank?
          controller = attributes["controller"].to_sym
          @@useful_rights[controller] ||= []
          @@useful_rights[controller] << right.to_sym
        end
        for uniq_action in attributes["actions"]
          controller, action = uniq_action.split(/\W+/)[0..1].collect{|x| x.to_sym}
          @@rights[controller] ||= {}
          @@rights[controller][action] ||= []
          @@rights[controller][action] << right.to_sym
        end if attributes["actions"].is_a? Array
      end
    end
  end

  Entity.initialize_rights

end
