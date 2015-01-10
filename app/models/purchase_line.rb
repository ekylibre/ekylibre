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
# == Table: purchase_lines
#
#  account_id      :integer          not null
#  amount          :decimal(16, 2)   default(0.0), not null
#  annotation      :text             
#  company_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer          
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  position        :integer          
#  pretax_amount   :decimal(16, 2)   default(0.0), not null
#  price_id        :integer          not null
#  product_id      :integer          not null
#  purchase_id     :integer          not null
#  quantity        :decimal(16, 4)   default(1.0), not null
#  tracking_id     :integer          
#  tracking_serial :string(255)      
#  unit_id         :integer          not null
#  updated_at      :datetime         not null
#  updater_id      :integer          
#  warehouse_id    :integer          
#


class PurchaseLine < CompanyRecord
  acts_as_list :scope=>:purchase
  attr_readonly :company_id, :purchase_id
  belongs_to :account
  belongs_to :company
  belongs_to :purchase
  belongs_to :price
  belongs_to :product
  belongs_to :warehouse
  belongs_to :tracking, :dependent=>:destroy
  belongs_to :unit
  has_many :delivery_lines, :class_name=>"IncomingDeliveryLine", :foreign_key=>:purchase_line_id
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :allow_nil => true
  validates_length_of :tracking_serial, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  validates_presence_of :pretax_amount, :price_id
  validates_presence_of :tracking_id, :if=>Proc.new{|pol| !pol.tracking_serial.blank?}
  validates_uniqueness_of :tracking_serial, :scope=>:price_id, :allow_nil=>true, :if=>Proc.new{|pl| !pl.tracking_serial.blank? }

  sums :purchase, :lines, :pretax_amount, :amount
  
  before_validation do
    self.company_id = self.purchase.company_id if self.purchase
    check_reservoir = true
    self.warehouse_id = self.company.warehouses.first.id if self.company.warehouses.size == 1
    if self.price
      product = self.price.product
      if product.purchases_account.nil?
        account_number = self.company.preferred_charges_accounts
        product.purchases_account = self.company.accounts.find_by_number(account_number.to_s)
        product.purchases_account = self.company.accounts.create!(:number=>account_number.to_s, :name=>::I18n.t('preferences.accountancy.major_accounts.charges')) if product.purchases_account.nil?
        product.save!
      end
      self.account_id = product.purchases_account_id
      self.unit_id ||= self.price.product.unit_id
      self.product_id = self.price.product_id
      self.pretax_amount = (self.price.pretax_amount*self.quantity).round(2)
      self.amount = (self.price.amount*self.quantity).round(2)
    end
    if self.warehouse
      if self.warehouse.reservoir && self.warehouse.product_id != self.product_id
        check_reservoir = false
        errors.add_to_base(:warehouse_can_not_receive_product, :warehouse=>self.warehouse.name, :product=>self.product.name, :contained_product=>self.warehouse.product.name) 
      end
    end

    self.tracking_serial = self.tracking_serial.to_s.strip
    unless self.tracking_serial.blank?
      producer = self.purchase.supplier
      unless producer.has_another_tracking?(self.tracking_serial, self.product_id)
        tracking = self.company.trackings.find_by_serial_and_producer_id(self.tracking_serial.upper, producer.id)
        tracking = self.company.trackings.create!(:name=>self.tracking_serial, :product_id=>self.product_id, :producer_id=>producer.id) if tracking.nil?
        self.tracking_id = tracking.id
      end
      self.tracking_serial.upper!
    end

    check_reservoir
  end  

  validate do
    # Validate that tracking serial is not used for a different product
    producer = self.purchase.supplier
    unless self.tracking_serial.blank?
      errors.add(:tracking_serial, :serial_already_used_with_an_other_product) if producer.has_another_tracking?(self.tracking_serial, self.product_id)
    end
  end
  
  def name
    options = {:product=>self.product.name, :unit=>self.unit.name, :quantity=>quantity.to_s, :amount=>self.price.amount, :currency=>self.price.currency.name}
    if self.tracking
      options[:tracking] = self.tracking.name
      tc(:name_with_tracking, options)
    else
      tc(:name, options)
    end
  end

  def product_name
    self.product.name
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end
  
  def designation
    d  = self.product_name
    d += "\n"+self.annotation.to_s unless self.annotation.blank?
    d += "\n"+tc(:tracking, :serial=>self.tracking.serial.to_s) if self.tracking
    d
  end

  def undelivered_quantity
    return self.quantity-self.delivery_lines.sum(:quantity)
  end

  def label
    self.product.name
  end

end
