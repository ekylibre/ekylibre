# == Schema Information
# Schema version: 20080819191919
#
# Table name: journals
#
#  id             :integer       not null, primary key
#  nature_id      :integer       not null
#  name           :string(255)   not null
#  code           :string(4)     not null
#  counterpart_id :integer       
#  closed_on      :date          not null
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#

class Journal < ActiveRecord::Base
 #  validates_uniqueness_of :name 
  
#   before_create :journal_nature
#   before_destroy :journal_empty



#   # groups all the accounts corresponding to a transaction of sale.
#   ACCOUNTS_OF_SALES={:sale=>70, :tva_collected=>4457, :customer=>[411, 413, 4191], :bank=>[511, 512], :cash=>53 , 
#     :others=>[654, 661, 665] }
  
#   # groups all the accounts corresponding to a transaction of purchase.
#   ACCOUNTS_OF_PURCHASES={:purchase=>[60, 61, 62, 635], :tva_deductible=>[4452, 4456], :supplier=>[401, 403, 4091], 
#     :bank=>512, :others=>765 }


#   # Before create a journal.
#   def journal_nature()
#     begin
#       JournalNature.exists?(self.nature_id) 
#     rescue
#       raise Exception.new("The type of journal is invalide.") 
#     end 
#   end

#   # Before delete a journal.
#   def journal_empty()
#     # A journal has not to be empty.
#     if self.closed_on.split('-')[0] < Time.now.year and JournalPeriod.count.nil?
#       self.destroy
#     end
#   end

#   def close(date)
#     self.closed_on = date
#     self.save!
#   end
  

#   def journal(period)
    
#     # if the type of journal (purchase, sale, bank, cash ...) is precised. Otherwise, it deals with a standard journal. 
#     case self.nature_id
#     when "purchases"
#       ACCOUNTS_OF_PURCHASES.each_value do |account|
#         accounts +=  Account.find(:first, :conditions=>["number LIKE '?%'", account]).number
#       end
#     when "sales"
#       ACCOUNTS_OF_SALES.each_value do |account|
#         accounts +=  Account.find(:first, :conditions=>["number LIKE '?%'", account]).number
#       end
#     else
#       accounts +=  Account.find(:all).number
#     end
    
#     results = Hash.new
    
#     records = JournalRecord.find(:all,:conditions=>["period_id = ?", period])
#     records.each do |record|
#       results[record.created_on.to_sym] = Hash.new
#       result = results[results.created_on.to_sym]
#       entries = Entry.find(:all, :conditions=>["record_id = ?", record.id])
#       entries.each do |entrie|
#         account = Account.find(entrie.account_id)
#         if accounts.include? account.number
#           result[account.number.to_sym] = Hash.new
#           result[account.number.to_sym][:debit] = entrie.debit
#           result[account.number.to_sym][:credit] = entrie.credit
#           result[account.number.to_sym][:solde] = entrie.solde
#           result[account.number.to_sym][:name] = account.name
#         end
#       end
#       unless result.empty?
#         result[record.created_on.to_sym] = result 
#       end
#     end
    
  #end
  #    journals_list params
  #    @journals = @current_company.journals





end

