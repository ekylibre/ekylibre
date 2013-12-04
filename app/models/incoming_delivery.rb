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
# == Table: incoming_deliveries
#
#  address_id       :integer
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode_id          :integer
#  number           :string(255)      not null
#  purchase_id      :integer
#  received_at      :datetime
#  reference_number :string(255)
#  sender_id        :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class IncomingDelivery < Ekylibre::Record::Base
  acts_as_numbered
  # attr_accessible :address_id, :sender_id, :mode_id, :received_at, :reference_number, :items_attributes # , :description
  attr_readonly :number
  belongs_to :address, class_name: "EntityAddress"
  belongs_to :mode, class_name: "IncomingDeliveryMode"
  belongs_to :purchase
  belongs_to :sender, class_name: "Entity"
  has_many :items, class_name: "IncomingDeliveryItem", inverse_of: :delivery, foreign_key: :delivery_id, dependent: :destroy
  has_many :products, through: :items
  has_many :product_moves, :as => :origin

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :number, :reference_number, allow_nil: true, maximum: 255
  validates_presence_of :number, :sender
  #]VALIDATORS]
  validates_presence_of :received_at, :address, :mode

  accepts_nested_attributes_for :items
  delegate :order?, :draft?, to: :purchase

  # default_scope -> { order("received_at DESC") }
  scope :undelivereds, -> { where(received_at: nil) }

  before_validation do
    self.received_at ||= Time.now
    return true
  end

  after_initialize do
    if self.new_record?
      self.address ||= Entity.of_company.default_mail_address
      self.mode    ||= IncomingDeliveryMode.by_default
      self.received_at ||= Time.now
    end
  end

  before_update do
    if self.received_at != old_record.received_at
      for product in self.products
        product.indicator_data.where(measured_at: old_record.received_at).update_all(measured_at: self.received_at)
      end
    end
  end

  # # Only used for list usage
  # def quantity
  #   nil
  # end


  def execute(received_at = Time.now)
    self.class.transaction do
      self.update_attributes(:received_at => received_at)
    end
  end

end
