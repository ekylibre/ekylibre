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
# == Table: operation_items
#
#  area_unit_id    :integer          
#  created_at      :datetime         not null
#  creator_id      :integer          
#  direction       :string(4)        default("in"), not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  operation_id    :integer          not null
#  product_id      :integer          
#  quantity        :decimal(19, 4)   default(0.0), not null
#  stock_id        :integer          
#  stock_move_id   :integer          
#  tracking_serial :string(255)      
#  unit_id         :integer          
#  unit_quantity   :decimal(19, 4)   default(0.0), not null
#  updated_at      :datetime         not null
#  updater_id      :integer          
#  warehouse_id    :integer          
#


class OperationItem < CompanyRecord
  attr_accessible :direction, :product_id, :quantity, :unit_id, :warehouse_id
  enumerize :direction, :in => [:in, :out, :tool], :default => :in, :predicates => true
  belongs_to :area_unit, :class_name => "Unit"
  belongs_to :operation, :inverse_of => :lines
  belongs_to :product
  belongs_to :stock_move, :class_name => "ProductStockMove"
  belongs_to :unit
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :unit_quantity, :allow_nil => true
  validates_length_of :direction, :allow_nil => true, :maximum => 4
  validates_length_of :tracking_serial, :allow_nil => true, :maximum => 255
  validates_presence_of :direction, :operation, :quantity, :unit_quantity
  #]VALIDATORS]
  validates_presence_of :product
  validates_inclusion_of :direction, :in => self.direction.values

  acts_as_stockable :quantity => 'self.in? ? -self.quantity : self.quantity', :origin => :operation

  before_validation do
    self.direction = self.class.direction.default_value unless self.class.direction.values.include? self.direction.to_s
    self.quantity = self.quantity.to_f
    self.unit_id ||= self.product.unit_id if self.product

    if self.operation
      target = self.operation.target.target
      # raise Exception.new(target.inspect)
      if target.is_a? LandParcel
        self.area_unit_id  = target.area_unit_id
        self.unit_quantity = self.quantity/target.area_measure
      end
    end

    if self.out?
      self.tracking_serial = self.tracking_serial.to_s.strip
      unless self.tracking_serial.blank?
        producer = Entity.of_company
        unless producer.has_another_tracking?(self.tracking_serial, self.product_id)
          tracking = Tracking.find_by_serial_and_producer_id(self.tracking_serial.upper, producer.id)
          tracking = Tracking.create!(:name => self.tracking_serial, :product_id => self.product_id, :producer_id => producer.id) if tracking.nil?
          self.tracking_id = tracking.id
        end
        self.tracking_serial.upper!
      end
    elsif self.tracking
      self.tracking_serial = self.tracking.serial
    end
  end

  def density_label
    if self.unit_quantity.nil? or self.area_unit.nil?
      "-"
    else
      tc("density_label", :value => self.unit_quantity, :area_unit => self.area_unit.name, :product_unit => self.unit.name)
    end
  end

end
