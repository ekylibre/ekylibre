# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
# == Table: trackings
#
#  active       :boolean          default(TRUE), not null
#  comment      :text             
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  producer_id  :integer          
#  product_id   :integer          
#  serial       :string(255)      
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Tracking < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :serial, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :in => [true, false]
  validates_presence_of :company, :name
  #]VALIDATORS]
  after_save :update_serials
  belongs_to :company
  belongs_to :producer, :class_name=>"Entity"
  belongs_to :product
  has_many :outgoing_delivery_lines
  has_many :inventory_lines
  has_many :stocks
  has_many :purchase_lines
  has_many :sale_lines
  has_many :operation_lines
  has_many :stock_moves
  has_many :stock_transfers
  attr_readonly :company_id

  validates_presence_of :name, :serial
  validates_uniqueness_of :serial, :scope=>:producer_id

  before_validation do
    # the name is the serial number but it leave the possibility to put a name different from the serial
    self.serial ||= self.name
    self.name ||= self.serial
    self.serial = self.serial.strip.upper
  end

  def update_serials
    # Update tracking_serial columns through all the database
    OperationLine.update_all({:tracking_serial=>self.serial}, {:tracking_id=>self.id})
    PurchaseLine.update_all({:tracking_serial=>self.serial}, {:tracking_id=>self.id})
  end

end
