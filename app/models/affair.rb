# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: affairs
#
#  accounted_at     :datetime         
#  closed           :boolean          not null
#  closed_at        :datetime         
#  created_at       :datetime         not null
#  creator_id       :integer          
#  credit           :decimal(19, 4)   default(0.0), not null
#  currency         :string(3)        not null
#  debit            :decimal(19, 4)   default(0.0), not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  last_deal_on     :date             
#  lock_version     :integer          default(0), not null
#  origin_id        :integer          not null
#  origin_type      :string(255)      not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#

# Where to put amounts
#       Deal      |  Debit  |  Credit |
# Sale            |         |    X    |
# SaleCredit      |    X    |         |
# Purchase        |    X    |         |
# PurchaseCredit  |         |    X    |
# IncomingPayment |    X    |         |
# OutgoingPayment |         |    X    |
#
class Affair < ActiveRecord::Base
  has_many :sales, :conditions => {:credit => false }, :inverse_of => :affair
  has_many :sale_credits, :conditions => {:credit => true }, :inverse_of => :affair
  has_many :purchases, :inverse_of => :affair
  has_many :incoming_payments, :inverse_of => :affair
  has_many :outgoing_payments, :inverse_of => :affair
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :credit, :debit, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_length_of :origin_type, :allow_nil => true, :maximum => 255
  validates_inclusion_of :closed, :in => [true, false]
  validates_presence_of :credit, :currency, :debit, :origin_type
  #]VALIDATORS]
  validates :origin_type, :inclusion => ["Sale", "Purchase", "IncomingPayment", "OutgoingPayment"]

  before_validation do
    # Sums debits
    self.debit  = 0
    self.debit -= self.sale_credits.sum(:amount).to_d # Credit amount are negative
    self.debit += self.purchases.sum(:amount).to_d
    self.debit += self.incoming_payments.sum(:amount).to_d
    # Sums credits
    self.credit = 0
    self.credit += self.sales.sum(:amount).to_d
    self.credit += self.outgoing_payments.sum(:amount).to_d
    # Check state
    if self.credit == self.debit # and self.debit != 0
      self.closed = true
      self.closed_at = Time.now
    else
      self.closed = false
      self.closed_at = nil
    end
  end

  # TODO : Finish bookkeeping
  # bookkeep do |b|
  #   label = tc(:bookkeep)
  #   thirds = {}
  #   for sale in self.sales
  #     thirds
  #   end
  #   b.journal_entry(Journal.various.first, :printed_on => self.last_deal_on, :unless => thirds.empty?) do |entry|
  #     entry.add_debit(label, attorney.id, self.amount)
  #     entry.add_credit(label,  client.id, self.amount)
  #   end
  # end


  # Adds a deal in the affair
  # Checks if possible and updates amounts
  def add(deal)
    if deal.currency != self.currency
      raise ArgumentError.new("The deal currency (#{deal.currency}) is different of the affair currency(#{self.currency})")
    end
    old_affair = deal.affair
    deal.affair = self
    deal.save!
    self.save!
    old_affair.save!
    return self
  end

end
