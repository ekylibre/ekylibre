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
# == Table: outgoing_deliveries
#
#  address_id       :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode             :string(255)      not null
#  net_mass         :decimal(19, 4)
#  number           :string(255)      not null
#  recipient_id     :integer          not null
#  reference_number :string(255)
#  sale_id          :integer
#  sent_at          :datetime
#  transport_id     :integer
#  transporter_id   :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#  with_transport   :boolean          not null
#


class OutgoingDelivery < Ekylibre::Record::Base
  attr_readonly :number
  belongs_to :address, class_name: "EntityAddress"
  # belongs_to :mode, class_name: "OutgoingDeliveryMode"
  belongs_to :recipient, class_name: "Entity"
  belongs_to :sale, inverse_of: :deliveries
  belongs_to :transport
  belongs_to :transporter, class_name: "Entity"
  has_many :items, class_name: "OutgoingDeliveryItem", foreign_key: :delivery_id, dependent: :destroy, inverse_of: :delivery
  has_many :interventions, class_name: "Intervention", :as => :ressource
  has_many :issues, as: :target

  enumerize :mode, in: Nomen::DeliveryModes.all
  # has_many :product_moves, :as => :origin, dependent: :destroy
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :sent_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :net_mass, allow_nil: true
  validates_length_of :mode, :number, :reference_number, allow_nil: true, maximum: 255
  validates_inclusion_of :with_transport, in: [true, false]
  validates_presence_of :address, :mode, :number, :recipient
  #]VALIDATORS]
  validates_presence_of :sent_at, unless: :with_transport
  validates_presence_of :transporter, if: :with_transport

  accepts_nested_attributes_for :items, reject_if: :all_blank

  # autosave :transport
  acts_as_numbered
  sums :transport, :deliveries, :net_mass

  scope :without_transporter, -> { where(with_transport: true, transporter_id: nil) }

  before_validation do
    # if self.transport
    #   self.transporter ||= self.transport.transporter
    # end
    if self.with_transport and self.transport
      self.sent_at = self.transport.departed_at
    end
  end

  validate do
    if self.transport and self.transporter
      if self.transport.transporter != self.transporter
        errors.add :transporter_id, :invalid
      end
    end
  end

  # protect do
  #   self.with_transport and self.transporter
  # end

  # # Ships the delivery and move the real stocks. This operation locks the delivery.
  # # This permits to manage stocks.
  # def ship(shipped_at=Date.today)
  #   # self.confirm_transfer(shipped_at)
  #   # self.items.each{|l| l.confirm_move}
  #   for item in self.items.where("quantity > 0")
  #     item.product.move_outgoing_stock(:origin => item, :building_id => item.sale_item.building_id, :planned_at => self.sent_at, :moved_at => shipped_at)
  #   end
  #   self.sent_at = shipped_at if self.sent_at.nil?
  #   self.save
  # end

  # def moment
  #   if self.sent_at <= Date.today-(3)
  #     "verylate"
  #   elsif self.sent_at <= Date.today
  #     "late"
  #   elsif self.sent_at > Date.today
  #     "advance"
  #   end
  # end

  # def label
  #   tc('label', :client => self.sale.client.full_name.to_s, :address => self.address.coordinate.to_s)
  # end

  # # Used with list for the moment
  # def quantity
  #   0
  # end

  def address_coordinate
    self.address.coordinate if self.address
  end

  def address_mail_coordinate
    return (self.address || self.sale.client.default_mail_address).mail_coordinate
  end

  def parcel_sum
    self.items.sum(:quantity)
  end

  def has_issue?
    self.issues.any?
  end

  def status
    if self.sent_at == nil
      return (has_issue? ? :stop : :caution)
    elsif self.sent_at
      return (has_issue? ? :caution : :go)
    end
  end

  # Ships outgoing deliveries. Returns a transport
  # options:
  #   - transporter_id: the transporter ID
  #   - responsible_id: the responsible (Entity) ID for the transport
  # raises:
  #   - "Need an obvious transporter to ship deliveries" if there is no unique transporter for the deliveries
  def self.ship(deliveries, options = {})
    transport = nil
    transaction do
      unless options[:transporter_id] and Entity.find_by(id: options[:transporter_id])
        transporter_ids = transporters_of(deliveries).uniq
        if transporter_ids.size == 1
          options[:transporter_id] = transporter_ids.first
        else
          raise StandardError, "Need an obvious transporter to ship deliveries"
        end
      end
      transport = Transport.create!(departed_at: Time.now, transporter_id: options[:transporter_id], responsible_id: options[:responsible_id])
      deliveries.each do |delivery|
        delivery.with_transport = true
        delivery.transporter_id = options[:transporter_id]
        delivery.transport = transport
        delivery.save!
      end

      transport.save!
    end
    return transport
  end

  # Returns an array of all the transporter ids for the given deliveries
  def self.transporters_of(deliveries)
    deliveries.map(&:transporter_id).compact
  end


  def self.invoice(deliveries)
    sale = nil
    transaction do
      deliveries = deliveries.flatten.collect do |d|
        (d.is_a?(self) ? d : self.find(d))
      end.sort{|a,b| a.sent_at <=> b.sent_at }
      recipients = deliveries.map(&:recipient_id).uniq
      raise "Need unique recipient (#{recipients.inspect})" if recipients.count > 1
      planned_at = deliveries.map(&:sent_at).last || Time.now
      unless nature = SaleNature.actives.first
        unless journal = Journal.sales.opened_at(planned_at).first
          raise "No sale journal"
        end
        nature = SaleNature.create!(active: true, currency: Preference[:currency], with_accounting: true, journal: journal, by_default: true, name: SaleNature.tc('default.name', default: SaleNature.model_name.human))
      end
      sale = Sale.create!(client: Entity.find(recipients.first),
                          nature: nature,
                          # created_at: planned_at,
                          delivery_address: deliveries.last.address)

      # Adds items
      for delivery in deliveries
        for item in delivery.items
          #raise "#{item.variant.name} cannot be sold" unless item.variant.saleable?
          if !item.variant.saleable?
            item.category.product_account = Account.find_or_create_in_chart(:revenues)
            item.category.saleable = true
          end
          next unless item.population > 0
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
        delivery.reload
        delivery.sale_id = sale.id
        delivery.save!
      end

      # Refreshes affair
      sale.save!
    end
    return sale
  end

end
