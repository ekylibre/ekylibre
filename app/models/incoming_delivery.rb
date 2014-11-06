# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: incoming_deliveries
#
#  address_id       :integer
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode             :string(255)
#  net_mass         :decimal(19, 4)
#  number           :string(255)      not null
#  purchase_id      :integer
#  received_at      :datetime
#  reference_number :string(255)
#  sender_id        :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class IncomingDelivery < Ekylibre::Record::Base
  belongs_to :address, class_name: "EntityAddress"
  # belongs_to :mode, class_name: "IncomingDeliveryMode"
  belongs_to :purchase
  belongs_to :sender, class_name: "Entity"
  has_many :items, class_name: "IncomingDeliveryItem", inverse_of: :delivery, foreign_key: :delivery_id, dependent: :destroy
  has_many :products, through: :items
  has_many :issues, as: :target

  enumerize :mode, in: Nomen::DeliveryModes.all

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :received_at, allow_blank: true, on_or_after: Date.civil(1,1,1)
  validates_numericality_of :net_mass, allow_nil: true
  validates_length_of :mode, :number, :reference_number, allow_nil: true, maximum: 255
  validates_presence_of :number, :sender
  #]VALIDATORS]
  validates_presence_of :received_at, :address, :mode

  acts_as_numbered
  accepts_nested_attributes_for :items
  delegate :order?, :draft?, to: :purchase

  scope :undelivereds, -> { where(received_at: nil) }

  before_validation do
    self.received_at ||= Time.now
  end

  after_initialize do
    if self.new_record?
      self.address ||= Entity.of_company.default_mail_address
      # self.mode    ||= IncomingDeliveryMode.by_default
      self.received_at ||= Time.now
    end
  end

  before_update do
    if self.received_at != old_record.received_at
      for product in self.products
        product.readings.where(read_at: old_record.received_at).update_all(read_at: self.received_at)
      end
    end
  end

  def execute(received_at = Time.now)
    self.class.transaction do
      self.update_attributes(:received_at => received_at)
    end
  end

  def has_issue?
    self.issues.any?
  end

  def status
    if self.received_at == nil
      return (has_issue? ? :stop : :caution)
    elsif self.received_at
      return (has_issue? ? :caution : :go)
    end
  end

  def self.invoice(*deliveries)
    purchase = nil
    transaction do
      deliveries = deliveries.flatten.collect do |d|
        self.find(d) # (d.is_a?(self) ? d : self.find(d))
      end.compact.sort do |a,b|
        a.received_at <=> b.received_at or a.id <=> b.id
      end
      senders = deliveries.map(&:sender_id).uniq
      raise "Need unique sender (#{senders.inspect})" if senders.count > 1
      planned_at = deliveries.map(&:received_at).last
      unless nature = PurchaseNature.actives.first
        unless journal = Journal.purchases.opened_at(planned_at).first
          raise "No purchase journal"
        end
        nature = PurchaseNature.create!(active: true, currency: Preference[:currency], with_accounting: true, journal: journal, by_default: true, name: PurchaseNature.tc('default.name', default: PurchaseNature.model_name.human))
      end
      purchase = Purchase.create!(supplier: Entity.find(senders.first),
                                  nature: nature,
                                  planned_at: planned_at,
                                  delivery_address: deliveries.last.address)

      # Adds items
      for delivery in deliveries
        for item in delivery.items
          next unless item.population > 0
          item.purchase_item = purchase.items.create!(variant: item.variant,
                                                      unit_price_amount: item.variant.prices.first.amount,
                                                      tax: item.variant.category.purchase_taxes.first || Tax.first,
                                                      indicator_name: "population",
                                                      quantity: item.population)
          item.save!
        end
        delivery.reload
        delivery.purchase = purchase
        delivery.save!
      end

      # Refreshes affair
      purchase.save!
    end
    return purchase
  end

end
