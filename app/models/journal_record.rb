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
# == Table: journal_records
#
#  always_draft    :boolean          not null
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
#  id              :integer          not null, primary key
#  journal_id      :integer          not null
#  lock_version    :integer          default(0), not null
#  number          :string(255)      not null
#  position        :integer          not null
#  printed_on      :date             not null
#  resource_id     :integer          
#  resource_type   :string(255)      
#  updated_at      :datetime         not null
#  updater_id      :integer          
#

class JournalRecord < ActiveRecord::Base
  acts_as_list :scope=>:journal
  attr_readonly :company_id, :journal_id, :created_on
  belongs_to :company
  belongs_to :currency
  belongs_to :journal
  belongs_to :resource, :polymorphic=>true
  has_many :entries, :foreign_key=>:record_id, :dependent=>:destroy, :class_name=>JournalEntry.name

  validates_presence_of :currency
  validates_format_of :number, :with => /^[\dA-Z]+$/
  validates_numericality_of :currency_rate, :greater_than=>0

  #
  def before_validation
    if self.journal
      self.company_id  = self.journal.company_id 
      self.currency_id = self.journal.currency_id
    end
    if self.currency
      self.currency_rate = self.currency.rate if self.currency_rate.to_f <= 0
    end
    self.currency_debit  = self.entries.sum(:currency_debit)
    self.currency_credit = self.entries.sum(:currency_credit)
    self.debit  = self.entries.sum(:debit)
    self.credit = self.entries.sum(:credit)
    self.created_on = Date.today
    if self.always_draft
      self.draft = true
    else
      self.draft = !self.balanced?
    end
    if self.journal and not self.number
      self.number ||= self.journal.next_number 
    end
  end 
  
  #
  def validate
    return unless self.created_on
    if self.journal
      if self.printed_on <= self.journal.closed_on
        errors.add_to_base(:closed_journal, :on=>::I18n.localize(self.journal.closed_on))
        return false
      end
    end
    if self.printed_on
      errors.add(:created_on, :posterior, :to=>::I18n.localize(self.printed_on)) if self.printed_on > self.created_on
    end
    if self.financialyear
      errors.add(:printed_on, :out_of_financialyear, :from=>::I18n.localize(self.financialyear.started_on), :to=>::I18n.localize(self.financialyear.stopped_on)) if self.financialyear.closed?
#       if self.printed_on < self.financialyear.started_on or self.printed_on > self.financialyear.stopped_on
#         errors.add(:printed_on, :out_of_financialyear, :from=>::I18n.localize(self.financialyear.started_on), :to=>::I18n.localize(self.financialyear.stopped_on)) 
#       end
    end
  end
  
  def after_save
    # self.entries.update_all({:draft=>self.draft}, ["draft != ? ", self.draft])
    JournalEntry.update_all({:draft=>self.draft}, ["record_id = ? AND draft != ? ", self.id, self.draft])
  end

  def before_destroy
    return false if self.printed_on < self.journal.closed_on 
  end


  def destroyable?
    self.printed_on >= self.journal.closed_on 
  end

  
  # this method computes the debit and the credit of the record.
  def refresh
    self.save!
  end

  def financialyear
    self.company.financialyears.find(:first, :conditions=>['? BETWEEN started_on AND stopped_on', self.printed_on], :order=>"id")
  end
  
  #determines if the record is balanced or not.
  def balanced?
    self.debit == self.credit and self.debit > 0
  end

  def updatable?
    self.printed_on > self.journal.closed_on
  end

  #determines the difference between the debit and the credit from the record.
  def balance
    self.debit - self.credit 
  end


  # Add a record which cancel the record
  # Create counter-entries
  def cancel
    record = self.class.new(:journal=>self.journal, :resource=>self.resource, :currency=>self.currency, :currency_rate=>self.currency_rate, :printed_on=>self.printed_on)
    ActiveRecord::Base.transaction do
      record.save!
      for entry in self.entries
        record.send(:add!, tc(:record_cancel, :number=>self.number, :name=>entry.name), entry.account, (entry.debit-entry.credit).abs, :credit=>(entry.debit>0))
      end
    end
    return record
  end

  # this method allows to lock the record.
  def close
    self.update_attribute(:closed, true)
    if self.entries.size > 0
      for entry in self.entries
        entry.close
      end
    end
  end

  def reopen
    if self.entries.size > 0
      for entry in self.entries
        entry.reopen
      end
    end    
    self.update_attribute(:closed, false)
  end

  def save_with_entries(entries)
    ActiveRecord::Base.transaction do
      saved = self.save
      self.entries.clear
      entries.each_index do |index|
        entries[index] = self.entries.build(entries[index])
        if saved
          saved = false unless entries[index].save
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
        raise ActiveRecord::Rollback
      end
    end
    return false
  end


  
  #this method tests if all the entries matching to the record does not edited in draft mode.
  def normalized
    return (not self.entries.exists?(:draft=>true))
  end

  # Adds an entry with the minimum informations. It computes debit and credit with the "amount".
  # If the amount is negative, the amount is put in the other column (debit or credit). Example: 
  #   record.add_debit("blabla", account, -65) # will put +65 in +credit+ column
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
    e = self.entries.create!(attributes)
    return e
  end

  
end
