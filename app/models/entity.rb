# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
#  active                    :boolean          default(TRUE), not null
#  activity_code             :string(32)       
#  attorney                  :boolean          not null
#  attorney_account_id       :integer          
#  authorized_payments_count :integer          
#  born_on                   :date             
#  category_id               :integer          
#  client                    :boolean          not null
#  client_account_id         :integer          
#  code                      :string(64)       
#  comment                   :text             
#  company_id                :integer          not null
#  country                   :string(2)        
#  created_at                :datetime         not null
#  creator_id                :integer          
#  dead_on                   :date             
#  deliveries_conditions     :string(60)       
#  discount_rate             :decimal(8, 2)    
#  ean13                     :string(13)       
#  excise                    :string(15)       
#  first_met_on              :date             
#  first_name                :string(255)      
#  full_name                 :string(255)      not null
#  hashed_password           :string(64)       
#  id                        :integer          not null, primary key
#  invoices_count            :integer          
#  language                  :string(3)        default("???"), not null
#  last_name                 :string(255)      not null
#  lock_version              :integer          default(0), not null
#  locked                    :boolean          not null
#  name                      :string(32)       
#  nature_id                 :integer          not null
#  origin                    :string(255)      
#  payment_delay_id          :integer          
#  payment_mode_id           :integer          
#  photo                     :string(255)      
#  proposer_id               :integer          
#  prospect                  :boolean          not null
#  reduction_rate            :decimal(8, 2)    
#  reflation_submissive      :boolean          not null
#  responsible_id            :integer          
#  salt                      :string(64)       
#  siren                     :string(9)        
#  soundex                   :string(4)        
#  supplier                  :boolean          not null
#  supplier_account_id       :integer          
#  transporter               :boolean          not null
#  updated_at                :datetime         not null
#  updater_id                :integer          
#  vat_number                :string(15)       
#  vat_submissive            :boolean          default(TRUE), not null
#  webpass                   :string(255)      
#  website                   :string(255)      
#


