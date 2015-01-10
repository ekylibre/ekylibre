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
# == Table: operation_lines
#
#  area_unit_id    :integer          
#  company_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer          
#  direction       :string(4)        default("in"), not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  operation_id    :integer          not null
#  product_id      :integer          
#  quantity        :decimal(16, 4)   default(0.0), not null
#  stock_move_id   :integer          
#  tracking_id     :integer          
#  tracking_serial :string(255)      
#  unit_id         :integer          
#  unit_quantity   :decimal(16, 4)   default(0.0), not null
#  updated_at      :datetime         not null
#  updater_id      :integer          
#  warehouse_id    :integer          
#


class OperationLine < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :unit_quantity, :allow_nil => true
  validates_length_of :direction, :allow_nil => true, :maximum => 4
  validates_length_of :tracking_serial, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  acts_as_stockable :quantity=>'self.in? ? -self.quantity : self.quantity', :origin=>:operation  
  belongs_to :area_unit, :class_name=>"Unit"
  belongs_to :company
  belongs_to :warehouse
  belongs_to :operation
  belongs_to :product
  belongs_to :stock_move
  belongs_to :tracking
  belongs_to :unit
  validates_presence_of :product_id

  # IN operation.target or OUT of operation.target
  @@directions = ["in", "out"]
  validates_inclusion_of :direction, :in => @@directions

  before_validation do
    self.direction = @@directions[0] unless @@directions.include? self.direction
    self.quantity = self.quantity.to_f
    self.unit_id ||= self.product.unit_id if self.product

    if self.operation
      self.company_id = self.operation.company_id
      target = self.operation.target.target
      # raise Exception.new(target.inspect)
      if target.is_a? LandParcel
        self.area_unit_id  = target.area_unit_id
        self.unit_quantity = self.quantity/target.area_measure
      end
    end
    
    if self.direction == "out"
      self.tracking_serial = self.tracking_serial.to_s.strip
      unless self.tracking_serial.blank?
        producer = self.company.entity
        unless producer.has_another_tracking?(self.tracking_serial, self.product_id)
          tracking = self.company.trackings.find_by_serial_and_producer_id(self.tracking_serial.upper, producer.id)
          tracking = self.company.trackings.create!(:name=>self.tracking_serial, :product_id=>self.product_id, :producer_id=>producer.id) if tracking.nil?
          self.tracking_id = tracking.id
        end
        self.tracking_serial.upper!
      end
    elsif self.tracking
      self.tracking_serial = self.tracking.serial
    end
  end

  # Translate direction
  def direction_label
    tc('direction_label.'+self.direction.to_s)
  end

  def in?
    self.direction == "in"
  end

  def out?
    self.direction == "out"
  end

  def density_label
    if self.unit_quantity.nil? or self.area_unit.nil?
      "-"
    else
      tc("density_label", :value=>self.unit_quantity, :area_unit=>self.area_unit.name, :product_unit=>self.unit.name)
    end
  end

end
