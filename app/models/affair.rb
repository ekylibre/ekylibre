# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
#  deals_count      :integer          default(0), not null
#  debit            :decimal(19, 4)   default(0.0), not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  third_id         :integer          not null
#  third_role       :string(255)      not null
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
  AFFAIRABLE_TYPES = %w(Gap Sale Purchase IncomingPayment OutgoingPayment Transfer).freeze
  AFFAIRABLE_MODELS = AFFAIRABLE_TYPES.map(&:underscore).freeze
  enumerize :third_role, in: [:client, :supplier], predicates: true
  belongs_to :third, class_name: "Entity"
  belongs_to :journal_entry
  has_many :gaps,              inverse_of: :affair, dependent: :nullify
  has_many :sales,             inverse_of: :affair, dependent: :nullify
  has_many :purchases,         inverse_of: :affair, dependent: :nullify
  has_many :incoming_payments, inverse_of: :affair, dependent: :nullify
  has_many :outgoing_payments, inverse_of: :affair, dependent: :nullify
  has_many :transfers,         inverse_of: :affair, dependent: :nullify
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :credit, :debit, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :third_role, allow_nil: true, maximum: 255
  validates_inclusion_of :closed, in: [true, false]
  validates_presence_of :credit, :currency, :debit, :third, :third_role
  #]VALIDATORS]
  validates_inclusion_of :third_role, in: self.third_role.values

  before_validation do
    deals = self.deals
    self.debit, self.credit, self.deals_count = 0, 0, deals.count
    for deal in deals
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
        # account = third.account(deal.class.affairable_options[:third])
        account = third.account(deal.deal_third_role)
        hash[account.id] ||= 0
        hash[account.id] += deal.deal_debit_amount - deal.deal_credit_amount
      end
      hash
    end.delete_if{|k, v| v.zero?}
    b.journal_entry(Journal.used_for_affairs, printed_on: (all_deals.last ? all_deals.last.dealt_on.to_date : Date.today), :if => (self.debit == self.credit and !thirds.empty?)) do |entry|
      for account_id, amount in thirds
        entry.add_debit(label, account_id, amount)
      end
    end
  end


  # Removes empty affairs
  def self.clean_deads
    self.where("journal_entry_id NOT IN (SELECT id FROM #{connection.quote_table_name(:journal_entries)})" + AFFAIRABLE_TYPES.collect do |type|
                 model = type.constantize
                 " AND id NOT IN (SELECT #{model.reflections[:affair].foreign_key} FROM #{connection.quote_table_name(model.table_name)})"
               end.join).delete_all
  end


  def balance
    self.debit - self.credit
  end

  def refresh!
    self.reload
    self.save!
  end

  def losing?
    self.debit < self.credit
  end

  # Adds a gap to close the affair
  def finish(thirds_repartition = nil)
    balance = self.balance.abs
    return false if balance.zero?
    thirds = affair.thirds
    if thirds_repartition.nil?
      thirds_repartition = thirds.inject({}) do |hash, third|
        hash[third.id] = balance * self.third_ratio(third)
        hash
      end
    end
    if thirds_repartition.values.sum != balance
      raise StandardError, "Cannot finish"
    end
    
    for third in thirds
      attributes = {amount: balance, currency: self.currency, entity: self.third, direction: (self.debit > self.credit ? :loss : :profit), items: {}}
      self.gaps.create!(attributes)
    end
    self.refresh!
    return true
  end

  # Returns heterogen list of deals of the affair
  def deals
    return (self.gaps.to_a +
            self.sales.to_a +
            self.purchases.to_a +
            self.incoming_payments.to_a +
            self.outgoing_payments.to_a +
            self.transfers.to_a).compact.sort do |a, b|
      a.dealt_on <=> b.dealt_on
    end
  end

  # Returns all associated thirds of the affair
  def thirds
    self.deals.map(&:deal_third).uniq
  end

  def third_ratio(third)
    self.third_amount / self.amount
  end

  def third_amount(third)
    mode = (self.debit > self.credit ? :debit : :credit)
    self.deals.select do |deal|
      deal.send("deal_#{mode}?")
    end.map(&:deal_XXXX_amount)
  end

end