class Entity < CompanyRecord
  acts_as_numbered :code
  attr_readonly :company_id
  belongs_to :attorney_account, :class_name=>"Account"
  belongs_to :client_account, :class_name=>"Account"
  belongs_to :category, :class_name=>"EntityCategory"
  belongs_to :company
  belongs_to :nature, :class_name=>"EntityNature"
  belongs_to :payment_delay, :class_name=>"Delay"
  belongs_to :payment_mode, :class_name=>"IncomingPaymentMode"
  belongs_to :proposer, :class_name=>"Entity"
  belongs_to :responsible, :class_name=>"User"
  belongs_to :supplier_account, :class_name=>"Account"
  has_many :cashes, :dependent=>:destroy
  has_many :contacts, :conditions=>{:deleted_at=>nil}
  has_many :custom_field_data
  has_many :direct_links, :class_name=>"EntityLink", :foreign_key=>:entity_1_id
  has_many :events
  has_many :godchildren, :class_name=>"Entity", :foreign_key=>"proposer_id"
  has_many :incoming_payments, :foreign_key=>:payer_id
  has_many :indirect_links, :class_name=>"EntityLink", :foreign_key=>:entity_2_id
  has_many :mandates
  has_many :observations
  has_many :prices
  has_many :purchase_invoices, :class_name=>"Purchase", :foreign_key=>:supplier_id, :order=>"created_on desc", :conditions=>{:state=>"invoice"}
  has_many :purchases, :foreign_key=>:supplier_id
  has_many :outgoing_deliveries, :foreign_key=>:transporter_id
  has_many :outgoing_payments, :foreign_key=>:payee_id
  has_many :sales_invoices, :class_name=>"Sale", :foreign_key=>:client_id, :order=>"created_on desc", :conditions=>{:state=>"invoice"}
  has_many :sales, :foreign_key=>:client_id, :order=>"created_on desc"
  has_many :sale_lines
  has_many :subscriptions
  has_many :trackings, :foreign_key=>:producer_id
  has_many :transfers, :foreign_key=>:supplier_id
  has_many :transports, :foreign_key=>:transporter_id
  has_many :transporter_sales, :foreign_key=>:transporter_id, :order=>"created_on desc", :class_name=>"Sale"
  has_many :usable_incoming_payments, :conditions=>["used_amount < amount"], :class_name=>"IncomingPayment", :foreign_key=>:payer_id
  has_many :waiting_deliveries, :class_name=>"OutgoingDelivery", :foreign_key=>:transporter_id, :conditions=>["moved_on IS NULL AND planned_on <= CURRENT_DATE"]
  has_one :default_contact, :class_name=>"Contact", :conditions=>{:by_default=>true}
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :discount_rate, :reduction_rate, :allow_nil => true
  validates_length_of :country, :allow_nil => true, :maximum => 2
  validates_length_of :language, :allow_nil => true, :maximum => 3
  validates_length_of :soundex, :allow_nil => true, :maximum => 4
  validates_length_of :siren, :allow_nil => true, :maximum => 9
  validates_length_of :ean13, :allow_nil => true, :maximum => 13
  validates_length_of :excise, :vat_number, :allow_nil => true, :maximum => 15
  validates_length_of :activity_code, :name, :allow_nil => true, :maximum => 32
  validates_length_of :deliveries_conditions, :allow_nil => true, :maximum => 60
  validates_length_of :code, :hashed_password, :salt, :allow_nil => true, :maximum => 64
  validates_length_of :first_name, :full_name, :last_name, :origin, :photo, :webpass, :website, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :attorney, :client, :locked, :prospect, :reflation_submissive, :supplier, :transporter, :vat_submissive, :in => [true, false]
  validates_presence_of :company, :full_name, :language, :last_name, :nature
  #]VALIDATORS]
  validates_presence_of :category
  validates_uniqueness_of :code, :scope=>:company_id


  before_validation do
    self.webpass = User.give_password(8, :normal) if self.webpass.blank?
    self.soundex = self.last_name.soundex2 if !self.last_name.nil?
    self.first_name = self.first_name.to_s.strip
    self.last_name  = self.last_name.to_s.strip
    self.full_name = (self.last_name.to_s+" "+self.first_name.to_s)
    unless self.nature.nil?
      self.full_name = (self.nature.title+' '+self.full_name).strip unless self.nature.in_name # or self.nature.abbreviation == "-")
    end
    self.full_name.strip!
  end

  #
  validate do
    if self.nature 
      if self.nature.in_name and not self.last_name.match(/( |^)#{self.nature.title}( |$)/i)
        errors.add(:last_name, :missing_title, :title=>self.nature.title)
      end
      # if not self.nature.physical and not self.first_name.blank?
      #   errors.add(:first_name, :nature_do_not_allow_a_first_name, :nature=>self.nature.name) 
      # end
    end
  end
    
  protect_on_destroy do
    #raise Exception.new("Can't delete entity of the company") if self.id == self.company.entity.id
    return false if self.id == self.company.entity.id or self.sales_invoices.size > 0
    return true
  end

  def self.exportable_columns
    self.content_columns.delete_if{|c| [:active, :lock_version, :webpass, :soundex, :photo, :deliveries_conditions].include?(c.name.to_sym)}
  end


  def label
    self.code+'. '+self.full_name
  end

  #
  def created_on
    self.created_at.to_date
  end

  
  def last_incoming_payment
    self.incoming_payments.find(:first, :order=>"updated_at DESC")
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
    self.trackings.find(:all, :conditions=>["serial=? AND product_id!=? ", serial, product_id]).size > 0
  end


  # This method creates automatically an account for the entity for its usage (client, supplier...)
  def account(nature)
    natures = {:client=>:client_account, :supplier=>:supplier_account, :attorney=>:attorney_account}
    raise ArgumentError.new("Unknown nature #{nature.inspect} (#{natures.keys.to_sentence} are accepted)") unless natures.keys.include? nature
    valid_account = self.send(natures[nature])
    if valid_account.nil?
      prefix = self.company.preferred("third_#{nature.to_s.pluralize}_accounts")
      if self.company.prefer_use_entity_codes_for_account_numbers?
        number = prefix.to_s+self.code.to_s
        valid_account = self.company.accounts.find_by_number(number)
        valid_account = self.company.accounts.create(:number=>number, :name=>self.full_name, :reconcilable=>true) unless valid_account
      else
        suffix = "1"
        suffix = suffix.upper_ascii[0..5].rjust(6, '0')
        account = 1
        #x=Time.now
        i = 0
        while not account.nil? do
          account = self.company.accounts.find(:first, :conditions => ["number LIKE ?", prefix.to_s+suffix.to_s])
          suffix.succ! unless account.nil?
          i=i+1
        end    
        # puts "Find entity (#{x-Time.now}s) :"+i.to_s
        valid_account = self.company.accounts.create(:number=>prefix.to_s+suffix.to_s, :name=>self.full_name, :reconcilable=>true)
      end
      self.reload.update_attribute("#{natures[nature]}_id", valid_account.id)
    end
    return valid_account
  end

  def warning
    count = self.observations.find_all_by_importance("important").size
    #count += self.balance<0 ? 1 : 0
  end

  def add_event(nature, user_id)
    user = self.company.users.find_by_id(user_id)
    if user
      event_natures = self.company.event_natures.find_all_by_usage(nature.to_s)
      event_natures.each do |event_nature|
        self.company.events.create!(:started_at=>Time.now, :nature_id => event_nature.id, :duration=>event_nature.duration, :entity_id=>self.id, :responsible_id=>user.id)
      end
    end
  end

  def contact
    self.default_contact ? self.default_contact.address : '[NoDefaultContactError]'
  end

  def max_reduction_percent(computed_on=Date.today)
    Subscription.maximum(:reduction_rate, :joins=>"JOIN #{SubscriptionNature.table_name} AS sn ON (#{Subscription.table_name}.nature_id = sn.id) LEFT JOIN #{EntityLink.table_name} AS el ON (el.nature_id = sn.entity_link_nature_id AND #{Subscription.table_name}.entity_id IN (entity_1_id, entity_2_id))", :conditions=>["? IN (#{Subscription.table_name}.entity_id, entity_1_id, entity_2_id) AND ? BETWEEN #{Subscription.table_name}.started_on AND #{Subscription.table_name}.stopped_on AND #{Subscription.table_name}.company_id = ? AND COALESCE(#{Subscription.table_name}.sale_id, 0) NOT IN (SELECT id FROM #{Sale.table_name} WHERE company_id=? AND state='estimate')", self.id, computed_on, self.company_id, self.company_id]).to_f*100||0.0
  end
  
  def description
    desc = self.code+". "+self.full_name
    c = self.default_contact
    desc += " ("+c.line_6.to_s+")" unless c.nil?
    desc
  end

  def merge_with(entity)
    raise Exception.new("Base entity is not mergeable") if entity.id == entity.company.entity_id
    ActiveRecord::Base.transaction do
      # Classics
      for many in [:cashes, :direct_links, :events, :godchildren, :indirect_links, :mandates, :observations, :prices, :purchases, :outgoing_deliveries, :outgoing_payments, :sales, :sale_lines, :incoming_payments, :subscriptions, :trackings, :transfers, :transports, :transporter_sales]
        ref = self.class.reflections[many]
        ref.class_name.constantize.update_all({ref.primary_key_name=>self.id}, {ref.primary_key_name=>entity.id})
      end
      # Contact
      Contact.update_all(["code = '0'||SUBSTR(code, 2, 3), entity_id=?, by_default=? ", self.id, false], {:entity_id => entity.id})
      
      # Add observation
      observation = "Merged entity (ID=#{entity.id}) :\n"
      for attr, value in entity.attributes.sort
        observation += " - #{Entity.human_attribute_name(attr)} : #{entity.send(attr).to_s}\n"
      end
      for custom_field_datum in entity.custom_field_data
        observation += " * #{custom_field_datum.custom_field.name} : #{custom_field_datum.value.to_s}\n"
        custom_field_datum.destroy
      end
      self.observations.create!(:description=>observation, :importance=>"normal")

      # Remove doublon
      entity.destroy
    end
  end


end 
