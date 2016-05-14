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
  belongs_to :sale_item, class_name: 'SaleItem'
  belongs_to :subscriber, class_name: 'Entity'
  has_one :sale, through: :sale_item
  has_one :variant, through: :sale_item, class_name: 'ProductNatureVariant'
  has_one :product_nature, through: :variant, source: :nature
  has_many :children, class_name: 'Subscription', foreign_key: :parent_id, dependent: :nullify

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_date :started_on, :stopped_on, allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }
  validates_datetime :stopped_on, allow_blank: true, on_or_after: :started_on, if: ->(subscription) { subscription.stopped_on && subscription.started_on }
  validates_numericality_of :quantity, allow_nil: true, only_integer: true
  validates_inclusion_of :suspended, in: [true, false]
  validates_presence_of :quantity, :started_on, :stopped_on, :swim_lane_uuid
  # ]VALIDATORS]
  validates_presence_of :nature, :subscriber

  # Look for subscriptions started without previous subscription
  scope :started_between, ->(started_on, stopped_on) { where('started_on BETWEEN ? AND ? AND parent_id IS NULL', started_on, stopped_on) }
  scope :stopped_between, ->(started_on, stopped_on) { where('stopped_on BETWEEN ? AND ? AND id NOT IN (SELECT parent_id FROM subscriptions WHERE parent_id IS NOT NULL)', started_on, stopped_on) }
  scope :renewed_between, ->(started_on, stopped_on) { where('stopped_on BETWEEN ? AND ? AND id IN (SELECT parent_id FROM subscriptions WHERE parent_id IS NOT NULL)', started_on, stopped_on) }
  scope :between, ->(started_on, stopped_on) { where('started_on BETWEEN ? AND ? OR stopped_on BETWEEN ? AND ? OR (started_on < ? AND ? < stopped_on)', started_on, stopped_on, started_on, stopped_on, started_on, stopped_on) }

  delegate :name, to: :nature, prefix: true

  before_validation do
    if parent
      self.swim_lane_uuid = parent.swim_lane_uuid
    else
      self.swim_lane_uuid ||= UUIDTools::UUID.random_create.to_s
    end
    self.address_id ||= sale.delivery_address_id if sale
    self.subscriber_id = address.entity_id if address
  end

  before_validation(on: :create) do
    self.started_on ||= Time.zone.today
    if product_nature
      unless self.stopped_on
        self.stopped_on = self.started_on
        self.stopped_on += product_nature.subscription_years_count.years
        self.stopped_on += product_nature.subscription_months_count.months
        self.stopped_on += product_nature.subscription_days_count.months
        self.stopped_on -= 1.day
      end
    end
  end

  validate do
    errors.add(:stopped_on, :posterior, to: started_on.l) unless started_on <= stopped_on
    errors.add(:address_id, :invalid) if address && !address.mail?
  end

  def subscriber_name
    address.mail_line_1
  end

  def active?(instant = nil)
    instant ||= Time.zone.today
    self.started_on <= instant && instant <= self.stopped_on
  end

  def renewable?
    sale_item && children.empty?
  end

  # Create a Sale, a SaleItem and a Subscription linked to current subscription
  def renew
    raise NotImplementedError
  end
end
