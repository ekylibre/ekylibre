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
# == Table: entities
#
#  active                    :boolean          default(TRUE), not null
#  activity_code             :string(32)       
#  authorized_payments_count :integer          
#  born_on                   :date             
#  category_id               :integer          
#  client                    :boolean          not null
#  client_account_id         :integer          
#  code                      :string(16)       
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
#  id                        :integer          not null, primary key
#  invoices_count            :integer          
#  language_id               :integer          not null
#  lock_version              :integer          default(0), not null
#  name                      :string(255)      not null
#  nature_id                 :integer          not null
#  origin                    :string(255)      
#  payment_delay_id          :integer          
#  payment_mode_id           :integer          
#  photo                     :string(255)      
#  proposer_id               :integer          
#  reduction_rate            :decimal(8, 2)    
#  reflation_submissive      :boolean          not null
#  responsible_id            :integer          
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

class Entity < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :client_account, :class_name=>Account.to_s
  belongs_to :category, :class_name=>EntityCategory.to_s
  belongs_to :company
  belongs_to :language
  belongs_to :nature, :class_name=>EntityNature.to_s
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :payment_mode
  belongs_to :proposer, :class_name=>Entity.to_s
  belongs_to :responsible, :class_name=>User.name
  belongs_to :supplier_account, :class_name=>Account.to_s
  has_many :bank_accounts, :dependent=>:destroy
  has_many :complement_data
  has_many :contacts, :conditions=>{:active=>true}
  has_many :direct_links, :class_name=>EntityLink.name, :foreign_key=>:entity1_id
  has_many :events
  has_many :indirect_links, :class_name=>EntityLink.name, :foreign_key=>:entity2_id
  has_many :invoices, :foreign_key=>:client_id, :order=>"created_on desc"
  has_many :mandates
  has_many :observations
  has_many :payments
  has_many :prices
  has_many :purchase_orders, :foreign_key=>:supplier_id
  has_many :sale_orders, :foreign_key=>:client_id, :order=>"created_on desc"
  has_many :trackings, :foreign_key=>:producer_id
  has_many :subscriptions
  has_many :usable_payments, :conditions=>["parts_amount<amount"], :class_name=>Payment.name
  has_one :default_contact, :class_name=>Contact.name, :conditions=>{:default=>true, :active=>true}
  validates_presence_of :category_id


  def before_validation
    self.webpass = User.give_password(8, :normal) if self.webpass.blank?
    self.soundex = self.name.soundex2 if !self.name.nil?
    self.first_name = self.first_name.to_s.strip
    self.name = self.name.to_s.strip
    self.full_name = (self.name.to_s+" "+self.first_name.to_s)
    unless self.nature.nil?
      self.full_name = self.nature.abbreviation+' '+self.full_name unless (self.nature.in_name or self.nature.abbreviation == "-")
    end
    self.full_name.strip!
    
    self.code = self.full_name.codeize if self.code.blank?
    self.code = self.code[0..15]
  end

  def after_validation_on_create
    if not self.company.parameter("relations.entities.numeration").nil?
      specific_numeration = self.company.parameter("relations.entities.numeration").value
      if not specific_numeration.nil?
        self.code = specific_numeration.next_value
      end
    end
  end

  #
  def validate
    if self.nature 
      if self.nature.in_name and not self.name.match(/( |^)#{self.nature.abbreviation}( |$)/i)
        errors.add(:name, :error_missing_title, :title=>self.nature.abbreviation) 
      end
      if not self.nature.physical and not self.first_name.blank?
        errors.add(:first_name, :nature_do_not_allow_a_first_name, :nature=>self.nature.name) 
      end
    end
  end
  
  def before_destroy
    raise Exception.new("Can't delete entity of the company") if self.id == self.company.entity.id
    return false if self.id == self.company.entity.id
  end
  
  #
  def destroy_bank_account
    self.bank_accounts.find(:all).each do |bank_account|
      BankAccount.destroy bank_account
    end
  end

  def label
    self.code+'. '+self.full_name
  end

  #
  def created_on
    self.created_at.to_date
  end

  #
  def last_invoice
    self.invoices.find(:first, :order=>"created_at DESC")
  end
  
  #
  def balance
    #payments = Payment.find_all_by_entity_id_and_company_id(self.id, self.company_id).sum(:amount_with_taxes)
    payments = Payment.sum(:amount, :conditions=>{:company_id=>self.company_id, :entity_id=>self.id})
    invoices = Invoice.sum(:amount_with_taxes, :conditions=>{:company_id=>self.company_id, :client_id=>self.id})
    #invoices = Invoice.find_all_by_client_id_and_company_id(self.id, self.company_id).sum(:amount_with_taxes)
    #raise Exception.new.to_i.inspect
    payments - invoices
  end

  def reverse_balance
    self.balance*-1
  end

#   def default_contact
#     if self.contacts.size>0
#       self.contacts.find_by_default(true)
#     else
#       nil
#     end
#   end

  def has_another_tracking?(serial, product_id)
    self.trackings.find(:all, :conditions=>["serial=? AND product_id!=? ", serial, product_id]).size > 0
  end


  # this method creates automatically an account for the entity
  def account(nature=:client, suffix=nil)
    nature = :supplier if nature != :client
    a = nil
    a = self.send(nature.to_s+'_account') unless self.send(nature.to_s+'_account_id').nil?
    if a.nil?
      prefix = (nature == :client ? 411 : 401)
      suffix ||= self.code
      suffix = suffix.upper_ascii[0..5].rjust(6,'0')
      account = 1
      #x=Time.now
      i = 0
      while not account.nil? do
        account = self.company.accounts.find(:first, :conditions => ["number LIKE ?", prefix.to_s+suffix.to_s])
        suffix.succ! unless account.nil?
        i=i+1
      end    
      #puts "Find entity (#{x-Time.now}s) :"+i.to_s
      a = self.company.accounts.create(:number=>prefix.to_s+suffix.to_s, :name=>self.full_name)
      self.update_attribute(nature.to_s+'_account_id', a.id)
    end
    return a
  end


  
  # this method creates automatically an account for the entity
  def create_update_account(nature = :client, suffix = nil)
    self.account(nature, suffix)
  end

#   def find_or_create_account(nature = :client)
#     prefix = nature == :client ? 411 : 401
#     if self.client and self.client_account_id.nil?
      
#       #last = self.company.accounts.find(:first, :conditions=>["number like ?",'%411'],:order=>"number desc")
#       #account = self.company.create!(:number=>last.number.succ, :name=>self.full_name).id
#       #raise Exception.new self.inspect
#       account = self.create_update_account(:client).id
#       self.client_account_id = account
#       self.save
#     else
#       account = self.client_account_id
#     end
#     account
#   end

  def warning
    count = self.observations.find_all_by_importance("important").size
    #count += self.balance<0 ? 1 : 0
  end

  def add_event(nature, user_id)
    user = self.company.users.find_by_id(user_id)
    if user
      event_natures = self.company.event_natures.find_all_by_usage(nature.to_s)
      event_natures.each do |event_nature|
        self.company.events.create!(:started_at=>Time.now, :nature_id => event_nature.id, :duration=>event_nature.duration, :entity_id=>self.id, :user_id=>user.id)
      end
    end
  end

  def contact
    self.default_contact ? self.default_contact.address : '[NoDefaultContactError]'
  end

  def max_reduction_rate(computed_on=Date.today)
    # Subscription.count_by_sql(["SELECT max(reduction_rate) FROM subscriptions AS s JOIN subscription_natures ON (s.nature_id = subscription_natures.id) WHERE s.entity_id = ? AND s.company_id = ? AND ? BETWEEN s.started_on AND s.stopped_on", self.id, self.company_id, computed_on]).to_f
    Subscription.maximum(:reduction_rate, :joins=>"JOIN subscription_natures AS sn ON (subscriptions.nature_id = sn.id) LEFT JOIN entity_links AS el ON (el.nature_id = sn.entity_link_nature_id AND subscriptions.entity_id IN (entity1_id, entity2_id))", :conditions=>["? IN (subscriptions.entity_id, entity1_id, entity2_id) AND ? BETWEEN subscriptions.started_on AND subscriptions.stopped_on AND subscriptions.company_id = ?", self.id, computed_on, self.company_id]).to_f
  end
  
  def description
    desc = self.code+". "+self.full_name
    c = self.default_contact
    desc += " ("+c.line_6+")" unless c.nil?
    desc
  end

  def destroyable?
    self.id != self.company.entity_id
  end

end 
