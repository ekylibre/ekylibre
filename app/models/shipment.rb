# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
class Shipment < Parcel
  belongs_to :sale, inverse_of: :parcels
  has_many :items, class_name: 'ShipmentItem', inverse_of: :shipment, foreign_key: :parcel_id, dependent: :destroy

  accepts_nested_attributes_for :items, allow_destroy: true

  alias_method :entity, :recipient
  alias_method :third, :recipient

  state_machine initial: :draft do
    state :draft
    state :ordered
    state :in_preparation
    state :prepared
    state :given

    event :order do
      transition draft: :ordered, if: :any_items?
    end
    event :prepare do
      transition draft: :in_preparation, if: :any_items?
      transition ordered: :in_preparation, if: :any_items?
    end
    event :check do
      transition draft: :prepared, if: :all_items_prepared?
      transition ordered: :prepared, if: :all_items_prepared?
      transition in_preparation: :prepared, if: :all_items_prepared?
    end
    event :give do
      transition draft: :given, if: :giveable?
      transition ordered: :given, if: :giveable?
      transition in_preparation: :given, if: :giveable?
      transition prepared: :given, if: :giveable?
    end
    event :cancel do
      transition ordered: :draft
      transition in_preparation: :ordered
    end
  end

  after_initialize do
    next if persisted?

    self.currency ||= Preference[:currency]
    self.nature = :outgoing
    self.planned_at ||= Time.zone.today
    self.state ||= :draft
  end

  protect on: :destroy do
    prepared? || given?
  end

  bookkeep

  def third_id
    recipient_id
  end

  def invoiced?
    sale.present?
  end

  def order
    return false unless can_order?
    update_column(:ordered_at, Time.zone.now)
    super
  end

  def prepare
    order if can_order?
    return false unless can_prepare?
    now = Time.zone.now
    values = { in_preparation_at: now }
    # values[:ordered_at] = now unless ordered_at
    update_columns(values)
    super
  end

  def check
    state = true
    order if can_order?
    prepare if can_prepare?
    return false unless can_check?
    now = Time.zone.now
    values = { prepared_at: now }
    # values[:ordered_at] = now unless ordered_at
    # values[:in_preparation_at] = now unless in_preparation_at
    update_columns(values)
    state = items.collect(&:check)
    return false, state.collect(&:second) unless (state == true) || (state.is_a?(Array) && state.all? { |s| s.is_a?(Array) ? s.first : s })
    super
    true
  end

  def give
    state = true
    order if can_order?
    prepare if can_prepare?
    state, msg = check if can_check?
    return false, msg unless state
    return false unless can_give?
    update_column(:given_at, Time.zone.now) if given_at.blank?
    items.each(&:give)
    reload
    super
  end

  def allow_items_update?
    !prepared? && !given?
  end

  class << self
    # Ships parcels. Returns a delivery
    # options:
    #   - deliver<y_mode: delivery mode
    #   - transporter_id: the transporter ID if delivery mode is :transporter
    #   - responsible_id: the responsible (Entity) ID for the delivery
    # raises:
    #   - "Need an obvious transporter to ship parcels" if there is no unique transporter for the parcels
    def ship(parcels, options = {})
      delivery = nil
      transaction do
        if options[:transporter_id]
          options[:delivery_mode] ||= :transporter
        elsif !delivery_mode.values.include? options[:delivery_mode].to_s
          raise "Need a valid delivery mode at least if no transporter given. Got: #{options[:delivery_mode].inspect}. Expecting one of: #{delivery_mode.values.map(&:inspect).to_sentence}"
        end
        delivery_mode = options[:delivery_mode].to_sym
        if delivery_mode == :transporter
          unless options[:transporter_id] && Entity.find_by(id: options[:transporter_id])
            transporter_ids = transporters_of(parcels).uniq
            if transporter_ids.size == 1
              options[:transporter_id] = transporter_ids.first
            else
              raise StandardError, 'Need an obvious transporter to ship parcels'
            end
          end
        end
        options[:started_at] ||= Time.zone.now
        options[:mode] = options.delete(:delivery_mode)
        delivery = Delivery.create!(options.slice!(:started_at, :transporter_id, :mode, :responsible_id, :driver_id))
        parcels.each do |parcel|
          parcel.delivery_mode = delivery_mode
          parcel.transporter_id = options[:transporter_id]
          parcel.delivery = delivery
          parcel.save!
        end
        delivery.save!
      end
      delivery
    end
  end
end
