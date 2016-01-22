# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  address_id        :integer
#  created_at        :datetime         not null
#  creator_id        :integer
#  delivery_id       :integer
#  delivery_mode     :string
#  given_at          :datetime
#  id                :integer          not null, primary key
#  in_preparation_at :datetime
#  lock_version      :integer          default(0), not null
#  nature            :string           not null
#  number            :string           not null
#  ordered_at        :datetime
#  planned_at        :datetime         not null
#  position          :integer
#  prepared_at       :datetime
#  purchase_id       :integer
#  recipient_id      :integer
#  reference_number  :string
#  remain_owner      :boolean          default(FALSE), not null
#  sale_id           :integer
#  sender_id         :integer
#  state             :string           not null
#  storage_id        :integer
#  transporter_id    :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class Parcel < Ekylibre::Record::Base
  include Attachable
  enumerize :nature, in: [:incoming, :outgoing, :internal], predicates: true, scope: true, default: :incoming
  enumerize :delivery_mode, in: [:transporter, :us, :third, :indifferent], predicates: { prefix: true }, scope: true, default: :indifferent
  belongs_to :address, class_name: 'EntityAddress'
  belongs_to :delivery
  belongs_to :storage, class_name: 'Product'
  belongs_to :sale, inverse_of: :parcels
  belongs_to :purchase
  belongs_to :recipient, class_name: 'Entity'
  belongs_to :sender, class_name: 'Entity'
  belongs_to :transporter, class_name: 'Entity'
  has_many :items, class_name: 'ParcelItem', inverse_of: :parcel, foreign_key: :parcel_id, dependent: :destroy
  has_many :products, through: :items
  has_many :issues, as: :target
  # has_many :interventions, class_name: 'Intervention', as: :resource

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :given_at, :in_preparation_at, :ordered_at, :planned_at, :prepared_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_inclusion_of :remain_owner, in: [true, false]
  validates_presence_of :nature, :number, :planned_at, :state
  # ]VALIDATORS]
  validates_presence_of :delivery_mode, :address
  validates_presence_of :recipient, if: :outgoing?
  validates_presence_of :sender, if: :incoming?
  validates_presence_of :transporter, if: :delivery_mode_transporter?
  validates_presence_of :storage, unless: :outgoing?

  scope :without_transporter, -> { with_delivery_mode(:transporter).where(transporter_id: nil) }

  accepts_nested_attributes_for :items, reject_if: :all_blank, allow_destroy: true

  acts_as_list scope: :delivery
  acts_as_numbered
  accepts_nested_attributes_for :items
  delegate :draft?, :ordered?, :in_preparation?, :prepared?, :started?, :finished?, to: :delivery, prefix: true

  state_machine :state, initial: :draft do
    state :draft
    state :ordered
    state :in_preparation
    state :prepared
    state :given

    event :order do
      transition draft: :ordered, if: :items?
    end
    event :prepare do
      transition ordered: :in_preparation, if: :items?
    end
    event :check do
      transition in_preparation: :prepared, if: :all_items_prepared?
      transition ordered: :prepared, if: :all_items_prepared?
      transition draft: :prepared, if: :all_items_prepared?
    end
    event :give do
      transition prepared: :given, if: :delivery_started?
    end
    event :cancel do
      transition ordered: :draft
      transition in_preparation: :ordered
      # transition prepared: :in_preparation
      # transition given: :prepared
    end
  end

  before_validation do
    self.planned_at ||= Time.zone.today
    self.state ||= :draft
  end

  validate do
    if delivery && delivery.transporter && transporter
      if delivery.transporter != transporter
        errors.add :transporter_id, :invalid
      end
    end
  end

  after_initialize do
    if new_record? && incoming?
      self.address ||= Entity.of_company.default_mail_address
    end
  end

  before_update do
    if given_at != old_record.given_at
      products.each do |product|
        product.readings.where(read_at: old_record.given_at).update_all(read_at: given_at)
      end
    end
  end

  after_save do
    if delivery
      if prepared? && delivery_in_preparation?
        delivery.check if delivery.parcels.all?(&:prepared?)
        # elsif self.in_preparation? && self.delivery_ordered?
        #   delivery.prepare
      end
    end
  end

  def invoiced?
    purchase.present? || sale.present?
  end

  def invoiceable?
    !invoiced?
  end

  def delivery?
    delivery.present?
  end

  def delivery_started?
    delivery?
  end

  def shippable?
    !delivery.present?
  end

  def address_coordinate
    address.coordinate if address
  end

  def address_mail_coordinate
    (address || sale.client.default_mail_address).mail_coordinate
  end

  def human_delivery_mode
    delivery_mode.text
  end

  def human_delivery_nature
    nature.text
  end

  # Number of products delivered
  def items_quantity
    items.sum(:population)
  end

  def all_items_prepared?
    items.all?(&:prepared?)
  end

  def items?
    items.any?
  end

  def issues?
    issues.any?
  end

  def status
    if given?
      return (issues? ? :caution : :go)
    else
      return (issues? ? :stop : :caution)
    end
  end

  def third_id
    (incoming? ? sender_id : outgoing? ? recipient_id : nil)
  end

  def third
    (incoming? ? sender : outgoing? ? recipient : nil)
  end

  def order
    return false unless can_order?
    update_column(:ordered_at, Time.zone.now)
    super
  end

  def prepare
    return false unless can_prepare?
    now = Time.zone.now
    values = { in_preparation_at: now }
    values[:ordered_at] = now unless ordered_at
    update_columns(values)
    super
  end

  def check
    return false unless can_check?
    now = Time.zone.now
    values = { prepared_at: now }
    values[:ordered_at] = now unless ordered_at
    values[:in_preparation_at] = now unless in_preparation_at
    update_columns(values)
    items.each(&:check)
    super
  end

  def give
    return false unless can_give?
    update_column(:given_at, Time.zone.now)
    items.each(&:give)
    super
  end

  class << self
    # Ships parcels. Returns a delivery
    # options:
    #   - delivery_mode: delivery mode
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
          fail "Need a valid delivery mode at least if no transporter given. Got: #{options[:delivery_mode].inspect}. Expecting one of: #{delivery_mode.values.map(&:inspect).to_sentence}"
        end
        delivery_mode = options[:delivery_mode].to_sym
        if delivery_mode == :transporter
          unless options[:transporter_id] && Entity.find_by(id: options[:transporter_id])
            transporter_ids = transporters_of(parcels).uniq
            if transporter_ids.size == 1
              options[:transporter_id] = transporter_ids.first
            else
              fail StandardError, 'Need an obvious transporter to ship parcels'
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

    # Returns an array of all the transporter ids for the given parcels
    def transporters_of(parcels)
      parcels.map(&:transporter_id).compact
    end

    # Convert parcels to one sale. Assume that all parcels are checked before.
    # Sale is written in DB with default values
    def convert_to_sale(parcels)
      sale = nil
      transaction do
        parcels = parcels.collect do |d|
          (d.is_a?(self) ? d : find(d))
        end.sort { |a, b| a.given_at <=> b.given_at }
        third = detect_third(parcels)
        planned_at = parcels.map(&:given_at).last || Time.zone.now
        unless nature = SaleNature.actives.first
          unless journal = Journal.sales.opened_at(planned_at).first
            fail 'No sale journal'
          end
          nature = SaleNature.create!(active: true, currency: Preference[:currency], with_accounting: true, journal: journal, by_default: true, name: SaleNature.tc('default.name', default: SaleNature.model_name.human))
        end
        sale = Sale.create!(client: third,
                            nature: nature,
                            # created_at: planned_at,
                            delivery_address: parcels.last.address)

        # Adds items
        parcels.each do |parcel|
          parcel.items.each do |item|
            # raise "#{item.variant.name} cannot be sold" unless item.variant.saleable?
            unless item.variant.saleable?
              item.category.product_account = Account.find_or_import_from_nomenclature(:revenues)
              item.category.saleable = true
            end
            next unless item.population && item.population > 0
            unless catalog_item = item.variant.catalog_items.first
              unless catalog = Catalog.of_usage(:sale).first
                catalog = Catalog.create!(name: Catalog.enumerized_attributes[:usage].human_value_name(:sales), usage: :sales)
              end
              catalog_item = catalog.items.create!(amount: 0, variant: item.variant)
            end
            item.sale_item = sale.items.create!(variant: item.variant,
                                                unit_pretax_amount: catalog_item.amount,
                                                tax: item.variant.category.sale_taxes.first || Tax.first,
                                                quantity: item.population)
            item.save!
          end
          parcel.reload
          parcel.sale_id = sale.id
          parcel.save!
        end

        # Refreshes affair
        sale.save!
      end
      sale
    end

    # Convert parcels to one purchase. Assume that all parcels are checked before.
    # Purchase is written in DB with default values
    def convert_to_purchase(parcels)
      purchase = nil
      transaction do
        parcels = parcels.collect do |d|
          (d.is_a?(self) ? d : find(d))
        end.sort { |a, b| a.given_at <=> b.given_at }
        third = detect_third(parcels)
        planned_at = parcels.map(&:given_at).last
        unless nature = PurchaseNature.actives.first
          unless journal = Journal.purchases.opened_at(planned_at).first
            fail 'No purchase journal'
          end
          nature = PurchaseNature.create!(
            active: true,
            currency: Preference[:currency],
            with_accounting: true,
            journal: journal,
            by_default: true,
            name: PurchaseNature.tc('default.name', default: PurchaseNature.model_name.human)
          )
        end
        purchase = Purchase.create!(supplier: third,
                                    nature: nature,
                                    planned_at: planned_at,
                                    delivery_address: parcels.last.address)

        # Adds items
        parcels.each do |parcel|
          parcel.items.each do |item|
            next unless item.population && item.population > 0
            item.purchase_item = purchase.items.create!(variant: item.variant,
                                                        unit_pretax_amount: (item.variant.catalog_items.any? ? item.variant.catalog_items.order(id: :desc).first.amount : 0.0),
                                                        tax: item.variant.category.purchase_taxes.first || Tax.first,
                                                        quantity: item.population)
            item.save!
          end
          parcel.reload
          parcel.purchase = purchase
          parcel.save!
        end

        # Refreshes affair
        purchase.save!
      end
      purchase
    end

    def detect_third(parcels)
      thirds = parcels.map(&:third_id).uniq
      fail "Need unique third (#{thirds.inspect})" if thirds.count != 1
      Entity.find(thirds.first)
    end
  end
end
