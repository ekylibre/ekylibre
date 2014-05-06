# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: outgoing_deliveries
#
#  address_id       :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode_id          :integer
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
#


class OutgoingDelivery < Ekylibre::Record::Base
  attr_readonly :sale_id, :number
  belongs_to :address, class_name: "EntityAddress"
  belongs_to :mode, class_name: "OutgoingDeliveryMode"
  belongs_to :recipient, class_name: "Entity"
  belongs_to :sale, inverse_of: :deliveries
  belongs_to :transport
  belongs_to :transporter, class_name: "Entity"
  has_many :items, class_name: "OutgoingDeliveryItem", foreign_key: :delivery_id, dependent: :destroy, inverse_of: :delivery
  has_many :interventions, class_name: "Intervention", :as => :ressource
  has_many :issues, as: :target
  # has_many :product_moves, :as => :origin, dependent: :destroy
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :net_mass, allow_nil: true
  validates_length_of :number, :reference_number, allow_nil: true, maximum: 255
  validates_presence_of :address, :number, :recipient
  #]VALIDATORS]
  validates_presence_of :sent_at

  accepts_nested_attributes_for :items

  # autosave :transport
  acts_as_numbered
  sums :transport, :deliveries, :net_mass

  scope :without_transporter, -> { where(:transporter_id => nil) }


  before_validation do
    self.transporter_id ||= self.transport.transporter_id if self.transport
    return true
  end

  protect do
    self.sent_at?
  end

  after_initialize do
    if self.new_record?
      self.mode ||= mode ||= OutgoingDeliveryMode.by_default
    end
  end

#   transfer do |t|
#     for item in self.items
#       t.move(:use => item)
#     end
#   end


  # Ships the delivery and move the real stocks. This operation locks the delivery.
  # This permits to manage stocks.
  def ship(shipped_at=Date.today)
    # self.confirm_transfer(shipped_at)
    # self.items.each{|l| l.confirm_move}
    for item in self.items.where("quantity > 0")
      item.product.move_outgoing_stock(:origin => item, :building_id => item.sale_item.building_id, :planned_at => self.sent_at, :moved_at => shipped_at)
    end
    self.sent_at = shipped_at if self.sent_at.nil?
    self.save
  end

  def moment
    if self.sent_at <= Date.today-(3)
      "verylate"
    elsif self.sent_at <= Date.today
      "late"
    elsif self.sent_at > Date.today
      "advance"
    end
  end

  def label
    tc('label', :client => self.sale.client.full_name.to_s, :address => self.address.coordinate.to_s)
  end

  # Used with list for the moment
  def quantity
    0
  end

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

  def invoice
    raise NotImplemented
  end

end
