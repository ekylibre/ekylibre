# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  accounted_at        :datetime
#  affair_id           :integer
#  amount              :decimal(19, 4)   default(0.0), not null
#  confirmed_at        :datetime
#  created_at          :datetime         not null
#  creator_id          :integer
#  currency            :string           not null
#  delivery_address_id :integer
#  description         :text
#  id                  :integer          not null, primary key
#  invoiced_at         :datetime
#  journal_entry_id    :integer
#  lock_version        :integer          default(0), not null
#  nature_id           :integer
#  number              :string           not null
#  planned_at          :datetime
#  pretax_amount       :decimal(19, 4)   default(0.0), not null
#  reference_number    :string
#  responsible_id      :integer
#  state               :string
#  supplier_id         :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class Purchase < Ekylibre::Record::Base
  include Attachable
  attr_readonly :currency, :nature_id
  belongs_to :delivery_address, class_name: "EntityAddress"
  belongs_to :journal_entry
  belongs_to :nature, class_name: "PurchaseNature"
  belongs_to :payee, class_name: "Entity", foreign_key: :supplier_id
  belongs_to :supplier, class_name: "Entity"
  belongs_to :responsible, class_name: "User"
  has_many :deliveries, class_name: "IncomingDelivery"
  has_many :documents, :as => :owner
  has_many :items, class_name: "PurchaseItem", dependent: :destroy, inverse_of: :purchase
  has_many :journal_entries, :as => :resource
  has_many :products, -> { uniq }, :through => :items
  has_many :financial_assets, :through => :items
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :accounted_at, :confirmed_at, :invoiced_at, :planned_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :amount, :pretax_amount, allow_nil: true
  validates_presence_of :amount, :currency, :number, :payee, :pretax_amount, :supplier
  #]VALIDATORS]
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :number, :state, allow_nil: true, maximum: 60
  validates_presence_of :created_at, :currency, :state, :nature
  validates_uniqueness_of :number

  acts_as_numbered
  acts_as_affairable :supplier
  accepts_nested_attributes_for :items, :reject_if => :all_blank, :allow_destroy => true

  delegate :closed, to: :affair, prefix: true

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }

  scope :unpaid, -> { where(state: ["order", "invoice"]).joins(:affair).where("NOT closed") }
  scope :current, lambda { unpaid }
  scope :current_or_self, lambda { |purchase| where(unpaid).or(where(id: (purchase.is_a?(Purchase) ? purchase.id : purchase))) }
  scope :of_supplier, lambda { |supplier| where(supplier_id: (supplier.is_a?(Entity) ? supplier.id : supplier)) }

  state_machine :state, :initial => :draft do
    state :draft
    state :estimate
    state :refused
    state :order
    state :invoice
    state :aborted
    event :propose do
      transition :draft => :estimate, if: :has_content?
    end
    event :correct do
      transition [:estimate, :refused, :order] => :draft
    end
    event :refuse do
      transition :estimate => :refused, if: :has_content?
    end
    event :confirm do
      transition :estimate => :order, if: :has_content?
    end
    event :invoice do
      transition :order => :invoice, if: :has_content?
      transition :estimate => :invoice, if: :has_content_not_deliverable?
    end
    event :abort do
      transition [:draft, :estimate] => :aborted # , :order
    end
  end

  before_validation(on: :create) do
    self.state ||= :draft
    self.currency = self.nature.currency if self.nature
  end

  before_validation do
    self.created_at ||= Time.now
    self.planned_at ||= self.created_at
    self.pretax_amount = self.items.sum(:pretax_amount)
    self.amount = self.items.sum(:amount)
  end

  validate do
    if self.invoiced_at
      errors.add(:invoiced_at, :before, restriction: Time.now.l) if self.invoiced_at > Time.now
    end
  end

  after_create do
    self.supplier.add_event(:purchase_creation, self.updater.person) if self.updater
  end

  # This method permits to add journal entries corresponding to the purchase order/invoice
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    b.journal_entry(self.nature.journal, printed_on: self.invoiced_on, if: self.invoice?) do |entry|
      label = tc(:bookkeep, :resource => self.class.model_name.human, :number => self.number, :supplier => self.supplier.full_name, :products => (self.description.blank? ? self.items.collect{|x| x.name}.to_sentence : self.description))
      for item in self.items
        # TODO 1.2 - add if statement for depreciable method during purchase
        if item.variant.depreciable? and item.depreciation?
          puts "CASE DEPRECIATION".inspect.red
           entry.add_debit(label, (item.variant.financial_asset_account), item.pretax_amount) unless item.pretax_amount.zero?
           # create the financial_asset
           puts item.inspect.green
           financial_asset = item.financial_assets.create!(name: item.name,
                                                           depreciable_amount: item.pretax_amount,
                                                           depreciation_method: :simplified_linear,
                                                           started_on: item.purchase.invoiced_at.to_date,
                                                           depreciation_percentage: item.variant.depreciation_rate,
                                                           journal_id: Journal.where(nature: :various).first,
                                                           allocation_account: item.variant.financial_asset_depreciations_account, #28
                                                           charges_account: item.variant.financial_asset_depreciations_inputations_expenses_account #68
                                                           )
           puts financial_asset.inspect.yellow
        else
         puts "CASE PURCHASE".inspect.red
         entry.add_debit(label, (item.account||item.variant.purchases_account), item.pretax_amount) unless item.pretax_amount.zero?
        end
        entry.add_debit(label, (item.account||item.variant.purchases_account), item.pretax_amount) unless item.pretax_amount.zero?
        entry.add_debit(label, item.tax.deduction_account_id, item.taxes_amount) unless item.taxes_amount.zero?
      end
      entry.add_credit(label, self.supplier.account(:supplier).id, self.amount)
    end
  end

  def invoiced_on
    self.dealt_at.to_date
  end

  def dealt_at
    return (self.invoice? ? self.invoiced_at : self.created_at)
  end

  # Globalizes taxes into an array of hash
  def deal_taxes(mode = :debit)
    return [] if self.deal_mode_amount(mode).zero?
    taxes = {}
    coeff = (1).to_d # (self.send("deal_#{mode}?") ? 1 : -1)
    for item in self.items
      taxes[item.tax_id] ||= {amount: 0.0.to_d, tax: item.tax}
      taxes[item.tax_id][:amount] += coeff * item.amount
    end
    return taxes.values
  end

  def refresh
    self.save
  end

  def has_content?
    self.items.any?
  end

  def purchased?
    return (self.order? or self.invoice?)
  end

  def has_content_not_deliverable?
    return false unless self.has_content?
    deliverable = false
    for item in self.items
      deliverable = true if item.variant.deliverable?
    end
    return !deliverable
  end

  # Computes an amount (with or without taxes) of the undelivered products
  # - +column+ can be +:amount+ or +:pretax_amount+
  def undelivered(column)
    sum  = self.send(column)
    sum -= self.deliveries.sum(column)
    sum.round(2)
  end

  def deliverable?
    # TODO How to compute if it remains deliverable products
    return true
    # (self.quantity - self.undelivered(:population)) > 0 and not self.invoice?
  end

  # Save the last date when the purchase was confirmed
  def confirm(confirmed_at = Time.now)
    return false unless self.can_confirm?
    self.reload
    self.confirmed_at ||= confirmed_at
    self.save!
    return super
  end

  # Save the last date when the invoice of purchase was received
  def invoice(invoiced_at = Time.now)
    return false unless self.can_invoice?
    self.reload
    self.invoiced_at ||= invoiced_at
    self.save!
    return super
  end

  def label
    self.number# tc('label', :supplier => self.supplier.full_name.to_s, :address => self.delivery_address.mail_coordinate.to_s)
  end

  # Need for use in list
  def quantity
    ''
  end

  # Prints human name of current state
  def state_label
    tc('states.'+self.state.to_s)
  end

  def status
    #if self.accounted_at == nil
    #  return (self.invoice? ? :caution : :stop)
    #elsif self.accounted_at
    #  return :go
    #end
    if self.invoice?
      return self.affair.status
    end
    return :stop
  end

  def supplier_address
    if self.supplier.default_mail_address
      return self.supplier.default_mail_address.mail_coordinate
    end
    return nil
  end

  def client_address
    return Entity.of_company.default_mail_address.mail_coordinate
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end

end
