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
# == Table: product_nature_prices
#
#  active            :boolean          default(TRUE), not null
#  amount            :decimal(19, 4)   not null
#  by_default        :boolean          default(TRUE)
#  category_id       :integer
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string(3)
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  pretax_amount     :decimal(19, 4)   not null
#  product_nature_id :integer          not null
#  started_at        :datetime
#  stopped_at        :datetime
#  supplier_id       :integer
#  tax_id            :integer          not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#


class ProductNaturePrice < Ekylibre::Record::Base
  attr_accessible :active, :amount, :by_default, :category_id, :supplier_id, :pretax_amount, :product_nature_id, :tax_id, :currency
  after_create :set_by_default
  belongs_to :category, :class_name => "EntityCategory"
  belongs_to :product_nature
  belongs_to :tax
  belongs_to :supplier, :class_name => "Entity"
  has_many :outgoing_delivery_items, :class_name => "OutgoingDeliveryItem"
  has_many :taxes
  has_many :purchase_items, :class_name => "PurchaseItem"
  has_many :sale_items, :class_name => "SaleItem"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_inclusion_of :active, :in => [true, false]
  validates_presence_of :amount, :pretax_amount, :product_nature, :tax
  #]VALIDATORS]
  validates_presence_of :category, :if => Proc.new{|price| price.supplier_id == Entity.of_company.id}
  validates_presence_of :supplier
  validates_numericality_of :pretax_amount, :amount, :greater_than_or_equal_to => 0

  delegate :storable?, :subscription?, :to => :product_nature

  scope :availables_for_sales, -> { joins(:product_nature).where("#{ProductNaturePrice.table_name}.active=? AND #{ProductNature.table_name}.active=?", true, true) }


  before_validation do
    if supplier = Entity.of_company
      self.currency  ||= supplier.currency
      self.supplier_id ||= supplier.id
    end
    if self.amount.to_f > 0
      self.amount = self.amount.round(2)
      tax_amount = (self.tax ? self.tax.compute(self.amount, true) : 0)
      self.pretax_amount = self.amount - tax_amount.round(2)
    else  # if self.amount.to_f >= 0
      tax_amount = (self.tax ? self.tax.compute(self.pretax_amount) : 0).to_f
      self.amount = (self.pretax_amount.to_f+tax_amount).round(2)
      self.pretax_amount = self.amount.to_f - tax_amount.round(2)
    end
    self.started_at = Time.now
  end


  def update
    current_time = Time.now
    stamper_id = self.class.stamper_class.stamper.id rescue nil
    nc = self.class.create!(self.attributes.merge(:started_at => current_time, :created_at => current_time, :updated_at => current_time, :creator_id => stamper_id, :updater_id => stamper_id, :active => true).delete_if{|k,v| k.to_s == "id"}, :without_protection => true)
    self.class.update_all({:stopped_at => current_time, :active => false}, {:id => self.id})
    nc.set_by_default
    return nc
  end

  def destroy
    unless self.new_record?
      current_time = Time.now
      self.class.update_all({:stopped_at => current_time, :active => false}, {:id => self.id})
    end
  end

  def set_by_default
    if self.by_default
      ProductNaturePrice.update_all({:by_default => false}, ["product_nature_id = ? AND id != ? AND supplier_id = ?", self.product_nature_id, self.id||0, self.supplier_id])
    end
  end

  def refresh
    self.save
  end

  def change(amount, tax_id)
    conditions = {:product_nature_id => self.product_nature_id, :amount => amount, :tax_id => tax_id, :active => true, :supplier_id => self.supplier_id, :currency => self.currency, :category_id => self.category_id}
    price = self.class.where(conditions).first
    if price.nil?
      self.update_column(:active, false)
      price = self.class.create!(conditions)
    end
    price
  end

  def label
    tc(:label, :product_nature => self.product_nature.name, :amount => self.amount, :currency => self.currency)
  end

  def compute(quantity = nil, pretax_amount = nil, amount = nil)
    if quantity
      pretax_amount = self.pretax_amount*quantity
      amount = self.amount*quantity
    elsif pretax_amount
      quantity = pretax_amount/self.pretax_amount
      amount = quantity*self.amount
    elsif amount
      quantity = amount/self.amount
      pretax_amount = quantity*self.amount
    elsif
      raise ArgumentError.new("At least one argument must be given")
    end
    return quantity.round(4), pretax_amount.round(2), amount.round(2)
  end

end
