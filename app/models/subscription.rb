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
# == Table: subscriptions
#
#  address_id     :integer
#  created_at     :datetime         not null
#  creator_id     :integer
#  custom_fields  :jsonb
#  description    :text
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  nature_id      :integer
#  number         :string
#  parent_id      :integer
#  quantity       :integer          not null
#  sale_item_id   :integer
#  started_on     :date             not null
#  stopped_on     :date             not null
#  subscriber_id  :integer
#  suspended      :boolean          default(FALSE), not null
#  swim_lane_uuid :uuid             not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#

class Subscription < Ekylibre::Record::Base
  include Customizable
  acts_as_numbered
  belongs_to :address, class_name: 'EntityAddress'
  belongs_to :nature, class_name: 'SubscriptionNature', inverse_of: :subscriptions
  belongs_to :parent, class_name: 'Subscription'
  belongs_to :sale_item, class_name: 'SaleItem', inverse_of: :subscription
  belongs_to :subscriber, class_name: 'Entity'
  has_one :sale, through: :sale_item
  has_one :variant, through: :sale_item, class_name: 'ProductNatureVariant'
  has_one :product_nature, through: :variant, source: :nature
  has_many :children, class_name: 'Subscription', foreign_key: :parent_id, dependent: :nullify

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :number, length: { maximum: 500 }, allow_blank: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(subscription) { subscription.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  validates :suspended, inclusion: { in: [true, false] }
  validates :swim_lane_uuid, presence: true
  # ]VALIDATORS]
  validates :nature, :subscriber, presence: true

  # Look for subscriptions started without previous subscription
  scope :started_between, ->(started_on, stopped_on) { where('started_on BETWEEN ? AND ? AND parent_id IS NULL', started_on, stopped_on) }
  scope :stopped_between, ->(started_on, stopped_on) { where('stopped_on BETWEEN ? AND ? AND id NOT IN (SELECT parent_id FROM subscriptions WHERE parent_id IS NOT NULL)', started_on, stopped_on) }
  scope :renewed_between, ->(started_on, stopped_on) { where('stopped_on BETWEEN ? AND ? AND id IN (SELECT parent_id FROM subscriptions WHERE parent_id IS NOT NULL)', started_on, stopped_on) }
  scope :between, ->(started_on, stopped_on) { where('started_on BETWEEN ? AND ? OR stopped_on BETWEEN ? AND ? OR (started_on < ? AND ? < stopped_on)', started_on, stopped_on, started_on, stopped_on, started_on, stopped_on) }
  scope :active, -> { where('NOT suspended AND ? BETWEEN started_on AND stopped_on', Time.zone.today) }

  delegate :name, to: :nature, prefix: true

  before_validation do
    if parent
      self.swim_lane_uuid = parent.swim_lane_uuid
    else
      self.swim_lane_uuid ||= UUIDTools::UUID.random_create.to_s
    end
    if sale_item
      self.nature ||= sale_item.subscription_nature
      self.quantity = sale_item.quantity.to_i
    end
    self.address_id ||= sale.delivery_address_id if sale
    self.subscriber_id = address.entity_id if address
  end

  before_validation(on: :create) do
    self.started_on ||= Time.zone.today
    if product_nature
      unless stopped_on
        self.stopped_on = product_nature.subscription_stopped_on(self.started_on)
      end
    end
  end

  validate do
    if self.started_on && stopped_on
      errors.add(:stopped_on, :posterior, to: started_on.l) unless started_on <= stopped_on
    end
    errors.add(:address_id, :invalid) if address && !address.mail?
  end

  def destroyable_by_user?
    !sale_item
  end

  def subscriber_name
    address.mail_line_1
  end

  def active?(instant = nil)
    instant ||= Time.zone.today
    self.started_on <= instant && instant <= stopped_on
  end

  def renewable?
    sale_item && children.empty?
  end

  # Returns a hash to create a Sale with a SaleItem and a Subscription linked
  # to current subscription
  def renew_attributes(attributes = {})
    hash = {
      client_id: sale.client_id,
      nature_id: sale.nature_id,
      letter_format: false
    }
    # Items
    attrs = %i[
      variant_id quantity amount label pretax_amount annotation
      reduction_percentage tax_id unit_amount unit_pretax_amount
    ].each_with_object({}) do |field, h|
      v = sale_item.send(field)
      h[field] = v if v.present?
    end
    attrs[:subscription_attributes] = following_attributes
    hash[:items_attributes] = { '0' => attrs }
    hash.with_indifferent_access.deep_merge(attributes)
  end

  # Create a Sale, a SaleItem and a Subscription linked to current subscription
  # Inspired by Sale#duplicate
  def renew!(attributes = {})
    Sale.create!(renew_attributes(attributes))
  end

  def following_attributes
    attributes = {
      nature_id: nature_id,
      address_id: self.address_id,
      subscriber_id: subscriber_id
    }
    last_subscription = subscriber.last_subscription(self.nature)
    if last_subscription
      attributes[:parent_id] = last_subscription.id
      attributes[:started_on] = last_subscription.stopped_on + 1
    else
      attributes[:started_on] = Time.zone.today
    end
    product_nature = self.product_nature || last_subscription.product_nature
    attributes[:stopped_on] = if product_nature
                                product_nature.subscription_stopped_on(attributes[:started_on])
                              else
                                attributes[:started_on] + 1.year - 1.day
                              end
    attributes
  end

  def suspendable?
    !suspended && active?
  end

  def active?
    !(past? || future?)
  end

  def disabled?
    past? || suspended
  end

  def future?
    self.started_on > Time.zone.today
  end

  def past?
    stopped_on < Time.zone.today
  end

  def suspend
    update_attribute(:suspended, true)
  end

  def takeover
    update_attribute(:suspended, false)
  end
end
