# == Schema Information
#
# Table name: entities
#
#  id                    :integer       not null, primary key
#  nature_id             :integer       not null
#  language_id           :integer       not null
#  name                  :string(255)   not null
#  first_name            :string(255)   
#  full_name             :string(255)   not null
#  code                  :string(16)    
#  active                :boolean       default(TRUE), not null
#  born_on               :date          
#  dead_on               :date          
#  ean13                 :string(13)    
#  soundex               :string(4)     
#  website               :string(255)   
#  client                :boolean       not null
#  supplier              :boolean       not null
#  company_id            :integer       not null
#  created_at            :datetime      not null
#  updated_at            :datetime      not null
#  created_by            :integer       
#  updated_by            :integer       
#  lock_version          :integer       default(0), not null
#  client_account_id     :integer       
#  supplier_account_id   :integer       
#  vat_submissive        :boolean       default(TRUE), not null
#  reflation_submissive  :boolean       not null
#  deliveries_conditions :string(60)    
#  discount_rate         :decimal(8, 2) 
#  reduction_rate        :decimal(8, 2) 
#  comment               :text          
#  excise                :string(15)    
#  vat_number            :string(15)    
#  country               :string(2)     
#  payments_number       :integer       
#  employee_id           :integer       
#  proposer_id           :integer       
#  payment_mode_id       :integer       
#  payment_delay_id      :integer       
#  invoices_count        :integer       
#  origin_id             :integer       
#  first_met_on          :date          
#  category_id           :integer       
#

class Entity < ActiveRecord::Base
  belongs_to :client_account, :class_name=>Account.to_s
  belongs_to :category, :class_name=>EntityCategory.to_s
  belongs_to :company
  belongs_to :employee
  belongs_to :language
  belongs_to :nature, :class_name=>EntityNature.to_s
  belongs_to :origin, :class_name=>MeetingLocation.to_s
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :payment_mode
  belongs_to :proposer, :class_name=>Entity.to_s
  belongs_to :supplier_account, :class_name=>Account.to_s
  has_many :bank_accounts
  has_many :complement_data
  has_many :contacts
  has_many :invoices, :foreign_key=>:client_id
  has_many :meetings
  has_many :prices
  has_many :purchase_orders, :foreign_key=>:supplier_id
  has_many :sale_orders, :foreign_key=>:client_id


  
  validates_presence_of :category_id, :if=>Proc.new{|u| u.client}
  attr_readonly :company_id
  
 
  #has_many :contact
  def before_validation
    
    self.soundex = self.name.soundex2 if !self.name.nil?
    self.first_name = self.first_name.to_s.strip
    self.name = self.name.to_s.strip
    unless self.nature.nil?
      self.first_name = '' unless self.nature.physical
    end
    self.full_name = (self.name.to_s+" "+self.first_name.to_s).strip
    
    self.code = self.full_name.codeize if self.code.blank?
    self.code = self.code[0..15]
    #raise Exception.new self.inspect
    #    while Entity.find(:first, :conditions=>["company_id=? AND code=? AND id!=?",self.company_id, self.code, self.id||0])
    #      self.code.succ!
    #    end

    #self.active = false  unless self.dead_on.blank?
    
    
  end

  def created_on
    self.created_at.to_date
  end

  def last_invoice
    self.invoices.find(:first, :order=>"created_at DESC")
  end
  
  def validate
    if self.nature
      #raise Exception.new self.nature.in_name.inspect
      if self.nature.in_name
        errors.add(:name, tc(:error_missing_title,:title=>self.nature.abbreviation)) unless self.name.match(/( |^)#{self.nature.abbreviation}( |$)/i)
      end
    end
  end
  
  def balance
    #payments = Payment.find_all_by_entity_id_and_company_id(self.id, self.company_id).sum(:amount_with_taxes)
    payments = Payment.sum(:amount, :conditions=>{:company_id=>self.company_id, :entity_id=>self.id})
    invoices = Invoice.sum(:amount_with_taxes, :conditions=>{:company_id=>self.company_id, :client_id=>self.id})
    #invoices = Invoice.find_all_by_client_id_and_company_id(self.id, self.company_id).sum(:amount_with_taxes)
    #raise Exception.new.to_i.inspect
    payments - invoices
  end

end 
