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
# == Table: journal_entries
#
#  balance         :decimal(16, 2)   default(0.0), not null
#  company_id      :integer          not null
#  created_at      :datetime         not null
#  created_on      :date             not null
#  creator_id      :integer          
#  credit          :decimal(16, 2)   default(0.0), not null
#  currency_credit :decimal(16, 2)   default(0.0), not null
#  currency_debit  :decimal(16, 2)   default(0.0), not null
#  currency_id     :integer          default(0), not null
#  currency_rate   :decimal(16, 6)   default(0.0), not null
#  debit           :decimal(16, 2)   default(0.0), not null
#  id              :integer          not null, primary key
#  journal_id      :integer          not null
#  lock_version    :integer          default(0), not null
#  number          :string(255)      not null
#  printed_on      :date             not null
#  resource_id     :integer          
#  resource_type   :string(255)      
#  state           :string(32)       default("draft"), not null
#  updated_at      :datetime         not null
#  updater_id      :integer          
#


class JournalEntry < CompanyRecord
  attr_readonly :company_id, :journal_id, :created_on
  belongs_to :company
  belongs_to :currency
  belongs_to :journal
  belongs_to :resource, :polymorphic=>true
  has_many :useful_lines, :conditions=>["balance != ?", 0.0], :foreign_key=>:entry_id, :class_name=>"JournalEntryLine"
  has_many :lines, :foreign_key=>:entry_id, :dependent=>:delete_all, :class_name=>"JournalEntryLine"
  has_many :outgoing_payments, :dependent=>:nullify
  has_many :outgoing_payment_uses, :dependent=>:nullify
  has_many :incoming_payments, :dependent=>:nullify
  has_many :incoming_payment_uses, :dependent=>:nullify
  has_many :purchases, :dependent=>:nullify
  has_many :sales, :dependent=>:nullify
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :balance, :credit, :currency_credit, :currency_debit, :currency_rate, :debit, :allow_nil => true
  validates_length_of :state, :allow_nil => true, :maximum => 32
  validates_length_of :number, :resource_type, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  validates_presence_of :currency
  validates_format_of :number, :with => /^[\dA-Z]+$/
  validates_numericality_of :currency_rate, :greater_than=>0

  state_machine :state, :initial=>:draft do
    state :draft
    state :confirmed
    state :closed
    event :confirm do
      transition :draft=>:confirmed, :if=>:balanced?
    end
    event :close do
      transition :confirmed=>:closed, :if=>:balanced?
    end
#     event :reopen do
#       transition :closed=>:confirmed
#     end
  end

  # Build an SQL condition based on options which should contains acceptable states
  def self.state_condition(states={}, table_name=nil)
    table = table_name || self.table_name
    states = {} unless states.is_a? Hash
    if states.empty?
      return JournalEntry.connection.quoted_false
    else
      return "#{table}.state IN (#{states.collect{|s, v| JournalEntry.connection.quote(s)}.join(',')})"
    end
  end

  # Build an SQL condition based on options which should contains acceptable states
  def self.journal_condition(journals={}, table_name=nil)
    table = table_name || self.table_name
    journals = {} unless journals.is_a? Hash
    if journals.empty?
      return JournalEntry.connection.quoted_false
    else
      return "#{table}.journal_id IN (#{journals.collect{|s, v| JournalEntry.connection.quote(s.to_i)}.join(',')})"
    end
  end

  # Build a condition for filter journal entries on period
  def self.period_condition(period, started_on, stopped_on, table_name=nil)
    table = table_name || self.table_name
    if period == 'all'
      return self.connection.quoted_true
    else
      conditions = []
      started_on, stopped_on = period.to_s.split('_')[0..1] unless period == 'interval'
      if (started_on = started_on.to_date rescue nil)
        conditions << "#{table}.printed_on >= #{self.connection.quote(started_on)}"
      end
      if (stopped_on = stopped_on.to_date rescue nil)
        conditions << "#{table}.printed_on <= #{self.connection.quote(stopped_on)}"
      end
      return self.connection.quoted_false if conditions.empty?
      return '('+conditions.join(' AND ')+')'
    end
  end

  # Returns states names
  def self.states
    self.state_machine.states.collect{|x| x.name}
  end

  #
  before_validation do
    if self.journal
      self.company_id  = self.journal.company_id 
      self.currency_id = self.journal.currency_id
    end
    if self.currency
      self.currency_rate = self.currency.rate if self.currency_rate.to_f <= 0
    end
    self.currency_debit  = self.lines.sum(:currency_debit)
    self.currency_credit = self.lines.sum(:currency_credit)
    self.debit  = self.lines.sum(:debit)
    self.credit = self.lines.sum(:credit)
    self.balance = self.debit - self.credit
    self.created_on = Date.today
