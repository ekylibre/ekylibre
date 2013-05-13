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
# == Table: product_moves
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  last_done    :boolean          not null
#  lock_version :integer          default(0), not null
#  mode         :string(255)      not null
#  origin_id    :integer
#  origin_type  :string(255)
#  product_id   :integer          not null
#  quantity     :decimal(19, 4)   not null
#  started_at   :datetime         not null
#  stopped_at   :datetime         not null
#  unit_id      :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class ProductMove < Ekylibre::Record::Base
  belongs_to :origin, :polymorphic => true
  belongs_to :product
  belongs_to :unit
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :mode, :origin_type, :allow_nil => true, :maximum => 255
  validates_inclusion_of :last_done, :in => [true, false]
  validates_presence_of :mode, :product, :quantity, :started_at, :stopped_at, :unit
  #]VALIDATORS]
  validates_presence_of :product

  after_save :add_in_stock
  after_destroy :remove_from_stock
  before_update :remove_from_stock

  before_validation do
    if origin
      code = [:name, :code, :number, :id].detect{|x| origin.respond_to? x}
      self.name ||= tc('default_name', :origin => (origin ? origin.class.model_name.human : "*"), :code => (origin ? origin.send(code) : "*"))
    end
    unless self.stock
      conditions = {:product_id => self.product_id, :building_id => self.building_id, :tracking_id => self.tracking_id}
      self.stock = ProductStock.find_by_product_id_and_building_id_and_tracking_id(self.product_id, self.building_id, self.tracking_id)
      self.stock = ProductStock.create!(conditions) if stock.nil?
    end
    self.product ||= self.stock.product
    self.building ||= self.stock.building
    self.tracking ||= self.stock.tracking
    self.generated = false if self.generated.nil?
    self.virtual = moved_on.nil?
    self.unit_id ||= self.stock.unit_id
    # Add validation on unit correspondance
    return true
  end

  before_validation(:on => :create) do
    self.planned_on = Date.today
    return true
  end

  def self.natures
    [:virtual, :real].collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def state
    if self.quantity > 0
      "notice"
    elsif self.quantity < 0
      "error"
    end
  end

  private

  # Adds in stock the quantity
  def add_in_stock
    stock = self.reload.stock
    # self.reload.stock.add_quantity(self.quantity, self.unit, self.virtual)
    qty = stock.unit.convert(self.quantity, self.unit)
    stock.quantity += qty unless self.virtual
    stock.virtual_quantity += qty
    stock.save
    return true
  end

  # Removes from stock the old associated quantity
  def remove_from_stock
    old = self.class.find_by_id(self.id) rescue self
    if old and old.stock
      stock = old.stock
      # old.stock.remove_quantity(old.quantity, old.unit, old.virtual)
      qty = -stock.unit.convert(self.quantity, self.unit)
      stock.quantity += qty unless self.virtual
      stock.virtual_quantity += qty
      stock.save
    end
    return true
  end

end


