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
# == Table: cashes
#
#  account_id   :integer          not null
#  address      :text             
#  agency_code  :string(255)      
#  bank_code    :string(255)      
#  bank_name    :string(50)       
#  bic          :string(16)       
#  by_default   :boolean          not null
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  currency_id  :integer          not null
#  entity_id    :integer          
#  iban         :string(34)       
#  iban_label   :string(48)       
#  id           :integer          not null, primary key
#  journal_id   :integer          not null
#  key          :string(255)      
#  lock_version :integer          default(0), not null
#  mode         :string(255)      default("IBAN"), not null
#  name         :string(255)      not null
#  nature       :string(16)       default("bank_account"), not null
#  number       :string(255)      
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Cash < CompanyRecord
  @@natures = ["bank_account", "cash_box"]
  @@modes = ["iban", "bban"]
  @@bban_translations = {:fr=>["abcdefghijklmonpqrstuvwxyz", "12345678912345678923456789"]}  

  attr_readonly :company_id, :nature
  belongs_to :account
  belongs_to :company
  belongs_to :currency
  belongs_to :entity
  belongs_to :journal
  has_many :bank_statements
  has_many :deposits
  has_many :outgoing_payment_modes
  has_many :incoming_payment_modes
  has_one :last_bank_statement, :class_name=>"BankStatement", :order=>"stopped_on DESC"
  validates_inclusion_of :mode, :in=>%w( iban bban )
  validates_uniqueness_of :account_id
  # validates_presence_of :bank_name
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :bic, :nature, :allow_nil => true, :maximum => 16
  validates_length_of :iban, :allow_nil => true, :maximum => 34
  validates_length_of :iban_label, :allow_nil => true, :maximum => 48
  validates_length_of :bank_name, :allow_nil => true, :maximum => 50
  validates_length_of :agency_code, :bank_code, :key, :mode, :name, :number, :allow_nil => true, :maximum => 255
  validates_inclusion_of :by_default, :in => [true, false]
  validates_presence_of :account, :company, :currency, :journal, :mode, :name, :nature
  #]VALIDATORS]

  
  COUNTRY_CODE_FR="FR"

  # before create a bank account, this computes automatically code iban.
  before_validation do
    self.mode.lower!
    self.mode = @@modes[0] if self.mode.blank?
    # raise Exception.new self.mode.inspect
    self.entity_id = self.company.entity_id if self.company
    self.currency ||= self.company.default_currency
    if self.use_mode?
      self.iban = self.iban.to_s.upper.gsub(/[^A-Z0-9]/, '')
    else
      self.iban = self.class.generate_iban(COUNTRY_CODE_FR, self.bank_code+self.agency_code+self.number+self.key)
    end
    self.iban_label = self.iban.split(/(\w\w\w\w)/).delete_if{|k| k.empty?}.join(" ") 
  end  
  
  # IBAN have to be checked before saved.
  validate do
    if self.bank_account?
      if self.use_mode?(:bban)
        errors.add_to_base(:unvalid_bban) unless self.class.valid_bban?(COUNTRY_CODE_FR, self.attributes)
      end
      errors.add(:iban, :invalid) unless self.class.valid_iban?(self.iban) 
    end
  end

  protect_on_destroy do
    self.deposits.size <= 0 and self.bank_statements.size <= 0
  end


  def bank_account?
    self.nature.to_s == "bank_account"
  end

  def use_mode?(value=:iban)
    self.mode.to_s.lower == value.to_s.lower
  end



  # this method returns an array .
  def self.modes
    @@modes.collect{|x| [tc('modes.'+x.to_s), x] }
  end

  def self.nature_label(name)
    tc('natures.'+name.to_s)
  end

  def nature_label
    self.class.nature_label(self.nature.to_s)
  end

  def self.natures
    @@natures.collect{|x| [self.nature_label(x), x] }
  end



  
  #this method checks if the BBAN is valid.
  def self.valid_bban?(country_code, options={})
    case cc = country_code.lower.to_sym
    when :fr
      ban = (options["bank_code"].to_s.lower.tr(*@@bban_translations[cc]).to_i*89+
             options["agency_code"].to_s.lower.tr(*@@bban_translations[cc]).to_i*15+
             options["number"].to_s.lower.tr(*@@bban_translations[cc]).to_i*3)
      return (options["key"].to_i+ban.modulo(97)-97).zero?
    else
      raise ArgumentError.new("Unknown country code #{country_code.inspect}")
    end
  end

  #this method generates the IBAN key.
  def self.generate_iban(country_code, bban)
   iban=bban+country_code+"00"
    iban.each_char do |c|
      if c=~/\D/
       iban.gsub!(c, c.to_i(36).to_s)
     end
   end
   return country_code+(98 - (iban.to_i.modulo 97)).to_s+bban
  end
  
  #this method checks if the IBAN is valid.
  def self.valid_iban?(iban) 
    iban = iban.to_s
    return false unless iban.length > 4
    str = iban[4..iban.length]+iban[0..1]+"00" 
        
    # test the iban key
    str.each_char do |c|
      if c=~/\D/
        str.gsub!(c, c.to_i(36).to_s)
      end
    end
    iban_key = 98 - (str.to_i.modulo 97)
    
    return (iban_key.to_i.eql? iban[2..3].to_i)
    
  end
  
  def formated_bban
    self.bank_code.to_s+"."+self.agency_code.to_s+"."+self.number.to_s+"."+self.key.to_s
  end


end

