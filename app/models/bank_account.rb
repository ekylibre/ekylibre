# == Schema Information
# Schema version: 20090406132452
#
# Table name: bank_accounts
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  iban         :string(34)    not null
#  iban_label   :string(48)    not null
#  iban_label2  :string(48)    not null
#  bic          :string(16)    
#  deleted      :boolean       not null
#  journal_id   :integer       not null
#  currency_id  :integer       not null
#  account_id   :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#  entity_id    :integer       
#  bank_code    :string(5)     
#  agency_code  :string(5)     
#  number       :string(11)    
#  key          :string(2)     
#  mod          :string(255)   default("IBAN"), not null
#

class BankAccount < ActiveRecord::Base
  #  validates_length_of :bank_code, :is => 5
  #   validates_length_of :agency_code, :is => 5
  #   validates_length_of :number, :is => 11
  #   validates_length_of :iban, :is => 27

  #  validates_numericality_of :bank_code
  # validates_numericality_of :agency_code 

  # :on => :create
    
  TABLE_BBAN = {:A=>1,:B=>2,:C=>3,:D=>4,:E=>5,:F=>6,:G=>7,:H=>8,:I=>9,:J=>1,:K=>2,:L=>3,:M=>4,:N=>5,
    :O=>6, :P=>7, :Q=>8, :R=>9, :S=>2, :T=>3, :U=>4, :V=>5, :W=>6, :X=>7, :Y=>8, :Z=>9}
  
  
  COUNTRY_CODE_FR="FR"
 # IBAN_KEY="76"

  # before create a bank account, this computes automatically code iban.
  def before_validation
    if self.mode=="IBAN" 
      self.iban.delete!(' ')
      self.iban.delete!('-')
    else #BBAN
     self.iban=BankAccount.generate_iban(COUNTRY_CODE_FR, self.bank_code+self.agency_code+self.number+self.key)
   
      # self.iban=COUNTRY_CODE_FR+"00"+self.bank_code+self.agency_code+self.number+self.key
     # iban_key=BankAccount.generate_iban_key(self.bank_code+self.agency_code+self.number+self.key+COUNTRY_CODE_FR+"00")
   #self.iban=COUNTRY_CODE_FR+iban_key.to_s+self.bank_code+self.agency_code+self.number+self.key
    end
    self.iban_label = self.iban.split(/(\w\w\w\w)/).delete_if{|k| k.empty?}.join(" ") 
    self.entity_id = self.company.entity_id
  end  
  
  # IBAN have to be checked before saved.
  def validate
    if self.mode=="bban"
      errors.add_to_base tc(:bban_unvalid_key) unless BankAccount.check_bban?(COUNTRY_CODE_FR, self.attributes) 
    end
   # raise Exception.new('ibn2:'+self.iban.to_s)
    errors.add_to_base tc(:iban_unvalid_key) unless BankAccount.check_iban?(self.iban) 
  end

  # this method returns an array .
  def self.modes
    [:iban, :bban].collect{|x| [tc(x.to_s), x] }
  end

  
  #this method checks if the BBAN is valid.
  def self.check_bban?(country_code,options={})
#    raise Exception.new(options.inspect)
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
  # str=iban+COUNTRY_CODE_FR+"00"
   iban=bban+country_code+"00"
    iban.each_char do |c|
      if c=~/\D/
       iban.gsub!(c, c.to_i(36).to_s)
     end
   end
   return country_code+(98 - (iban.to_i.modulo 97)).to_s+bban
  end
  
  #this method checks if the IBAN is valid.
  #   def check_iban?(bank_code, agency_code, number, key, *iban)
  def self.check_iban?(iban) 
    # raise Exception.new('ibn:'+iban[2..3].to_s)
    str = iban[4..iban.length]+iban[0..1]+"00" 
    
    #     raise Exception.new(str.to_s+'a::'+str.class.to_s)  
    # test the iban key
    str.each_char do |c|
      if c=~/\D/
        str.gsub!(c, c.to_i(36).to_s)
      end
    end
    #raise Exception.new(str.to_s+'f::'+str.class.to_s)  
    iban_key = 98 - (str.to_i.modulo 97)
    
    return (iban_key.to_i.eql? iban[2..3].to_i)
    
  end
  

end

