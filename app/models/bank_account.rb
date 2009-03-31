# == Schema Information
# Schema version: 20090311124450
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
#

class BankAccount < ActiveRecord::Base
 #  validates_length_of :bank_code, :is => 5
#   validates_length_of :agency_code, :is => 5
#   validates_length_of :number, :is => 11
#   validates_length_of :iban, :is => 27

#  validates_numericality_of :bank_code
 # validates_numericality_of :agency_code 

# :on => :create
  
  TABLE_IBAN = {:A=>10,:B=>11,:C=>12,:D=>13,:E=>14,:F=>15,:G=>16,:H=>17,:I=>18,:J=>19,:K=>20,
           :L=>21, :M=>22, :N=>23, :O=>24, :P=>25, :Q=>26, :R=>27, :S=>28, :T=>29, :U=>30, :V=>31,
    :W=>32, :X=>33, :Y=>34, :Z=>35}
  
  
  TABLE_RIB = {:A=>1,:B=>2,:C=>3,:D=>4,:E=>5,:F=>6,:G=>7,:H=>8,:I=>9,:J=>1,:K=>2,:L=>3,:M=>4,:N=>5,
    :O=>6, :P=>7, :Q=>8, :R=>9, :S=>2, :T=>3, :U=>4, :V=>5, :W=>6, :X=>7, :Y=>8, :Z=>9}
    
  
  COUNTRY_CODE_FR="FR"
  IBAN_KEY="76"

 # before create a bank account, this computes automatically code iban.
 def before_validation
   if self.mode=="IBAN" 
     self.iban=self.iban_label
     self.iban.delete!(' ')
     self.iban.delete!('-')
   
     errors.add_to_base("") if self.iban.length < 27
     errors.add_to_base("") unless check_iban?(self.iban[4..8],self.iban[9..13],self.iban[14..24], self.iban[25..26], self.iban[2..3])
    
   else #BBAN
     #puts 'v:'+check_iban?(self.bank_code,self.agency_code,self.number,self.key).to_s
     errors.add_to_base("aie") unless check_iban?(self.bank_code,self.agency_code,self.number,self.key)
     self.iban=COUNTRY_CODE_FR+IBAN_KEY+self.bank_code+self.agency_code+self.number+self.key
     self.iban_label=self.iban    
   end

   self.entity_id = self.company.entity_id
 end  
 
 # this method returns an array .
 def self.modes
   [:iban, :rib].collect{|x| [tc(x.to_s), x] }
 end


 private
  
   #this method checks if the IBAN is valid.
   def check_iban?(bank_code, agency_code, number, key, *iban)
     valid_rib=false
     valid_iban=true

     str=bank_code+agency_code+number
    
     errors.add_to_base("") if bank_code.length!=5 or agency_code.length!=5 or number.length!=11
     errors.add_to_base("") if bank_code=~/\D/ or agency_code=~/\D/
     
     # test the rib key
     number_rib = str
     number_rib.each_char do |c|
       if c=~/\D/
         number_rib.gsub!(c, TABLE_RIB[c])
       end
     end
     
     #return false unless ((number_rib+key).to_i.modulo 97) 
     valid_rib = ( (number_rib+key).to_i.modulo 97 ).zero? 
     
     #puts 'vr:'+vr.to_s
     if valid_rib=="true"
       #test the iban key
       valid_iban = ( iban.eql? IBAN_KEY ) if iban
         #return false unless iban.eql? IBAN_KEY
       if valid_iban=="true"
       #result = (iban.eql? IBAN_KEY) ? true : false 
       # if str=~/[^\D]/ 
         # iban_key=IBAN_KEY
         # else
         number_iban = str+COUNTRY_CODE_FR+"00"
         number_iban.each_char do |c|
           if c=~/\D/
             number_iban.gsub!(c, TABLE_IBAN[c])
           end
         end
         iban_key = 98 - (number_iban.to_i.modulo 97)
         valid_iban = (iban_key.to_i.eql? IBAN_KEY)
         #return false unless iban_key.eql? IBAN_KEY
       end 
       #if iban
      # errors.add_to_base() unless iban = iban_key.to_s
       #end
       
       # if  (not (number_rib+key).to_i.modulo 97) or (not iban=iban_key.to_s)
       #    return false
       #      else
       #        return true
       #      end
     end
     puts 'vi:'+valid_iban.to_s+' vr:'+valid_rib.to_s
     if valid_rib=="true" and valid_iban=="true"
       return true
     else
       return false
     end
    
   end
 
 end

