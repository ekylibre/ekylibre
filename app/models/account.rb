# == Schema Information
#
# Table name: accounts
#
#  alpha        :string(16)    
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  deleted      :boolean       not null
#  groupable    :boolean       not null
#  id           :integer       not null, primary key
#  is_debit     :boolean       not null
#  keep_entries :boolean       not null
#  label        :string(255)   not null
#  last_letter  :string(8)     
#  letterable   :boolean       not null
#  lock_version :integer       default(0), not null
#  name         :string(208)   not null
#  number       :string(16)    not null
#  parent_id    :integer       default(0), not null
#  pointable    :boolean       not null
#  transferable :boolean       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#  usable       :boolean       not null
#

class Account < ActiveRecord::Base
  belongs_to :company
  has_many :account_balances
  has_many :balances, :class_name=>AccountBalance.to_s
  has_many :bank_accounts
  has_many :entries
  has_many :journals, :class_name=>"Journal", :foreign_key=>:counterpart_id
  has_many :payments
  has_many :payment_modes
  has_many :products
  has_many :purchase_order_lines
  acts_as_tree
  validates_format_of :number, :with=>/[0-9][0-9]?[0-9]?[0-9A-Z]*/
 
  # This method allows to create the parent accounts if it is necessary.
  def before_validation
    self.label = self.number.to_s+' - '+self.name.to_s
    index = -252
#    raise Exception.new('a:'+self.number.to_s.length.to_s)
    parent_account = Account.find(:last, :conditions=> {:company_id => self.company_id, :number => self.number.to_s[0..index]})
   # raise Exception.new('p:'+parent_account.inspect)
    while parent_account.nil? and index.abs <= self.number.to_s.length do
      index += -1
      parent_account = Account.find(:last, :conditions => {:company_id => self.company_id, :number => self.number.to_s[0..index]})
    end
#    raise Exception.new('p_account: '+parent_account.inspect+':'+index.abs.to_s+':'+self.number.to_s)
    self.update_attribute(:parent_id, parent_account.id) unless parent_account.nil? 

  end

  # This method is called after the account is created or updated.
  def after_save
    sub_accounts = Account.find(:all, :conditions => ["id <> ? AND company_id = ? AND parent_id = ? AND number LIKE ?", self.id, self.company_id, self.parent_id, self.number.to_s+'%'])
    if sub_accounts.size > 0
      sub_accounts.each do |sub_account|
      sub_account.update_attribute(:parent_id, self.id)
      end
    end
  end
    
  # This method allows to delete the account only if it has any sub-accounts.
  def before_destroy
    errors.add_to_base tc('error_account_children') if self.children.size > 0
  end

  # This method allows to find all the parent accounts.
  def parent
    Account.find_by_id(self.parent_id)
  end
  
  # This method allows to find all the sub-accounts.
  def childrenz
    Account.find_all_by_parent_id(self.id)||{}
  end

  # computes the balance for a given financialyear.
 #  def compute(company, financialyear)
#     debit = self.entries.sum(:debit, :conditions => {:company_id => company}, :joins => "INNER JOIN journal_records r ON r.id=entries.record_id AND r.financialyear_id ="+financialyear.to_s).to_f
#     credit = self.entries.sum(:credit, :conditions => {:company_id => company}, :joins => "INNER JOIN journal_records r ON r.id=entries.record_id AND r.financialyear_id ="+financialyear.to_s).to_f
 
#     balance = {}
#     unless (debit.zero? and credit.zero?) and not self.number.to_s.match /^12/
#       balance[:id] = self.id.to_i
#       balance[:number] = self.number.to_i
#       balance[:name] = self.name.to_s
#       balance[:balance] = debit - credit
#       if debit.zero? or credit.zero?
#         balance[:debit] = debit
#         balance[:credit] = credit
#       end
#       if not debit.zero? and not credit.zero?
#         if balance[:balance] > 0  
#           balance[:debit] = balance[:balance]
#           balance[:credit] = 0
#         else
#           balance[:debit] = 0
#           balance[:credit] = balance[:balance].abs
#         end
#       end
#     end
    
#     balance unless balance.empty?
#   end

  # this method loads the balance for a given period.
  def self.balance(company, from, to, list_accounts=[])
    balance = []
    conditions = "company_id = "+company.to_s
    if not list_accounts.empty?
      conditions += " AND "+list_accounts.collect do |account|
        "number LIKE '"+account.to_s+"%'"
      end.join(" OR ")
    end  
    accounts = Account.find(:all, :conditions => conditions, :order => "number ASC")
    solde = 0
    #raise Exception.new("solde2: "+accounts.inspect) 
    accounts.each do |account| 
      debit = account.entries.sum(:debit, :conditions =>["CAST(r.created_on AS DATE) BETWEEN ? AND ?", from, to ], :joins => "INNER JOIN journal_records r ON r.id=entries.record_id").to_f
      credit = account.entries.sum(:credit, :conditions =>["CAST(r.created_on AS DATE) BETWEEN ? AND ?", from, to ], :joins => "INNER JOIN journal_records r ON r.id=entries.record_id").to_f
      
      compute={}
      compute[:id] = account.id.to_i
      compute[:number] = account.number.to_i
      compute[:name] = account.name.to_s
      compute[:debit] = debit
      compute[:credit] = credit
      compute[:balance] = debit - credit 

      if debit.zero? or credit.zero?
        compute[:debit] = debit
        compute[:credit] = credit
      end
      
      if not debit.zero? and not credit.zero?
        if compute[:balance] > 0  
          compute[:debit] = compute[:balance]
          compute[:credit] = 0
        else
          compute[:debit] = 0
          compute[:credit] = compute[:balance].abs
        end
      end
      
      solde += compute[:balance] if account.number.to_s.match /^(6|7)/
          
      balance << compute
    end
   #raise Exception.new("solde2: "+solde.to_s)
    balance.each do |account| 
       if account[:number].to_s.match /^12/
         account[:debit] = 0
         account[:credit] = 0
         account[:balance] = solde
       end
    end
   #raise Exception.new(balance.inspect)
    balance.compact
  end
  
  # this method loads the general ledger for all the accounts.
  def self.ledger(company, from, to)
    ledger = []
    accounts = Account.find(:all, :conditions => {:company_id => company})
    accounts.each do |account|
      compute={}
      compute[:number] = account.number.to_i
      compute[:name] = account.name.to_s
      entries = account.entries.find(:all, :conditions =>["CAST(r.created_on AS DATE) BETWEEN ? AND ?", from, to ], :joins => "INNER JOIN journal_records r ON r.id=entries.record_id")
      compute[:entries] = []

      if entries.size > 0
        entries.each do |e|
          entry ={}
          entry[:date] = e.record.created_on
          entry[:name] = e.name.to_s
          entry[:number_record] = e.record.number
          entry[:journal] = e.record.journal.name.to_s
          entry[:credit] = e.credit
          entry[:debit] = e.debit
          compute[:entries] << entry
        end
      end
      ledger << compute
    end
    ledger.compact
  end



  # this method loads all the entries having the given letter for the account.
  def balanced_letter?(letter) 
    entries = self.company.entries.find(:all, :conditions => ["letter = ?", letter.to_s], :joins => "INNER JOIN journal_records r ON r.id = entries.record_id INNER JOIN financialyears f ON f.id = r.financialyear_id")
   
    if entries.size > 0
      sum_debit = 0
      sum_credit = 0
      entries.each do |entry|
        sum_debit += entry.debit
        sum_credit += entry.credit
      end
      return true if sum_debit == sum_credit
    end
    return false
  end
  
end

