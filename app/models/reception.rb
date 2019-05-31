# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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
  belongs_to :purchase_order, foreign_key: :purchase_id, class_name: 'PurchaseOrder', inverse_of: :parcels
  belongs_to :intervention, class_name: 'Intervention'
  has_many :items, class_name: 'ReceptionItem', inverse_of: :reception, foreign_key: :parcel_id, dependent: :destroy
  has_many :storings, through: :items, class_name: 'ParcelItemStoring'

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

  after_initialize do
    self.address ||= Entity.of_company.default_mail_address if new_record?
  end

  after_save do
    purchase_order_ids = items.map { |item| item.purchase_order_item&.purchase_id }.uniq.compact
    if purchase_order_ids.any?
      purchase_orders = PurchaseOrder.find(purchase_order_ids)
      purchase_orders.each { |order| order.update!(reconciliation_state: 'reconcile') if order.fully_reconciled? }
    end
  end

  protect on: :destroy do
    given?
  end

  bookkeep

  # Remove previous items, only if we are in an intervention and if the purchase
  # change(in callback)
  def remove_all_items
    items.where.not(id: nil).destroy_all
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
