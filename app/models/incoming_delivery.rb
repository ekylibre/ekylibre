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
#  amount           :decimal(19, 4)   default(0.0), not null
#  comment          :text             
#  created_at       :datetime         not null
#  creator_id       :integer          
#  currency         :string(3)        
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  mode_id          :integer          
#  moved_on         :date             
#  number           :string(255)      
#  planned_on       :date             
#  pretax_amount    :decimal(19, 4)   default(0.0), not null
#  purchase_id      :integer          
#  reference_number :string(255)      
#  updated_at       :datetime         not null
#  updater_id       :integer          
#  weight           :decimal(19, 4)   
#


class IncomingDelivery < CompanyRecord
  acts_as_numbered
  attr_readonly :number
  # DEPRECATED Replace use of contact with address
  belongs_to :contact, :class_name => "EntityAddress", :foreign_key => :address_id
  belongs_to :address, :class_name => "EntityAddress"
  belongs_to :mode, :class_name=>"IncomingDeliveryMode"
  belongs_to :purchase
  has_many :lines, :class_name=>"IncomingDeliveryLine", :foreign_key=>:delivery_id, :dependent=>:destroy
  has_many :stock_moves, :as=>:origin

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :weight, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_length_of :number, :reference_number, :allow_nil => true, :maximum => 255
  validates_presence_of :amount, :pretax_amount
  #]VALIDATORS]
  validates_presence_of :planned_on

  scope :undelivereds, where(:moved_on => nil)

  before_validation do
    self.planned_on ||= Date.today
#     self.pretax_amount = self.amount = self.weight = 0.0
#     for line in self.lines
#       self.pretax_amount += line.pretax_amount
#       self.amount += line.amount
#       self.weight += (line.product.weight||0)*line.quantity
#     end
    return true
  end

  # Only used for list usage
  def quantity
    nil
  end

  def execute(moved_on = Date.today)
    self.class.transaction do
      self.update_attributes(:moved_on => moved_on)
    end
  end

end
