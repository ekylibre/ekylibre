# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  reconciliation_state                     :string
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

class Purchase < Ekylibre::Record::Base
  include Attachable
  include Customizable
  attr_readonly :currency, :nature_id
  enumerize :tax_payability, in: %i[at_paying at_invoicing], default: :at_invoicing
  enumerize :reconciliation_state, in: %i[to_reconcile accepted reconcile], default: :to_reconcile
  refers_to :currency
  belongs_to :delivery_address, class_name: 'EntityAddress'
  belongs_to :nature, class_name: 'PurchaseNature'
  belongs_to :payee, class_name: 'Entity', foreign_key: :supplier_id
  belongs_to :supplier, class_name: 'Entity'
  belongs_to :responsible, class_name: 'User'
  belongs_to :contract
  has_many :parcels, class_name: 'Reception'
  has_many :items, class_name: 'PurchaseItem', dependent: :destroy, inverse_of: :purchase
  has_many :products, -> { uniq }, through: :items
  has_many :fixed_assets, through: :items
  has_one :supplier_payment_mode, through: :supplier
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :confirmed_at, :estimate_reception_date, :invoiced_at, :ordered_at, :payment_at, :planned_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, :pretax_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :command_mode, :payment_delay, :reference_number, length: { maximum: 500 }, allow_blank: true
  validates :currency, :payee, :supplier, :tax_payability, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :number, :state, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :number, :state, length: { allow_nil: true, maximum: 60 }
  validates :created_at, :state, :nature, :type, presence: true
  validates :number, uniqueness: true
  validates_associated :items
  validates_delay_format_of :payment_delay

  acts_as_numbered
  accepts_nested_attributes_for :items, reject_if: proc { |item| item[:variant_id].blank? && item[:variant].blank? }, allow_destroy: true

  delegate :with_accounting, to: :nature
  delegate :third_attribute, to: :class
  scope :with_nature, ->(id) { where(nature_id: id) }

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }

  scope :of_supplier, ->(supplier) { where(supplier_id: (supplier.is_a?(Entity) ? supplier.id : supplier)) }

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }

  before_validation(on: :create) do
    self.currency ||= nature.currency if nature
  end

  before_validation do
    self.state ||= :draft
    self.created_at ||= Time.zone.now
    self.planned_at ||= self.created_at
    if payment_delay.blank? && supplier && supplier.supplier_payment_delay
      self.payment_delay = supplier.supplier_payment_delay
    end
    self.payment_at = if payment_delay.blank?
                        invoiced_at || self.planned_at
                      else
                        Delay.new(payment_delay).compute(invoiced_at || self.planned_at)
                      end
    self.pretax_amount = items.sum(:pretax_amount)
    self.amount = items.sum(:amount)
  end

  validate do
    if invoiced_at
      errors.add(:invoiced_at, :before, restriction: Time.zone.now.l) if invoiced_at > Time.zone.now
    end
  end

  after_create do
    supplier.add_event(:purchase_creation, updater.person) if updater
  end

  def self.affair_class
    "#{name}Affair".constantize
  end

  def default_currency
    currency || nature.currency
  end

  def precision
    Nomen::Currency.find(currency).precision
  end

  def refresh
    save
  end

  def self.third_attribute
    :supplier
  end

  def third
    send(third_attribute)
  end

  # Computes an amount (with or without taxes) of the undelivered products
  # - +column+ can be +:amount+ or +:pretax_amount+
  def undelivered(column)
    sum  = send(column)
    sum -= parcels.sum(column)
    sum.round(2)
  end

  # Save the last date when the purchase was confirmed
  def confirm(confirmed_at = nil)
    return false unless can_confirm?
    reload
    self.confirmed_at ||= confirmed_at || Time.zone.now
    save!
    super
  end

  def label
    number # tc('label', :supplier => self.supplier.full_name.to_s, :address => self.delivery_address.mail_coordinate.to_s)
  end

  # Prints human name of current state
  def state_label
    self.class.state_machine.state(state.to_sym).human_name
  end

  def supplier_address
    if supplier.default_mail_address
      return supplier.default_mail_address.mail_coordinate
    end
    nil
  end

  def client_address
    Entity.of_company.default_mail_address.mail_coordinate
  end

  def sepable?
    cash_mode = OutgoingPaymentMode.mode_sepa.first

    cash_mode &&
      currency == cash_mode.cash.currency &&
      payee.iban.present? &&
      payee.bank_account_holder_name.present?
  end
end
