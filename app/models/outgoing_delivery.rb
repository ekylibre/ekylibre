# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
#  address_id       :integer
#  amount           :decimal(19, 4)   default(0.0), not null
#  created_at       :datetime         not null
#  creator_id       :integer
#  currency         :string(3)
#  description      :text
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode_id          :integer
#  moved_on         :date
#  number           :string(255)
#  planned_on       :date
#  pretax_amount    :decimal(19, 4)   default(0.0), not null
#  reference_number :string(255)
#  sale_id          :integer          not null
#  transport_id     :integer
#  transporter_id   :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#  weight           :decimal(19, 4)
#


class OutgoingDelivery < Ekylibre::Record::Base
  attr_accessible :address_id, :description, :mode_id, :planned_on, :reference_number, :sale_id
  attr_readonly :sale_id, :number
  belongs_to :address, :class_name => "EntityAddress"
  belongs_to :mode, :class_name => "OutgoingDeliveryMode"
  belongs_to :sale, :inverse_of => :deliveries
  belongs_to :transport
  belongs_to :transporter, :class_name => "Entity"
  has_many :items, :class_name => "OutgoingDeliveryItem", :foreign_key => :delivery_id, :dependent => :destroy
  has_many :product_moves, :as => :origin, :dependent => :destroy
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :weight, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_length_of :number, :reference_number, :allow_nil => true, :maximum => 255
  validates_presence_of :amount, :pretax_amount, :sale
  #]VALIDATORS]
  validates_presence_of :planned_on

  # autosave :transport
  acts_as_numbered
  sums :transport, :deliveries, :amount, :pretax_amount, :weight

  default_scope order(:planned_on, :moved_on)
  scope :undelivereds, where(:moved_on => nil).order(:planned_on, :entity_id)
  scope :without_transporter, where(:moved_on => nil, :transporter_id => nil)


  before_validation do
    self.transporter_id ||= self.transport.transporter_id if self.transport
    return true
  end

  protect(:on => :update) do
    return false unless self.moved_on.nil?
    return true
  end

#   transfer do |t|
#     for item in self.items
#       t.move(:use => item)
#     end
#   end


  # Ships the delivery and move the real stocks. This operation locks the delivery.
  # This permits to manage stocks.
  def ship(shipped_on=Date.today)
    # self.confirm_transfer(shipped_on)
    # self.items.each{|l| l.confirm_move}
    for item in self.items.find(:all, :conditions => ["quantity>0"])
      item.product.move_outgoing_stock(:origin => item, :warehouse_id => item.sale_item.warehouse_id, :planned_on => self.planned_on, :moved_on => shipped_on)
    end
    self.moved_on = shipped_on if self.moved_on.nil?
    self.save
  end

  def moment
    if self.planned_on <= Date.today-(3)
      "verylate"
    elsif self.planned_on <= Date.today
      "late"
    elsif self.planned_on > Date.today
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

end
