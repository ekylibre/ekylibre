# == Schema Information
#
# Table name: accounts
#
#  id           :integer       not null, primary key
#  number       :string(16)    not null
#  alpha        :string(16)    
#  name         :string(208)   not null
#  label        :string(255)   not null
#  deleted      :boolean       not null
#  usable       :boolean       not null
#  groupable    :boolean       not null
#  keep_entries :boolean       not null
#  transferable :boolean       not null
#  letterable   :boolean       not null
#  pointable    :boolean       not null
#  is_debit     :boolean       not null
#  last_letter  :string(8)     
#  comment      :text          
#  parent_id    :integer       default(0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
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
    index = -2
    parent_account = Account.find(:last, :conditions => {:company_id => self.company_id, :number => self.number.to_s[0..index]})
   # raise Exception.new('p:'+parent_account.inspect)
    while parent_account.nil? and index.abs <= self.number.length do
      index += -1
      parent_account = Account.find(:last, :conditions => {:company_id => self.company_id, :number => self.number.to_s[0..index]})
    end
#    raise Exception.new('p_account: '+parent_account.inspect+':'+index.abs.to_s+':'+self.number.to_s)
    self.update_attribute(:parent_id, parent_account.id) unless parent_account.nil? 

  end

  # This method is called after the account is created or updated.
  def after_save
    sub_accounts = Account.find(:all, :conditions => ["id <> ? AND company_id = ? AND parent_id = ? AND number LIKE ?", self.id, self.company_id, self.parent_id, self.number+'%'])
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
  def compute(company, financialyear)
    debit = self.entries.sum(:debit, :conditions => {:company_id => company}, :joins => "INNER JOIN journal_records r ON r.id=entries.record_id AND r.financialyear_id ="+financialyear.to_s).to_f
    credit = self.entries.sum(:credit, :conditions => {:company_id => company}, :joins => "INNER JOIN journal_records r ON r.id=entries.record_id AND r.financialyear_id ="+financialyear.to_s).to_f
 
    balance = {}
    unless debit.zero? and credit.zero? 
      balance[:id] = self.id.to_i
      balance[:number] = self.number.to_i
      balance[:name] = self.name.to_s
      balance[:debit] = debit
      balance[:credit] = credit
      balance[:solde] = credit - debit if self.number.to_s.match /^(6|7)/ or self.number.to_s.match /^12/
    end
    balance unless balance.empty?
  end

  # this method loads the balance for a given period.
  def self.balance(company, from, to)
    balance = []
    accounts = Account.find(:all, :conditions => {:company_id => company})
    accounts.each do |account| 
      debit = account.entries.sum(:debit, :conditions =>["CAST(r.created_on AS DATE) BETWEEN ? AND ?", from, to ], :joins => "INNER JOIN journal_records r ON r.id=entries.record_id").to_f
      credit = account.entries.sum(:credit, :conditions =>["CAST(r.created_on AS DATE) BETWEEN ? AND ?", from, to ], :joins => "INNER JOIN journal_records r ON r.id=entries.record_id").to_f
      
      unless debit.zero? and credit.zero? 
        compute={}
        compute[:number] = account.number.to_i
        compute[:name] = account.name.to_s
        compute[:debit] = debit
        compute[:credit] = credit
        compute[:solde] = credit - debit 
        balance << compute
      end
    end
    balance.compact
  end

  # this method loads the genreal ledger for all the accounts.
  def self.ledger(company, from, to)
    ledger = []
    accounts = Account.find(:all, :conditions => {:company_id => company})
    accounts.each do |account|
      compute={}
      compute[:number] = account.number.to_i
      compute[:name] = account.name.to_s
      entries = account.entries.find(:all, :conditions =>["CAST(r.created_on AS DATE) BETWEEN ? AND ?", from, to ], :joins => "INNER JOIN journal_records r ON r.id=entries.record_id")
      if entries.size > 0
        compute[:entries] = {}
        entries.each do |entry|
          compute[:entries][:date] = entry.record.created_on
          compute[:entries][:name] = entry.name.to_s
          compute[:entries][:number_record] = entry.record.number
          compute[:entries][:journal] = entry.record.journal.name.to_s
          compute[:entries][:credit] = entry.record.credit
          compute[:entries][:debit] = entry.record.debit
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

