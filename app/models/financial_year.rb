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
    return false if self.previous and self.previous.closable?
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
  def close(to_close_on=nil, options={})
    return false unless self.closable?

    to_close_on ||= self.stopped_on

    ActiveRecord::Base.transaction do
      
      # Close journals
      for journal in self.company.journals.find(:all, :conditions => ["closed_on < ?", to_close_on])
        return false unless journal.close(to_close_on)
      end

      # Close year
      self.update_attributes(:stopped_on => to_close_on, :closed => true)

      # Compute balance of closed year
      self.compute_balances!

      # Create first entry of the new year
      if renew_journal = self.company.journals.find_by_id(options[:renew_id].to_i)
        
        if self.account_balances.size > 0
          entry = renew_journal.entries.create!(:company_id => self.company.id, :printed_on => to_close_on+1, :currency_id => renew_journal.currency_id)
          result   = 0
          gains    = self.company.account(self.company.preferred_capital_gains_accounts)
          losses   = self.company.account(self.company.preferred_capital_losses_accounts)
          charges  = self.company.account(self.company.preferred_charges_accounts)
          products = self.company.account(self.company.preferred_products_accounts)
          
          for balance in self.account_balances.joins(:account).order("number")
            if balance.account.number.to_s.match(/^(#{charges.number}|#{products.number})/)
              result += balance.balance
              # elsif balance.account.number.to_s.match(/^#{gains.number}/)
              #   result += balance.local_balance
              # elsif balance.account.number.to_s.match(/^#{losses.number}/)
              #   result += balance.local_balance
            elsif balance.balance != 0
              # TODO: Use currencies properly in account_balances !
              entry.lines.create!(:account_id => balance.account_id, :name => balance.account.name, :currency_debit => balance.balance_debit, :currency_credit => balance.balance_credit)
            end
          end

          if result > 0
            entry.lines.create!(:account_id => losses.id, :name => losses.name, :currency_debit => result, :currency_credit => 0.0) 
          elsif result < 0
            entry.lines.create!(:account_id => gains.id, :name => gains.name, :currency_debit => 0.0, :currency_credit => result.abs)
          end

        end
      end



          #   if balance.account.number.to_s.match(/^#{gains.number}/)
          #     result += account[:balance]
          #   elsif account[:number].to_s.match(/^#{losses.number}/)
          #     result -= account[:balance]
          #   elsif account[:number].to_s.match(/^(#{charges.number}|#{products.number})/)
          #     result += account[:balance] 
          #   elsif account[:debit] > 0 or account[:credit] > 0
          #     renew_entry.lines.create!(:currency_id => renew_journal.currency_id, :account_id => account[:id], :name => account[:name], :currency_debit => account[:debit], :currency_credit => account[:credit])
          #   end
          # end
          # if result > 0
          #   renew_entry.lines.create!(:currency_id => renew_journal.currency_id, :account_id => losses.id, :name => losses.name, :currency_debit => result, :currency_credit => 0.0) 
          # elsif result < 0
          #   renew_entry.lines.create!(:currency_id => renew_journal.currency_id, :account_id => gains.id, :name => gains.name, :currency_debit => 0.0, :currency_credit => result.abs)
          # end


    end
    return true
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
  # 789X will compute the balance although result is negative
  def balance(accounts, credit = false)
    normals, excepts, negatives, forceds = ["(XD)"], [], [], []
    for prefix in accounts.strip.split(/\s*[\,\s]+\s*/)
      code = prefix.gsub(/(^(\-|\^)|[CDX]+$)/, '')
      excepts   << code if prefix.match(/^\^\d+$/)
      negatives << code if prefix.match(/^\-\d+/)
      forceds   << code if prefix.match(/^\-?\d+[CDX]$/)
      normals   << code if prefix.match(/^\-?\d+[CDX]?$/)
    end
    
    balance = FinancialYear.balance_expr(credit)
    if forceds.size > 0 or negatives.size > 0
      forceds_and_negatives = forceds & negatives
      balance  = "CASE"
      balance << " WHEN "+forceds_and_negatives.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN -#{FinancialYear.balance_expr(!credit, :forced=>true)}" if forceds_and_negatives.size > 0
      balance << " WHEN "+forceds.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN #{FinancialYear.balance_expr(credit, :forced=>true)}" if forceds.size > 0
      balance << " WHEN "+negatives.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+" THEN -#{FinancialYear.balance_expr(!credit)}" if negatives.size > 0
      balance << " ELSE #{FinancialYear.balance_expr(credit)} END"
    end

    query  = "SELECT sum(#{balance}) AS balance FROM #{AccountBalance.table_name} AS ab JOIN #{Account.table_name} AS a ON (a.id=ab.account_id) WHERE a.company_id = #{self.company_id} AND ab.financial_year_id=#{self.id}"
    query << " AND ("+normals.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+")"
    query << " AND NOT ("+excepts.sort.collect{|c| "a.number LIKE '#{c}%'"}.join(" OR ")+")" if excepts.size > 0
    balance = ActiveRecord::Base.connection.select_value(query)
    # self.balance(accounts, false)
  end

  def debit_balance(accounts)
    self.balance(accounts, false)
  end

  def credit_balance(accounts)
    self.balance(accounts, true)
  end


  def self.balance_expr(credit = false, options = {})
    columns = [:debit, :credit]
    columns.reverse! if credit
    prefix = (options[:record] ? options.delete(:record).to_s + "." : "") + "local_"
    if options[:forced]
      return "(#{prefix}#{columns[0]} - #{prefix}#{columns[1]})"
    else
      return "(CASE WHEN #{prefix}#{columns[0]} > #{prefix}#{columns[1]} THEN #{prefix}#{columns[0]} - #{prefix}#{columns[1]} ELSE 0 END)"
    end
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
