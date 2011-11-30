# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2011 Brice Texier, Thibaud Merigon
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
# == Table: financial_years
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


class FinancialYear < CompanyRecord
  attr_readonly :company_id
  belongs_to :company
  has_many :account_balances, :class_name=>"AccountBalance", :foreign_key=>:financial_year_id, :dependent=>:delete_all
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :code, :allow_nil => true, :maximum => 12
  validates_inclusion_of :closed, :in => [true, false]
  validates_presence_of :code, :company, :started_on, :stopped_on
  #]VALIDATORS]
  validates_uniqueness_of :code, :scope=>:company_id

  before_validation do
    self.stopped_on = self.started_on+1.year if self.stopped_on.blank? and self.started_on
    self.stopped_on = self.stopped_on.end_of_month unless self.stopped_on.blank?
    if self.started_on and self.stopped_on and code.blank?
      self.code = self.default_code
    end
    self.code.upper!
    if self.company
      while self.company.financial_years.count(:conditions=>["code=? AND id!=?", self.code, self.id||0]) > 0 do
        self.code.succ!
      end
    end
  end

  validate do
    unless self.stopped_on.blank? or self.started_on.blank?
      errors.add(:stopped_on, :end_of_month) unless self.stopped_on == self.stopped_on.end_of_month
      errors.add(:stopped_on, :posterior, :to=>::I18n.localize(self.started_on)) unless self.started_on < self.stopped_on
      # If some financial years are already present
      id = self.id || 0
      if self.company.financial_years.find(:all, :conditions=>["id!=?", id]).size > 0
        # errors.add(:started_on, :consecutive) if not self.company.financial_years.find(:first, :conditions=>["id != ? AND stopped_on=?", id, self.started_on-1]) and self.company.financial_years.find(:first, :conditions=>["stopped_on < ?", self.started_on])
        errors.add(:started_on, :overlap) if self.company.financial_years.find(:first, :conditions=>["id != ? AND ? BETWEEN started_on AND stopped_on", id, self.started_on])
        errors.add(:stopped_on, :overlap) if self.company.financial_years.find(:first, :conditions=>["id != ? AND ? BETWEEN started_on AND stopped_on", id, self.stopped_on])
      end
    end
  end

  def journal_entries(conditions=nil)
    unless conditions.nil?
      conditions = " AND ("+self.class.send(:sanitize_sql_for_conditions, conditions)+")"
    end
    JournalEntry.find(:all, :conditions=>["company_id=? AND printed_on BETWEEN ? AND ? #{conditions}", self.company_id, self.started_on, self.stopped_on])
  end
  

  def default_code
    tc("code."+(self.started_on.year!=self.stopped_on.year ? "double" : "single"), :first_year=>self.started_on.year, :second_year=>self.stopped_on.year)
  end

  # tests if the financial_year can be closed.
  def closable?(noticed_on=nil)
    noticed_on ||= Date.today
    return false if self.closed
    if previous=self.previous
      return false if self.previous.closable?
    end
    return false unless self.journal_entries("debit != credit").empty?
    return (self.stopped_on < noticed_on)
  end


  def closures(noticed_on=nil)
    noticed_on ||= Date.today
    array, first_year = [], self.company.financial_years.find(:first, :order=>"started_on")
    if (first_year.nil? or first_year == self) and self.company.financial_years.size<=1
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
      new_financial_year = self.next||Financial_Year.create!(:started_on=>to_close_on+1)
      balance_account =  Account.balance(self.company_id, self.started_on, self.stopped_on)
      if balance_account.size > 0
        renew_entry = renew_journal.entries.create!(:financial_year_id => new_financial_year.id, :company_id => self.company.id, :created_on => new_financial_year.started_on, :printed_on => new_financial_year.started_on)
        result   = 0
        gains    = self.company.account(self.company.preferred_capital_gains_accounts)
        losses   = self.company.account(self.company.preferred_capital_losses_accounts)
        charges  = self.company.account(self.company.preferred_charges_accounts)
        products = self.company.account(self.company.preferred_products_accounts)
        for account in balance_account
          if account[:number].to_s.match /^#{gains.number}/
            result += account[:balance]
          elsif account[:number].to_s.match /^#{losses.number}/
            result -= account[:balance]
          elsif account[:number].to_s.match /^(#{charges.number}|#{products.number})/
            result += account[:balance] 
          elsif account[:debit] > 0 or account[:credit] > 0
            renew_entry.lines.create!(:currency_id => renew_journal.currency_id, :account_id => account[:id], :name => account[:name], :currency_debit => account[:debit], :currency_credit => account[:credit])
          end
        end
        if result > 0
          renew_entry.lines.create!(:currency_id => renew_journal.currency_id, :account_id => losses.id, :name => losses.name, :currency_debit => result, :currency_credit => 0.0) 
        elsif result < 0
          renew_entry.lines.create!(:currency_id => renew_journal.currency_id, :account_id => gains.id, :name => gains.name, :currency_debit => 0.0, :currency_credit => result.abs)
        end
      end
    end
    for journal in self.company.journals.find(:all, :conditions => ["closed_on < ?", to_close_on])
      journal.close(to_close_on)
    end
    self.update_attributes(:stopped_on => to_close_on, :closed => true)
  end

  # this method returns the previous financial_year.
  def previous
    return self.company.financial_years.find(:first, :conditions => {:stopped_on=>self.started_on-1})
  end
 
   # this method returns the next financial_year.
  def next
    return self.company.financial_years.find(:first, :conditions => {:started_on=>self.stopped_on+1})
  end

 
  # Computes the value of list of accounts in a String
  # 123 will take all accounts 123*
  # ^456 will remove all accounts 456*
  # 789D will take only the debit value of accounts 789*
  # 789C will take only the credit value of accounts 789*
  def balance(accounts_number)
    normals, debits, credits, excepts, negatives = [], [], [], [], []
    for prefix in accounts_number.strip.split(/\s*[\,\s]+\s*/)
      code = prefix.gsub(/(^(\-|\^)|[CD]+$)/, '')
      excepts   << code if prefix.match(/^\^\d+$/)
      negatives << code if prefix.match(/^\-\d+/)
      debits    << code if prefix.match(/^\-?\d+D$/)
      credits   << code if prefix.match(/^\-?\d+C$/)
      normals   << code if prefix.match(/^\-?\d+$/)
    end
    balance = "local_debit - local_credit"
    if debits.size > 0 or credits.size > 0
      balance = "CASE "
      balance += "WHEN "+debits.sort.collect{|d|  "a.number LIKE '#{d}%'"}.join(" OR ")+" THEN CASE WHEN local_debit > local_credit THEN local_debit - local_credit ELSE 0 END" if debits.size > 0
      balance += "WHEN "+credits.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN CASE WHEN local_debit < local_credit THEN local_credit - local_debit ELSE 0 END" if credits.size > 0
      balance += " ELSE local_debit - local_credit END"
    end

    
    #debit = (credits.size > 0 ? "CASE WHEN "+credits.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN 0 ELSE ab.local_debit END" : "local_debit")
    #credit = (debits.size > 0 ? "CASE WHEN "+debits.collect{|d| "a.number LIKE '#{d}%'"}.join(" OR ")+" THEN 0 ELSE ab.local_credit END" : "local_credit")
    if negatives.size > 0
      balance = "CASE WHEN "+negatives.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN -1 ELSE 1 END * #{balance}"
      # debit = "CASE WHEN "+negatives.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN -1 ELSE 1 END * #{debit}"
      # credit = "CASE WHEN "+negatives.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN -1 ELSE 1 END * #{credit}"
    end

    # sum(#{debit}) - sum(#{credit})
    query = "SELECT sum(#{balance}) AS balance FROM #{AccountBalance.table_name} AS ab JOIN #{Account.table_name} AS a ON (a.id=ab.account_id) WHERE a.company_id = #{self.company_id} AND ab.financial_year_id=#{self.id}"
    all_codes = normals + debits + credits
    query += " AND ("+all_codes.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+")" if all_codes.size > 0
    query += " AND NOT ("+excepts.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+")" if excepts.size > 0
    balance = ActiveRecord::Base.connection.select_value(query)
    return balance

    # unless accounts_number.nil?
    #   not_in_query, in_query, accounts_to_substract = [], [], []

    #   if accounts_number.include?(",")
        
    #     if accounts_number.include?("-")
    #       accounts_number.split(",").each{|a| accounts_to_substract << a.strip.gsub(/^\-/,'') if a.match(/\-/)}
    #       accounts_to_substract.each do |a|
    #         in_query << "accounts.number LIKE '#{a.upcase}%'"
    #       end
    #       balance_to_substract = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit , sum(account_balances.local_debit) as sum_debit FROM #{AccountBalance.table_name} AS account_balances LEFT JOIN #{Account.table_name} AS accounts ON (accounts.id = account_balances.account_id  AND account_balances.financial_year_id = #{self.id}) WHERE #{in_query.join(' OR ')} AND account_balances.company_id = #{self.company_id}")
    #     end
        
    #     in_query.clear
    #     accounts = accounts_number.split(",").each{|a| a.strip!}
    #     accounts.each do |a|
    #       if a.match(/^\^/)
    #         not_in_query << "accounts.number NOT LIKE '#{a.gsub!(/^\^/,'').upcase}%'"
    #       elsif not a.match(/^\-/)
    #         in_query << "accounts.number LIKE '#{a.upcase}%'"
    #       end
    #     end
    #     not_in_query = not_in_query.empty? ? "" : "AND "+not_in_query.join(" OR ")
    #     balance = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit , sum(account_balances.local_debit) as sum_debit FROM #{AccountBalance.table_name} AS account_balances LEFT JOIN #{Account.table_name} AS accounts ON (accounts.id = account_balances.account_id  AND account_balances.financial_year_id = #{self.id}) WHERE #{in_query.join(' OR ')} #{not_in_query} AND account_balances.company_id = #{self.company_id}")
    #     #raise Exception.new balance.inspect if accounts_number == "707,708,7097"
    #   else
    #     balance = ActiveRecord::Base.connection.select_all("SELECT sum(account_balances.local_credit) as sum_credit, sum(account_balances.local_debit) as sum_debit FROM #{AccountBalance.table_name} AS account_balances LEFT JOIN #{Account.table_name} AS accounts ON (accounts.id = account_balances.account_id  AND account_balances.financial_year_id = #{self.id}) WHERE accounts.number LIKE '#{accounts_number.strip.upcase}%' AND account_balances.company_id = #{self.company_id}")
    #   end
    # end
    # #puts accounts_number.include?("-").inspect+balance[0].inspect+"!!!!!!!!!!!!!"+balance_to_substract.inspect
    # #raise Exception.new balance_to_substract[0]["sum_credit"].to_d.inspect
    # if accounts_number.include?("-")
    #   return ( (balance[0]["sum_debit"].to_f - balance[0]["sum_credit"].to_f) - (balance_to_substract[0]["sum_debit"].to_f - balance_to_substract[0]["sum_credit"].to_f) )
    # else
    #   return (balance[0]["sum_debit"].to_f - balance[0]["sum_credit"].to_f)
    # end
  end

  # Re-create all account_balances record for the financial year
  def compute_balances!
    results = ActiveRecord::Base.connection.select_all("SELECT account_id, sum(jel.debit) AS debit, sum(jel.credit) AS credit, count(jel.id) AS count FROM #{JournalEntryLine.table_name} AS jel JOIN #{JournalEntry.table_name} AS je ON (je.id = jel.entry_id AND je.printed_on BETWEEN #{self.class.connection.quote(self.started_on)} AND #{self.class.connection.quote(self.stopped_on)}) WHERE jel.company_id = #{self.company_id} AND je.state != 'draft' GROUP BY account_id")
    self.account_balances.clear
    for result in results
      self.account_balances.create!(:account_id=>result["account_id"].to_i, :local_count=>result["count"].to_i, :local_credit=>result["credit"].to_f, :local_debit=>result["debit"].to_f)
    end
    return self
  end
  
  def print_synthesis(template)
    template = ::LibXML::XML::Document.file(template.to_s)
    root = template.root
    columns = []
    
    

    return "data"
  end

end
