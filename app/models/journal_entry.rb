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
# == Table: journal_entries
#
#  closed          :boolean          
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
#  draft           :boolean          not null
#  draft_mode      :boolean          not null
#  id              :integer          not null, primary key
#  journal_id      :integer          not null
#  lock_version    :integer          default(0), not null
#  number          :string(255)      not null
#  position        :integer          
#  printed_on      :date             not null
#  resource_id     :integer          
#  resource_type   :string(255)      
#  updated_at      :datetime         not null
#  updater_id      :integer          
#

class JournalEntry < ActiveRecord::Base
  acts_as_list :scope=>:journal
  after_save :set_draft
  attr_readonly :company_id, :journal_id, :created_on
  belongs_to :company
  belongs_to :currency
  belongs_to :journal
  belongs_to :resource, :polymorphic=>true
  has_many :lines, :foreign_key=>:entry_id, :dependent=>:delete_all, :class_name=>JournalEntryLine.name
  has_many :invoices, :dependent=>:nullify
  has_many :purchase_payments, :dependent=>:nullify
  has_many :purchase_payment_parts, :dependent=>:nullify
  has_many :sale_payments, :dependent=>:nullify
  has_many :sale_payment_parts, :dependent=>:nullify
  validates_presence_of :currency
  validates_format_of :number, :with => /^[\dA-Z]+$/
  validates_numericality_of :currency_rate, :greater_than=>0

  #
  def prepare
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
    self.created_on = Date.today
    # self.draft = (self.draft_mode or not self.balanced?)
    if self.draft_mode
      self.draft = true
    else
      self.draft = (self.balanced? ? false : true)
    end
    if self.journal and not self.number
      self.number ||= self.journal.next_number 
    end
  end 
  
  def check_on_update
    old = self.class.find(self.id)
    errors.add_to_base(:entry_has_been_already_validated) if old.closed?
  end
  
  #
  def check
    return unless self.created_on
    if self.journal
      if self.printed_on <= self.journal.closed_on
        errors.add_to_base(:closed_journal, :journal=>self.journal.name, :on=>::I18n.localize(self.journal.closed_on))
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
  
  def set_draft
    JournalEntryLine.update_all({:draft=>self.draft}, ["entry_id = ? AND draft != ? ", self.id, self.draft])
  end

  def destroyable?
    self.printed_on > self.journal.closed_on and not self.closed?
  end

  def updatable?
    self.printed_on > self.journal.closed_on and not self.closed?
  end

  #determines if the entry is balanced or not.
  def balanced?
    self.debit == self.credit and self.lines.count > 0
  end
  
  def confirmed?
    not self.draft and not self.closed?
  end

  
  # this method computes the debit and the credit of the entry.
  def refresh
    self.reload
    self.save!
  end

  def financial_year
    self.company.financial_years.find(:first, :conditions=>['? BETWEEN started_on AND stopped_on', self.printed_on], :order=>"id")
  end
  
  #determines the difference between the debit and the credit from the entry.
  def balance
    self.debit - self.credit 
  end


  # Add a entry which cancel the entry
  # Create counter-entry_lines
  def cancel
    entry = self.class.new(:journal=>self.journal, :resource=>self.resource, :currency=>self.currency, :currency_rate=>self.currency_rate, :printed_on=>self.printed_on, :draft_mode=>self.draft_mode?)
    ActiveEntry::Base.transaction do
      entry.save!
      for entry_line in self.lines
        entry.send(:add!, tc(:entry_cancel, :number=>self.number, :name=>entry_line.name), entry_line.account, (entry_line.debit-entry_line.credit).abs, :credit=>(entry_line.debit>0))
      end
    end
    return entry
  end

  # Cancel a journal entry and return a journal entry which can be used to 
  # be refilled with entry_lines
  def __reset(attributes={})
    entry = nil
    if self.draft?
      self.lines.destroy_all
      entry = self
    else
      self.cancel
      entry = self.journal.entries.create!({:resource=>self.resource, :printed_on=>self.printed_on, :draft_mode=>self.draft_mode?}.merge(attributes))
    end
    return entry
  end

  # this method allows to lock the entry.
  def close
    self.update_attribute(:closed, true)
    if self.lines.size > 0
      for entry_line in self.lines
        entry_line.close
      end
    end
  end

  def reopen
    if self.lines.size > 0
      for entry_line in self.lines
        entry_line.reopen
      end
    end    
    self.update_attribute(:closed, false)
  end

  def save_with_entry_lines(entry_lines)
    ActiveEntry::Base.transaction do
      saved = self.save
      self.lines.clear
      entry_lines.each_index do |index|
        entry_lines[index] = self.lines.build(entry_lines[index])
        if saved
          saved = false unless entry_lines[index].save
        end
      end
      self.reload if saved
      if saved and not self.balanced?
        self.errors.add_to_base(:unbalanced) 
        saved = false
      end
      if saved
        return true
      else
        raise ActiveEntry::Rollback
      end
    end
    return false
  end


  
  #this method tests if all the entry_lines matching to the entry does not edited in draft mode.
  def normalized
    return (not self.lines.exists?(:draft=>true))
  end

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