#     # self.draft = (self.draft_mode or not self.balanced?)
#     if self.draft_mode
#       self.draft = true
#     else
#       self.draft = (self.balanced? ? false : true)
#     end
    if self.journal and not self.number
      self.number ||= self.journal.next_number 
    end
  end 
  
  validate(:on=>:update) do
    old = self.class.find(self.id)
    errors.add_to_base(:entry_has_been_already_validated) if old.closed?
  end
  
  #
  validate do
    return unless self.created_on
    if self.journal
      if self.printed_on <= self.journal.closed_on
        errors.add_to_base(:closed_journal, :journal=>self.journal.name, :closed_on=>::I18n.localize(self.journal.closed_on))
        return false
      end
    end
#     if self.printed_on
#       errors.add(:created_on, :posterior, :to=>::I18n.localize(self.printed_on)) if self.printed_on > self.created_on
#     end
    if self.financial_year
      errors.add(:printed_on, :out_of_financial_year, :from=>::I18n.localize(self.financial_year.started_on), :to=>::I18n.localize(self.financial_year.stopped_on)) if self.financial_year.closed?
#       if self.printed_on < self.financial_year.started_on or self.printed_on > self.financial_year.stopped_on
#         errors.add(:printed_on, :out_of_financial_year, :from=>::I18n.localize(self.financial_year.started_on), :to=>::I18n.localize(self.financial_year.stopped_on)) 
#       end
    end
  end
  
  after_save do
    JournalEntryLine.update_all({:state=>self.state}, ["entry_id = ? AND state != ? ", self.id, self.state])
  end

  protect_on_destroy do
    self.printed_on > self.journal.closed_on and not self.closed?
  end

  protect_on_update do
    self.printed_on > self.journal.closed_on and not self.closed?
  end

  def self.state_label(state)
    tc('states.'+state.to_s)
  end

  # Prints human name of current state
  def state_label
    self.class.state_label(self.state)
  end

  #determines if the entry is balanced or not.
  def balanced?
    self.balance.zero? # and self.lines.count > 0
  end
  
  # this method computes the debit and the credit of the entry.
  def refresh
    self.reload
    self.save!
  end

  def financial_year
    self.company.financial_years.find(:first, :conditions=>['? BETWEEN started_on AND stopped_on', self.printed_on], :order=>"id")
  end
  
  # Add a entry which cancel the entry
  # Create counter-entry_lines
  def cancel
    reconcilable_accounts = []
    entry = self.class.new(:journal=>self.journal, :resource=>self.resource, :currency=>self.currency, :currency_rate=>self.currency_rate, :printed_on=>self.printed_on)
    ActiveRecord::Base.transaction do
      entry.save!
      for line in self.useful_lines
        entry.send(:add!, tc(:entry_cancel, :number=>self.number, :name=>line.name), line.account, (line.debit-line.credit).abs, :credit=>(line.debit>0)) 
        reconcilable_accounts << line.account if line.account.reconcilable? and not reconcilable_accounts.include?(line.account)
      end
    end
    # Mark accounts
    for account in reconcilable_accounts
      account.mark_entries(self, entry)
    end
    return entry
  end

  def save_with_lines(entry_lines)
    ActiveRecord::Base.transaction do
      saved = self.save
      self.lines.clear
      entry_lines.each_index do |index|
        entry_lines[index] = self.lines.build(entry_lines[index])
        if saved
          saved = false unless entry_lines[index].save
        end
      end
      self.reload if saved
      if saved and (not self.balanced? or self.lines.size.zero?)
        self.errors.add_to_base(:unbalanced) 
        saved = false
      end
      if saved
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    return false
  end


  
#   #this method tests if all the entry_lines matching to the entry does not edited in draft mode.
#   def normalized
#     return (not self.lines.exists?(:draft=>true))
#   end

  # Adds an entry_line with the minimum informations. It computes debit and credit with the "amount".
  # If the amount is negative, the amount is put in the other column (debit or credit). Example: 
  #   entry.add_debit("blabla", account, -65) # will put +65 in +credit+ column
  def add_debit(name, account, amount, options={})
    add!(name, account, amount, options)
  end

  #
  def add_credit(name, account, amount, options={})
    add!(name, account, amount, options.merge({:credit=>true}))
  end


  private

  #
  def add!(name, account, amount, options={})
    # return if amount == 0
    if name.size > 255
      omission = (options.delete(:omission)||"...").to_s
      name = name[0..254-omission.size]+omission
    end
    attributes = options.merge(:name=>name)
    attributes[:account_id] = account.is_a?(Integer) ? account : account.id
    # attributes[:currency_id] = self.journal.currency_id
    credit = options.delete(:credit) ? true : false
    credit = (not credit) if amount < 0
    if credit
      attributes[:currency_credit] = amount.abs
      attributes[:currency_debit]  = 0.0
    else
      attributes[:currency_credit] = 0.0
      attributes[:currency_debit]  = amount.abs
    end
    e = self.lines.create!(attributes)
    return e
  end

  
end
