# == Schema Information
#
# Table name: bank_accounts
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  iban         :string(34)    not null
#  iban_label   :string(48)    not null
#  bic          :string(16)    
#  deleted      :boolean       not null
#  journal_id   :integer       not null
#  currency_id  :integer       not null
#  account_id   :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  entity_id    :integer       
#  bank_code    :string(255)   
#  agency_code  :string(255)   
#  number       :string(255)   
#  key          :string(255)   
#  mode         :string(255)   default("IBAN"), not null
#  address      :text          
#  bank_name    :string(50)    
#  default      :boolean       not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class BankAccount < ActiveRecord::Base
  belongs_to :journal
  belongs_to :currency
  belongs_to :account
  belongs_to :company
  belongs_to :entity
  
  has_many :statements, :class_name=>"BankAccountStatement", :foreign_key=>:bank_account_id 
  has_many :embankments

  validates_presence_of :bank_name
    
  TABLE_BBAN = {:A=>1,:B=>2,:C=>3,:D=>4,:E=>5,:F=>6,:G=>7,:H=>8,:I=>9,:J=>1,:K=>2,:L=>3,:M=>4,:N=>5,
    :O=>6, :P=>7, :Q=>8, :R=>9, :S=>2, :T=>3, :U=>4, :V=>5, :W=>6, :X=>7, :Y=>8, :Z=>9}
  
  
  COUNTRY_CODE_FR="FR"

  # before create a bank account, this computes automatically code iban.
  def before_validation
    if self.mode=="IBAN" 
      self.iban.delete!(' ')
      self.iban.delete!('-')
    else #BBAN
     self.iban=BankAccount.generate_iban(COUNTRY_CODE_FR, self.bank_code+self.agency_code+self.number+self.key)
    end
    self.iban_label = self.iban.split(/(\w\w\w\w)/).delete_if{|k| k.empty?}.join(" ") 
  #  self.entity_id = self.company.entity_id
  end  
  
  # IBAN have to be checked before saved.
  def validate
    if self.mode=="bban"
      errors.add_to_base tc(:bban_unvalid_key) unless BankAccount.check_bban?(COUNTRY_CODE_FR, self.attributes) 
    end
    errors.add_to_base tc(:iban_unvalid_key) unless BankAccount.check_iban?(self.iban) 
  end

  # this method returns an array .
  def self.modes
    [:iban, :bban].collect{|x| [tc(x.to_s), x] }
  end

  
  #this method checks if the BBAN is valid.
  def self.check_bban?(country_code,options={})
    str=options["bank_code"]+options["agency_code"]+options["number"]
   
    # test the bban key
    str.each_char do |c|
      if c=~/\D/
        str.gsub!(c, TABLE_BBAN[c.to_sym].to_s)
        
      end
    end

    return ( (str+options["key"]).to_i.modulo 97 ).zero? 
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
  def self.check_iban?(iban) 
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

