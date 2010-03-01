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
#  closed           :boolean          
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  created_on       :date             not null
#  creator_id       :integer          
#  credit           :decimal(16, 2)   default(0.0), not null
#  debit            :decimal(16, 2)   default(0.0), not null
#  financialyear_id :integer          
#  id               :integer          not null, primary key
#  journal_id       :integer          not null
#  lock_version     :integer          default(0), not null
#  number           :string(255)      not null
#  position         :integer          not null
#  printed_on       :date             not null
#  resource_id      :integer          
#  resource_type    :string(255)      
#  status           :string(1)        default("A"), not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#

class JournalRecord < ActiveRecord::Base
  acts_as_list :scope=>:financialyear
  attr_readonly :company_id, :journal_id
  belongs_to :company
  belongs_to :journal
  belongs_to :financialyear, :class_name=>Financialyear.name
  belongs_to :resource, :polymorphic=>true
  has_many :entries, :foreign_key=>:record_id, :dependent=>:destroy, :class_name=>JournalEntry.name

  validates_format_of :number, :with => /^[\dA-Z]+$/
  validates_presence_of :created_on, :printed_on

  #
  def before_validation
    self.debit  = self.entries.sum(:debit)
    self.credit = self.entries.sum(:credit)
    unless self.number
      record = self.company.journal_records.find(:last, :conditions => ["EXTRACT(MONTH FROM created_on)=? AND financialyear_id=? AND journal_id=?", self.created_on.month, self.financialyear_id, self.journal_id], :order=>:number)
      if record
        self.number = record.number.succ
      else
        self.number = '1'
      end
    end
    self.number = self.number.rjust(6, "0")
  end 
  
  #
  def validate
    if self.journal
      errors.add_o_base(:closed_journal, :on=>self.journal.closed_on.to_formatted_s) if self.created_on <= self.journal.closed_on 
      return
    end
    errors.add(:created_on, :posterior, :to=>self.printed_on) if self.printed_on > self.created_on
    if self.financialyear
      errors.add(:created_on, :out_of_financialyear, :from=>self.financialyear.started_on, :to=>self.financialyear.stopped_on) if self.created_on < self.financialyear.started_on or self.created_on > self.financialyear.stopped_on
    end
  end
  
  def before_destroy
    return false if self.created_on < self.journal.closed_on 
  end

  
  # this method computes the debit and the credit of the record.
  def refresh
    self.save
  end
  
  #determines if the record is balanced or not.
  def balanced
    self.debit == self.credit and self.debit != 0
  end

  #determines the difference between the debit and the credit from the record.
  def balance
    self.debit - self.credit 
  end

  # this method allows to lock the record.
  def close
    self.update_attribute(:closed, true)
    if self.entries.size > 0
      self.entries.each do |entrie|
        entrie.close
      end
    end
  end

  
  #this method tests if all the entries matching to the record does not edited in draft mode.
  def normalized
    return (not self.entries.exists?(:draft=>true))
  end

  # Adds an entry with the minimum informations. It computes debit and credit with the "amount".
  # If the amount is negative, the amount is put in the other column (debit or credit). Example: 
  #   record.add_debit("blabla", account, -65) # will put +65 in +credit+ column
  def add_debit(name, account, amount, options={})
    add(name, account, amount, options)
  end

  #
  def add_credit(name, account, amount, options={})
    add(name, account, amount, options.merge({:credit=>true}))
  end

  #this method creates a next record with an initialized value matching to the previous record. 
  def next
    record = self.journal.records.find(:first, :conditions=>["debit!=credit OR (debit=0 AND credit=0) AND financialyear_id = ?", self.financialyear_id], :order=>"number DESC")

    if record.nil?
     
      records= self.journal.records.find(:all, :conditions=>{:financialyear_id => self.financialyear_id, :company_id => self.company_id},:order=>"number DESC")
      JournalRecord.new({:number=>(records.nil? ? 1 : records.first.number.succ), :created_on=>(records.nil? ? self.financialyear.started_on : records.first.created_on), :printed_on=>(records.nil? ? self.financialyear.started_on : records.first.printed_on), :company_id=>self.company.id, :financialyear_id=>self.financialyear.id, :journal_id=>self.journal.id})
    else
      record
    end
  end


  private

  #
  def add(name, account, amount, options={})
    return if amount == 0
    attributes = options.merge(:name=>name)
    attributes[:account_id] = account.is_a?(Integer) ? account : account.id
    attributes[:currency_id] = self.journal.currency_id
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
