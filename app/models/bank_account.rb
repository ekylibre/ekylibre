# == Schema Information
# Schema version: 20081111111111
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
#  entity_id    :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class BankAccount < ActiveRecord::Base
 
# :on => :create

 # before create a bank account, this computes automatically code iban.
 def before_validation
   #self.iban = self.key + self.agency_code
   self.iban.upper!
   self.iban.gsub!(/[^A-Z0-9]/, '')
   self.iban_label = self.iban.scan(/..../).join " "
   self.iban_label2 = self.iban
   
   self.entity_id = self.company.entity_id

 end  
  



end
