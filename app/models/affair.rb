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
#  lock_version     :integer          default(0), not null
#  third_id         :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#

# Where to put amounts. The point of view is us
#       Deal      |  Debit  |  Credit |
# Sale            |         |    X    |
# SaleCredit      |    X    |         |
# Purchase        |    X    |         |
# PurchaseCredit  |         |    X    |
# IncomingPayment |    X    |         |
# OutgoingPayment |         |    X    |
# ProfitGap       |    X    |         |
# LossGap         |         |    X    |
# Transfer        |         |    X    |
#
class Affair < Ekylibre::Record::Base
  AFFAIRABLE_TYPES = ["Sale", "Purchase", "IncomingPayment", "OutgoingPayment"].freeze # , "Transfer"
  AFFAIRABLE_MODELS = AFFAIRABLE_TYPES.map(&:underscore).freeze
  belongs_to :third, class_name: "Entity"
  belongs_to :journal_entry
  has_many :sales, :inverse_of => :affair, :dependent => :nullify
  has_many :purchases, :inverse_of => :affair, :dependent => :nullify
  has_many :incoming_payments, :inverse_of => :affair, :dependent => :nullify
  has_many :outgoing_payments, :inverse_of => :affair, :dependent => :nullify
  has_many :transfers, :inverse_of => :affair, :dependent => :nullify
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :credit, :debit, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_inclusion_of :closed, :in => [true, false]
  validates_presence_of :credit, :currency, :debit, :third
  #]VALIDATORS]

  before_validation do
    self.debit, self.credit = 0, 0
    for deal in self.deals
      self.debit  += deal.deal_debit_amount
      self.credit += deal.deal_credit_amount
    end
    # Check state
    if self.credit == self.debit # and self.debit != 0
      self.closed = true
      self.closed_at = Time.now
    else
      self.closed = false
      self.closed_at = nil
    end
  end

  # after_save do
  #   if self.deals.size.zero? and !self.journal_entry
  #     self.destroy
  #   end
  # end

  bookkeep do |b|
    label = tc(:bookkeep)
    all_deals = self.deals
    thirds = all_deals.inject({}) do |hash, deal|
      if third = deal.deal_third
        account = third.account(deal.class.affairable_options[:third])
        hash[account.id] ||= 0
        hash[account.id] += deal.deal_debit_amount - deal.deal_credit_amount
      end
      hash
    end.delete_if{|k, v| v.zero?}
    b.journal_entry(Journal.various.first, :printed_on => (all_deals.last ? all_deals.last.dealt_on : Date.today), :if => (self.debit == self.credit and !thirds.empty?)) do |entry|
      for account_id, amount in thirds
        entry.add_debit(label, account_id, amount)
      end
    end
  end


  # Removes empty affairs
  def self.clean_deads
    self.where("journal_entry_id NOT IN (SELECT id FROM #{connection.quote_table_name(:journal_entries)})" + AFFAIRABLE_TYPES.collect do |type|
                 model = type.constantize
                 " AND id NOT IN (SELECT #{model.reflections[model.affairable_options[:reflection]].foreign_key} FROM #{connection.quote_table_name(model.table_name)})"
               end.join).delete_all
  end


  def balance
    self.debit - self.credit
  end


  # Adds a deal in the affair
  # Checks if possible and updates amounts
  def attach(deal)
    if deal.currency != self.currency
      raise ArgumentError.new("The deal currency (#{deal.currency}) is different of the affair currency(#{self.currency})")
    end
    deal.affair = self
    deal.save!
    return self.reload
  end

  # Removes a deal from the affair
  # Checks if possible and updates amounts
  def detach(deal)
    deal.affair = nil
    deal.save!
    self.save!
    return self.reload
  end

  # Returns heterogen list of deals of the affair
  def deals
    return (self.sales.to_a +
            self.purchases.to_a +
            self.incoming_payments.to_a +
            self.outgoing_payments.to_a +
            self.transfers.to_a).compact.sort do |a, b|
      a.dealt_on <=> b.dealt_on
    end
  end

end
