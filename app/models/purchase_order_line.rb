# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
# == Table: purchase_order_lines
#
#  account_id        :integer          not null
#  amount            :decimal(16, 2)   default(0.0), not null
#  amount_with_taxes :decimal(16, 2)   default(0.0), not null
#  annotation        :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  id                :integer          not null, primary key
#  location_id       :integer          
#  lock_version      :integer          default(0), not null
#  order_id          :integer          not null
#  position          :integer          
#  price_id          :integer          not null
#  product_id        :integer          not null
#  quantity          :decimal(16, 4)   default(1.0), not null
#  tracking_id       :integer          
#  tracking_serial   :string(255)      
#  unit_id           :integer          not null
#  updated_at        :datetime         not null
#  updater_id        :integer          
#

class PurchaseOrderLine < ActiveRecord::Base
  attr_readonly :company_id, :order_id

  belongs_to :account
  belongs_to :company
  belongs_to :order, :class_name=>PurchaseOrder.name
  belongs_to :price
  belongs_to :product
  belongs_to :location, :class_name=>Location.name
  belongs_to :tracking
  belongs_to :unit

  validates_presence_of :amount, :price_id
  validates_presence_of :tracking_id, :if=>Proc.new{|pol| !pol.tracking_serial.blank?}
  validates_uniqueness_of :tracking_serial, :scope=>:price_id
  
  def before_validation
    self.company_id = self.order.company_id if self.order
    check_reservoir = true
    self.location_id = self.company.locations.first.id if self.company.locations.size == 1
    if self.price
      product = self.price.product
      if product.charge_account.nil?
        account_number = self.company.parameter("accountancy.major_accounts.charges").value
        product.charge_account = self.company.accounts.find_by_number(account_number.to_s)
        product.charge_account = self.company.accounts.create!(:number=>account_number.to_s, :name=>::I18n.t('parameters.accountancy.major_accounts.charges')) if product.charge_account.nil?
        product.save!
      end
      self.account_id = product.charge_account_id
      self.unit_id ||= self.price.product.unit_id
      self.product_id = self.price.product_id
      self.amount = (self.price.amount*self.quantity).round(2)
      self.amount_with_taxes = (self.price.amount_with_taxes*self.quantity).round(2)
    end
    if self.location
      if self.location.reservoir && self.location.product_id != self.product_id
        check_reservoir = false
        errors.add_to_base(tc(:location_can_not_receive_product), :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name) 
      end
    end

    self.tracking_serial = self.tracking_serial.strip
    unless self.tracking_serial.blank?
      producer = self.order.supplier
      unless producer.has_another_tracking?(self.tracking_serial, self.product_id)
        tracking = self.company.trackings.find_by_serial_and_producer_id(self.tracking_serial.upper, producer.id)
        tracking = self.company.trackings.create!(:name=>self.tracking_serial, :product_id=>self.product_id, :producer_id=>producer.id) if tracking.nil?
        self.tracking_id = tracking.id
      end
      self.tracking_serial.upper!
    end

    check_reservoir
  end  

  def validate
    # Validate that tracking serial is not used for a different product
    producer = self.order.supplier
    unless self.tracking_serial.blank?
      errors.add(:tracking_serial, tc(:is_already_used_with_an_other_product)) if producer.has_another_tracking?(self.tracking_serial, self.product_id)
    end
  end
  
  def after_save
    self.order.refresh
  end
  
  def after_destroy
    #raise Exception.new "yyy"
    self.tracking.destroy if self.tracking
    self.order.refresh
  end

  def product_name
    self.product.name
  end

  def taxes
    self.amount_with_taxes - self.amount
  end
  
end
