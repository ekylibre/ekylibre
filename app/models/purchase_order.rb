# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: purchases
#
#  accounted_at                             :datetime
#  affair_id                                :integer
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  command_mode                             :string
#  confirmed_at                             :datetime
#  contract_id                              :integer
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer
#  description                              :text
#  estimate_reception_date                  :datetime
#  id                                       :integer          not null, primary key
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer
#  lock_version                             :integer          default(0), not null
#  nature_id                                :integer
#  number                                   :string           not null
#  ordered_at                               :datetime
#  payment_at                               :datetime
#  payment_delay                            :string
#  planned_at                               :datetime
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_journal_entry_id :integer
#  reference_number                         :string
#  responsible_id                           :integer
#  state                                    :string           not null
#  supplier_id                              :integer          not null
#  tax_payability                           :string           not null
#  type                                     :string
#  undelivered_invoice_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#
class PurchaseOrder < Purchase
  enumerize :command_mode, in: %i[letter fax mail oral sms market_place], default: :mail

  state_machine :state, initial: :estimate do
    state :estimate
    state :opened
    state :closed
    event :open do
      transition estimate: :opened
    end
    event :close do
      transition opened: :closed, if: :items_all_received?
    end
  end

  before_validation(on: :create) do
    self.state = :estimate
    self.ordered_at ||= created_at
  end

  scope :with_state, lambda { |state|
    where(state: state)
  }

  def self.third_attribute
    :supplier
  end

  def third
    send(third_attribute)
  end

  def purchased?
    opened?
  end

  # Globalizes taxes into an array of hash
  def deal_taxes(mode = :debit)
    return [] if deal_mode_amount(mode).zero?
    taxes = {}
    coeff = 1.to_d # (self.send("deal_#{mode}?") ? 1 : -1)
    for item in items
      taxes[item.tax_id] ||= { amount: 0.0.to_d, tax: item.tax }
      taxes[item.tax_id][:amount] += coeff * item.amount
    end
    taxes.values
  end

  def has_content_not_deliverable?
    return false unless has_content?
    deliverable = false
    for item in items
      deliverable = true if item.variant.deliverable?
    end
    !deliverable
  end

  def deliverable?
    # TODO: How to compute if it remains deliverable products
    true
    # (self.quantity - self.undelivered(:population)) > 0 and not self.invoice?
  end

  def can_generate_parcel?
    items.any? && delivery_address && opened?
  end

  def taxes_amount
    amount - pretax_amount
  end

  def has_content?
    items.any?
  end

  def items_all_received?
    # Return a boolean to check if the order has all of his items received
  end
end
