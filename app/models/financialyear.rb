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
# == Table: financialyears
#
#  closed       :boolean          not null
#  code         :string(12)       not null
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  started_on   :date             not null
#  stopped_on   :date             not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#

class Financialyear < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :company
  has_many :account_balances, :class_name=>AccountBalance.name, :foreign_key=>:financialyear_id
  has_many :records,  :class_name=>JournalRecord.name
  has_many :journal_records
  validates_presence_of :started_on, :stopped_on
  validates_uniqueness_of :code, :scope=>:company_id

  #
  def before_validation
    self.stopped_on = self.started_on+1.year if self.stopped_on.blank? and self.started_on
    self.stopped_on = self.stopped_on.end_of_month unless self.stopped_on.blank?
    if self.started_on and self.stopped_on and code.blank?
      self.code = self.default_code
    end
    self.code.upper!
    if self.company
      while self.company.financialyears.count(:conditions=>["code=? AND id!=?",self.code, self.id||0]) > 0 do
        self.code.succ!
      end
    end
  end

  #
  def validate
    unless self.stopped_on.blank? or self.started_on.blank?
      errors.add(:stopped_on, :end_of_month) unless self.stopped_on == self.stopped_on.end_of_month
      errors.add(:stopped_on, :posterior, :to=>::I18n.localize(self.started_on)) unless self.started_on < self.stopped_on
      errors.add(:stopped_on, :too_far) if (self.stopped_on - self.started_on > 366) and self.company.financialyears.find(:first, :conditions=>["stopped_on < ?", self.started_on])
      # If some financial years are already present
      id = self.id || 0
      if self.company.financialyears.find(:all, :conditions=>["id!=?", id]).size > 0
        errors.add(:started_on, :consecutive) if not self.company.financialyears.find(:first, :conditions=>["id != ? AND stopped_on=?", id, self.started_on-1]) and self.company.financialyears.find(:first, :conditions=>["stopped_on < ?", self.started_on])
        errors.add(:started_on, :overlap) if self.company.financialyears.find(:first, :conditions=>["id != ? AND ? BETWEEN started_on AND stopped_on", id, self.started_on])
        errors.add(:stopped_on, :overlap) if self.company.financialyears.find(:first, :conditions=>["id != ? AND ? BETWEEN started_on AND stopped_on", id, self.stopped_on])
      end
    end
  end
  

  def default_code
    tc("code."+(self.started_on.year!=self.stopped_on.year ? "double" : "single"), :first_year=>self.started_on.year, :second_year=>self.stopped_on.year)
  end


  # tests if the financialyear can be closed.
  def closable?(noticed_on=nil)
    noticed_on ||= Date.today
    return false if self.closed
    if previous=self.previous
      return false if self.previous.closable?
    end
    return false if self.journal_records.find(:first, :conditions=>"debit != credit")
    return (self.stopped_on < noticed_on)
  end


  def closures(noticed_on=nil)
    noticed_on ||= Date.today
    array, first_year = [], self.company.financialyears.find(:first, :order=>"started_on")
    if (first_year.nil? or first_year == self) and self.company.financialyears.size<=1
      date = self.started_on.end_of_month
      while date < noticed_on
        array << date
        date = (date+1).end_of_month
      end
    else
      array << self.stopped_on
    end
    return array
  end


  # When a financial year is closed, all the matching journals are closed too. 
  def close(to_close_on, options={})
    return false unless self.closable?
    if renew_journal = options[:renew_id].blank? ? nil : self.company.journals.find_by_id(options[:renew_id])
      new_financialyear = self.next||Financialyear.create!(:started_on=>to_close_on+1)
      balance_account =  Account.balance(self.company_id, self.started_on, self.stopped_on)
      if balance_account.size > 0
        renew_record = renew_journal.records.create!(:financialyear_id => new_financialyear.id, :company_id => self.company.id, :created_on => new_financialyear.started_on, :printed_on => new_financialyear.started_on)
        result   = 0
        gains    = self.company.account(self.company.parameter("accountancy.minor_accounts.gains").value)
        losses   = self.company.account(self.company.parameter("accountancy.minor_accounts.losses").value)
        charges  = self.company.account(self.company.parameter("accountancy.major_accounts.charges").value)
        products = self.company.account(self.company.parameter("accountancy.major_accounts.products").value)
        for account in balance_account
          if account[:number].to_s.match /^#{gains.number}/
            result += account[:balance]
          elsif account[:number].to_s.match /^#{losses.number}/
            result -= account[:balance]
          elsif account[:number].to_s.match /^(#{charges.number}|#{products.number})/
            result += account[:balance] 
          elsif account[:debit] > 0 or account[:credit] > 0
            renew_record.entries.create!(:currency_id => renew_journal.currency_id, :account_id => account[:id], :name => account[:name], :currency_debit => account[:debit], :currency_credit => account[:credit])
          end
        end
        if result > 0
          renew_record.entries.create!(:currency_id => renew_journal.currency_id, :account_id => losses.id, :name => losses.name, :currency_debit => result, :currency_credit => 0.0) 
        elsif result < 0
          renew_record.entries.create!(:currency_id => renew_journal.currency_id, :account_id => gains.id, :name => gains.name, :currency_debit => 0.0, :currency_credit => result.abs)
        end
      end
    end
    for journal in self.company.journals.find(:all, :conditions => ["closed_on < ?", to_close_on])
      journal.close(to_close_on)
    end
    self.update_attributes(:stopped_on => to_close_on, :closed => true)
  end

  # this method returns the previous financialyear.
  def previous
    return self.company.financialyears.find(:first, :conditions => {:stopped_on=>self.started_on-1})
  end
 
   # this method returns the next financialyear.
  def next
    return self.company.financialyears.find(:first, :conditions => {:started_on=>self.stopped_on+1})
  end

 
  def balance(accounts_number)
    unless accounts_number.nil?
      not_in_query, in_query, accounts_to_substract = [], [], []

      if accounts_number.include?(",")
        
        if accounts_number.include?("-")
          accounts_number.split(",").each{|a| accounts_to_substract << a.strip.gsub(/^\-/,'') if a.match(/\-/)}
          accounts_to_substract.each do |a|
            in_query << "accounts.number LIKE '#{a.upcase}%'"
          end
          balance_to_substract = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit , sum(account_balances.local_debit) as sum_debit FROM account_balances LEFT JOIN accounts ON (accounts.id = account_balances.account_id  AND account_balances.financialyear_id = #{self.id}) WHERE #{in_query.join(' OR ')} AND account_balances.company_id = #{self.company_id}")
        end
        
        in_query.clear
        accounts = accounts_number.split(",").each{|a| a.strip!}
        accounts.each do |a|
          if a.match(/^\^/)
            not_in_query << "accounts.number NOT LIKE '#{a.gsub!(/^\^/,'').upcase}%'"
          elsif not a.match(/^\-/)
            in_query << "accounts.number LIKE '#{a.upcase}%'"
          end
        end
        not_in_query = not_in_query.empty? ? "" : "AND "+not_in_query.join(" OR ")
        balance = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit , sum(account_balances.local_debit) as sum_debit FROM account_balances LEFT JOIN accounts ON (accounts.id = account_balances.account_id  AND account_balances.financialyear_id = #{self.id}) WHERE #{in_query.join(' OR ')} #{not_in_query} AND account_balances.company_id = #{self.company_id}")
        #raise Exception.new balance.inspect if accounts_number == "707,708,7097"
      else
        balance = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit, sum(account_balances.local_debit) as sum_debit FROM account_balances LEFT JOIN accounts ON (accounts.id = account_balances.account_id  AND account_balances.financialyear_id = #{self.id}) WHERE accounts.number LIKE '#{accounts_number.strip.upcase}%' AND account_balances.company_id = #{self.company_id}")
      end
    end
    #puts accounts_number.include?("-").inspect+balance[0].inspect+"!!!!!!!!!!!!!"+balance_to_substract.inspect
    #raise Exception.new balance_to_substract[0]["sum_credit"].to_d.inspect
    if accounts_number.include?("-")
      return ( (balance[0]["sum_debit"].to_f - balance[0]["sum_credit"].to_f) - (balance_to_substract[0]["sum_debit"].to_f - balance_to_substract[0]["sum_credit"].to_f) )
    else
      return (balance[0]["sum_debit"].to_f - balance[0]["sum_credit"].to_f)
    end
  end

  def compute_balances
    ## journal_entries.all group_by account_id =>refresh account_balance corresponding
    results = ActiveRecord::Base.connection.select_all("SELECT account_id, sum(journal_entries.debit) as sum_debit, sum(journal_entries.credit) as sum_credit FROM journal_entries LEFT JOIN journal_records as jr ON jr.id = journal_entries.record_id AND jr.financialyear_id = #{self.id} WHERE journal_entries.company_id =  #{self.company_id} AND draft is false GROUP BY account_id")
    results.each do |result|
      if account_balance = self.company.account_balances.find_by_financialyear_id_and_account_id(self.id, result["account_id"].to_i)
        account_balance.update_attributes!(:local_credit=>result["sum_credit"].to_d, :local_debit=>result["sum_debit"].to_d)
      else
        self.company.account_balances.create!(:financialyear_id=>self.id, :account_id=>result["account_id"].to_i, :local_credit=>result["sum_credit"].to_d, :local_debit=>result["sum_debit"].to_d)
      end
    end
  end
  
 

end
