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
# == Table: accounts
#
#  comment      :text             
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  is_debit     :boolean          not null
#  label        :string(255)      not null
#  last_letter  :string(8)        
#  lock_version :integer          default(0), not null
#  name         :string(208)      not null
#  number       :string(16)       not null
#  reconcilable :boolean          not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Account < CompanyRecord
  attr_readonly :company_id, :number
  belongs_to :company
  has_many :account_balances
  has_many :attorneys, :class_name=>"Entity", :foreign_key=>:attorney_account_id
  has_many :balances, :class_name=>"AccountBalance"
  has_many :cashes
  has_many :clients, :class_name=>"Entity", :foreign_key=>:client_account_id
  has_many :collected_taxes, :class_name=>"Tax", :foreign_key=>:collected_account_id
  has_many :commissioned_incoming_payment_modes, :class_name=>"IncomingPaymentMode", :foreign_key=>:commission_account_id
  has_many :depositables_incoming_payment_modes, :class_name=>"IncomingPaymentMode", :foreign_key=>:depositables_account_id
  has_many :immobilizations_products, :class_name=>"Product", :foreign_key=>:immobilizations_account_id
  has_many :journal_entry_lines
  has_many :paid_taxes, :class_name=>"Tax", :foreign_key=>:paid_account_id
  has_many :purchases_products, :class_name=>"Product", :foreign_key=>:purchases_account_id
  has_many :purchase_lines
  has_many :sale_lines
  has_many :sales_products, :class_name=>"Product", :foreign_key=>:sales_account_id
  has_many :suppliers, :class_name=>"Entity", :foreign_key=>:supplier_account_id
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :last_letter, :allow_nil => true, :maximum => 8
  validates_length_of :number, :allow_nil => true, :maximum => 16
  validates_length_of :name, :allow_nil => true, :maximum => 208
  validates_length_of :label, :allow_nil => true, :maximum => 255
  validates_inclusion_of :is_debit, :reconcilable, :in => [true, false]
  validates_presence_of :company, :label, :name, :number
  #]VALIDATORS]
  validates_format_of :number, :with=>/^\d(\d(\d[0-9A-Z]*)?)?$/
  validates_uniqueness_of :number, :scope=>:company_id

  # This method allows to create the parent accounts if it is necessary.
  before_validation do
    self.reconcilable = self.reconcilableable? if self.reconcilable.nil?
    self.label = tc(:label, :number=>self.number.to_s, :name=>self.name.to_s)
  end

  protect_on_destroy do
    dependencies = 0
    for k, v in self.class.reflections.select{|k, v| v.macro == :has_many}
      dependencies += self.send(k).size
    end
    return dependencies <= 0
  end


  # Clean ranges of accounts
  # Example : 1-3 41 43  
  def self.clean_range_condition(range, table_name=nil)
    expression = ""
    unless range.blank?
      valid_expr = /^\d(\d(\d[0-9A-Z]*)?)?$/
      for expr in range.split(/[^0-9A-Z\-\*]+/)
        if expr.match(/\-/)
          start, finish = expr.split(/\-+/)[0..1]
          next unless start < finish and start.match(valid_expr) and finish.match(valid_expr)
          expression += " #{start}-#{finish}"
        elsif expr.match(valid_expr)
          expression += " #{expr}"
        end
      end
    end
    return expression.strip
  end


  # Build an SQL condition to restrein accounts to some ranges
  # Example : 1-3 41 43  
  def self.range_condition(range, table_name=nil)
    conn = Account.connection
    conditions = []
    if range.blank?
      return conn.quoted_true
    else
      range = Account.clean_range_condition(range)
      table = table_name || Account.table_name
      for expr in range.split(/\s+/)
        if expr.match(/\-/)
          start, finish = expr.split(/\-+/)[0..1]
          max = [start.length, finish.length].max
          conditions << "#{conn.substr(table+'.number', 1, max)} BETWEEN #{conn.quote(start.ljust(max, '0'))} AND #{conn.quote(finish.ljust(max, 'Z'))}"
        else
          conditions << "#{table}.number LIKE #{conn.quote(expr+'%')}"
        end
      end
    end
    return '('+conditions.join(' OR ')+')'
  end

  # Find all available accounting systems in all languages
  def self.lists
    lists = {}
    for locale in ::I18n.active_locales
      for k, v in ::I18n.translate("accounting_systems", :locale=>locale)
        lists["#{locale}.#{k}"] = v[:name] unless v.nil? or v[:name].nil?
      end
    end
    return lists
  end


  # Check if the account is a third account and therefore returns if it should be reconcilable
  def reconcilableable?
    return (self.number.to_s.match(self.company.reconcilable_regexp) ? true : false)
  end
  

  def reconcilable_entry_lines(period, started_on, stopped_on)
    self.journal_entry_lines.find(:all, :joins=>"JOIN #{JournalEntry.table_name} AS je ON (entry_id=je.id)", :conditions=>JournalEntry.period_condition(period, started_on, stopped_on, 'je'), :order=>"letter DESC, je.number DESC, #{JournalEntryLine.table_name}.position")
  end

  def new_letter
    letter = self.last_letter
    letter = letter.blank? ? "AAA" : letter.succ
    self.update_attribute(:last_letter, letter)
    # line = self.journal_entry_lines.find(:first, :conditions=>[self.class.connection.length(self.class.connection.trim("letter"))+" > 0"], :order=>"letter DESC")
    # return (line ? line.letter.succ : "AAA")
    return letter
  end


  # Finds entry lines to mark, checks their "markability" and
  # if all valids mark all with a new letter or the first defined before
  def mark_entries(*journal_entries)
    ids = journal_entries.flatten.compact.collect{|e| e.id}
    return self.mark(self.journal_entry_lines.find(:all, :conditions=>{:entry_id=>ids}).collect{|l| l.id})
  end

  # Mark entry lines with the given +letter+. If no +letter+ given, it uses a new letter.
  # Don't mark unless all the marked lines will be balanced together
  def mark(line_ids, letter = nil)
    conditions = ["id IN (?) AND (letter IS NULL OR #{connection.length(connection.trim('letter'))} <= 0)", line_ids]
    lines = self.journal_entry_lines.find(:all, :conditions=>conditions)
    return nil unless line_ids.size > 1 and lines.size == line_ids.size and lines.collect{|l| l.debit-l.credit}.sum.to_f.zero?
    letter ||= self.new_letter
    self.journal_entry_lines.update_all({:letter=>letter}, conditions)
    return letter
  end

  # Unmark all the entry lines concerned by the +letter+
  def unmark(letter)
    self.journal_entry_lines.update_all({:letter=>nil}, {:letter=>letter})
  end

  # Check if the balance of the entry lines of the given +letter+ is zero.
  def balanced_letter?(letter)
    lines = self.journal_entry_lines.find(:all, :conditions=>["letter = ?", letter.to_s])
    return true if lines.size <= 0
    return lines.sum("debit-credit").to_f.zero? 
  end

  # Compute debit, credit, balance, balance_debit and balance_credit of the account
  # with all the entry lines
  def totals
    hash = {}
    hash[:debit]  = self.journal_entry_lines.sum(:debit)
    hash[:credit] = self.journal_entry_lines.sum(:credit)
    hash[:balance_debit] = 0.0
    hash[:balance_credit] = 0.0
    hash[:balance] = (hash[:debit]-hash[:credit]).abs 
    hash["balance_#{hash[:debit]>hash[:credit] ? 'debit' : 'credit'}".to_sym] = hash[:balance]
    return hash
  end


  def journal_entry_lines_between(started_on, stopped_on)
    self.journal_entry_lines.find(:all, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on], :order=>"printed_on, journal_entries.id, #{JournalEntryLine.table_name}.id")
  end

  def journal_entry_lines_calculate(column, started_on, stopped_on, operation=:sum)
    column = (column == :balance ? "#{JournalEntryLine.table_name}.currency_debit - #{JournalEntryLine.table_name}.currency_credit" : "#{JournalEntryLine.table_name}.currency_#{column}")
    self.journal_entry_lines.calculate(operation, column, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on])
  end




  # computes the balance for a given financial_year.
  #  def compute(company, financial_year)
  #     debit = self.journal_entry_lines.sum(:debit, :conditions => {:company_id => company}, :joins => "INNER JOIN #{JournalEntry.table_name} AS r ON r.id=journal_entry_lines.entry_id AND r.financial_year_id ="+financial_year.to_s).to_f
  #     credit = self.journal_entry_lines.sum(:credit, :conditions => {:company_id => company}, :joins => "INNER JOIN #{JournalEntry.table_name} AS r ON r.id=journal_entry_lines.entry_id AND r.financial_year_id ="+financial_year.to_s).to_f
  
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

  # This method loads the balance for a given period.
  def self.balance(company, from, to, list_accounts=[])
    balance = []
    conditions = "company_id = "+company.to_s
    if not list_accounts.empty?
      conditions += " AND "+list_accounts.collect do |account|
        "number LIKE '"+account.to_s+"%'"
      end.join(" OR ")
    end  
    accounts = Account.find(:all, :conditions => conditions, :order => "number ASC")
    #solde = 0

    res_debit = 0
    res_credit = 0
    res_balance = 0
    
    for account in accounts
      debit  = account.journal_entry_lines.sum(:debit,  :conditions =>["r.created_on BETWEEN ? AND ?", from, to], :joins => "INNER JOIN #{JournalEntry.table_name} AS r ON r.id=#{JournalEntryLine.table_name}.entry_id").to_f
      credit = account.journal_entry_lines.sum(:credit, :conditions =>["r.created_on BETWEEN ? AND ?", from, to], :joins => "INNER JOIN #{JournalEntry.table_name} AS r ON r.id=#{JournalEntryLine.table_name}.entry_id").to_f
      
      compute=HashWithIndifferentAccess.new
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
      
      # if not debit.zero? and not credit.zero?
      #         if compute[:balance] > 0  
      #           compute[:debit] = compute[:balance]
      #           compute[:credit] = 0
      #         else
      #           compute[:debit] = 0
      #           compute[:credit] = compute[:balance].abs
      #         end
      #       end
      
      #if account.number.match /^12/
      # raise Exception.new compute[:balance].to_s
      #end
      
      if account.number.match /^(6|7)/
        res_debit += compute[:debit]
        res_credit += compute[:credit]
        res_balance += compute[:balance]
      end

      #solde += compute[:balance] if account.number.match /^(6|7)/
      #      raise Exception.new solde.to_s if account.number.match /^(6|7)/    
      balance << compute
    end
    #raise Exception.new res_balance.to_s
    balance.each do |account| 
      if res_balance > 0
        if account[:number].to_s.match /^12/
          account[:debit] += res_debit
          account[:credit] += res_credit
          account[:balance] += res_balance #solde
        end
      elsif res_balance < 0
        if account[:number].to_s.match /^129/
          account[:debit] += res_debit
          account[:credit] += res_credit
          account[:balance] += res_balance #solde
        end
      end
    end
    # raise Exception.new(balance.inspect)
    balance.compact
  end
  
  # this method loads the general ledger for all the accounts.
  def self.ledger(company, from, to)
    ledger = []
    accounts = Account.find(:all, :conditions => {:company_id => company}, :order=>"number ASC")
    accounts.each do |account|
      compute=[] #HashWithIndifferentAccess.new
      
      journal_entry_lines = account.journal_entry_lines.find(:all, :conditions=>["r.created_on BETWEEN ? AND ?", from, to ], :joins=>"INNER JOIN #{JournalEntry.table_name} AS r ON r.id=#{JournalEntryLine.table_name}.entry_id", :order=>"r.number ASC")
      
      if journal_entry_lines.size > 0
        entries = []
        compute << account.number.to_i
        compute << account.name.to_s
        journal_entry_lines.each do |e|
          entry = HashWithIndifferentAccess.new
          entry[:date] = e.entry.created_on
          entry[:name] = e.name.to_s
          entry[:number_entry] = e.entry.number
          entry[:journal] = e.entry.journal.name.to_s
          entry[:credit] = e.credit
          entry[:debit] = e.debit
          entries << entry
          # compute[:journal_entry_lines] << entry
        end
        compute << entries
        ledger << compute
      end
      
    end

    ledger.compact
  end

  
end

