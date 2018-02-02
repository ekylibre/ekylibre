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
# == Table: parcels
#
#  accounted_at                         :datetime
#  address_id                           :integer
#  contract_id                          :integer
#  created_at                           :datetime         not null
#  creator_id                           :integer
#  currency                             :string
#  custom_fields                        :jsonb
#  delivery_id                          :integer
#  delivery_mode                        :string
#  given_at                             :datetime
#  id                                   :integer          not null, primary key
#  in_preparation_at                    :datetime
#  intervention_id                      :integer
#  journal_entry_id                     :integer
#  late_delivery                        :boolean
#  lock_version                         :integer          default(0), not null
#  nature                               :string           not null
#  number                               :string           not null
#  ordered_at                           :datetime
#  planned_at                           :datetime         not null
#  position                             :integer
#  prepared_at                          :datetime
#  pretax_amount                        :decimal(19, 4)   default(0.0), not null
#  purchase_id                          :integer
#  recipient_id                         :integer
#  reconciliation_state                 :string
#  reference_number                     :string
#  remain_owner                         :boolean          default(FALSE), not null
#  responsible_id                       :integer
#  sale_id                              :integer
#  sender_id                            :integer
#  separated_stock                      :boolean
#  state                                :string           not null
#  storage_id                           :integer
#  transporter_id                       :integer
#  type                                 :string
#  undelivered_invoice_journal_entry_id :integer
#  updated_at                           :datetime         not null
#  updater_id                           :integer
#  with_delivery                        :boolean          default(FALSE), not null
#
class Reception < Parcel
  belongs_to :sender, class_name: 'Entity'
  belongs_to :purchase_order, foreign_key: :purchase_id, class_name: 'PurchaseOrder', inverse_of: :parcels
  belongs_to :intervention, class_name: 'Intervention'
  has_many :items, class_name: 'ReceptionItem', inverse_of: :reception, foreign_key: :parcel_id, dependent: :destroy
  has_many :storings, through: :items, class_name: 'ParcelItemStoring'
  validates :sender, presence: true

  accepts_nested_attributes_for :items, allow_destroy: true

  state_machine initial: :draft do
    state :draft
    state :given

    event :give do
      transition draft: :given, if: :giveable?
    end
  end

  before_validation :remove_all_items, if: ->(obj) { obj.intervention.present? && obj.purchase_id_changed? }

  before_validation do
    self.nature = 'incoming'
    self.state ||= :draft
  end

  # Remove previous items, only if we are in an intervention and if the purchase change(in callback)
  def remove_all_items
    items.where.not(id: nil).destroy_all
  end

  after_initialize do
    self.address ||= Entity.of_company.default_mail_address if new_record?
  end

  protect on: :destroy do
    given?
  end

  # Remove previous items, only if we are in an intervention and if the purchase change(in callback)
  def remove_all_items
    items.where.not(id: nil).destroy_all
  end

  # This method permits to add stock journal entries corresponding to the
  # incoming or outgoing parcels.
  # It depends on the preferences which permit to activate the "permanent stock
  # inventory" and "automatic bookkeeping".
  #
  # | Parcel mode            | Debit                      | Credit                    |
  # | incoming parcel        | stock (3X)                 | stock_movement (603X/71X) |
  # | outgoing parcel        | stock_movement (603X/71X)  | stock (3X)                |
  bookkeep do |b|
    # For purchase_not_received or sale_not_emitted
    invoice = lambda do |usage, order|
      lambda do |entry|
        label = tc(:undelivered_invoice,
                   resource: self.class.model_name.human,
                   number: number, entity: entity.full_name, mode: nature.l)
        account = Account.find_or_import_from_nomenclature(usage)
        items.each do |item|
          amount = (item.trade_item && item.trade_item.pretax_amount) || item.stock_amount
          next unless item.variant && item.variant.charge_account && amount.nonzero?
          if order
            entry.add_credit label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
            entry.add_debit  label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
          else
            entry.add_debit  label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
            entry.add_credit label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
          end
        end
      end
    end

    ufb_accountable = Preference[:unbilled_payables] && given?
    # For unbilled payables
    journal = unsuppress { Journal.used_for_unbilled_payables!(currency: currency) }
    b.journal_entry(journal, printed_on: printed_on, as: :undelivered_invoice, if: ufb_accountable, &invoice.call(:suppliers_invoices_not_received, true))

    accountable = Preference[:permanent_stock_inventory] && given?
    # For permanent stock inventory
    journal = unsuppress { Journal.used_for_permanent_stock_inventory!(currency: currency) }
    b.journal_entry(journal, printed_on: printed_on, if: (Preference[:permanent_stock_inventory] && given?)) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human,
                            number: number, entity: entity.full_name, mode: nature.l)
      items.each do |item|
        variant = item.variant
        next unless variant && variant.storable? && item.stock_amount.nonzero?
        entry.add_credit(label, variant.stock_movement_account_id, item.stock_amount, resource: item, as: :stock_movement, variant: item.variant)
        entry.add_debit(label, variant.stock_account_id, item.stock_amount, resource: item, as: :stock, variant: item.variant)
      end
    end
  end

  def third_id
    sender_id
  end

  def third
    sender
  end

  alias entity third

  def invoiced?
    purchase_order.present?
  end

  def allow_items_update?
    !given?
  end

  def in_accident?
    in_accident = late_delivery
    unless in_accident
      items.each do |item|
        if item.non_compliant
          in_accident = true
          break
        end
      end
    end
    in_accident
  end

  delegate :full_name, to: :sender, prefix: true

  delegate :number, to: :purchase_order, prefix: true

  def give
    state = true
    return false, msg unless state
    update_column(:given_at, Time.zone.now) if given_at.blank?
    items.each(&:give)
    reload
    super
  end
end
