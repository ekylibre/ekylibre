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
# == Table: warehouses
#
#  address_id       :integer          
#  comment          :text             
#  created_at       :datetime         not null
#  creator_id       :integer          
#  division         :string(255)      
#  establishment_id :integer          
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  name             :string(255)      not null
#  number           :integer          
#  parent_id        :integer          
#  product_id       :integer          
#  quantity_max     :decimal(19, 4)   
#  reservoir        :boolean          
#  subdivision      :string(255)      
#  subsubdivision   :string(255)      
#  unit_id          :integer          
#  updated_at       :datetime         not null
#  updater_id       :integer          
#


class Warehouse < CompanyRecord
  # TODO: Use acts_as_nested_set
  acts_as_tree
  attr_accessible :address_id, :comment, :establishment_id, :division, :subdivision, :subsubdivision, :reservoir, :unit_id, :parent_id, :product_id, :quantity_max
  attr_readonly :reservoir
  belongs_to :address, :class_name => "EntityAddress"
  belongs_to :establishment
  belongs_to :product, :class_name => "Product"
  has_many :purchase_lines
  has_many :sale_lines
  has_many :stocks
  has_many :stock_moves
  has_many :stock_transfers
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :number, :allow_nil => true, :only_integer => true
  validates_numericality_of :quantity_max, :allow_nil => true
  validates_length_of :division, :name, :subdivision, :subsubdivision, :allow_nil => true, :maximum => 255
  validates_presence_of :name
  #]VALIDATORS]
  validates_presence_of :product, :if => :reservoir?

  default_scope order(:name)
  scope :of_product, lambda { |product|
    where("(product_id = ? AND reservoir = ?) OR reservoir = ?", product.id, true, false)
  }

  validate do
    # TODO: Describe errors more precisely
    if self.parent
      errors.add(:parent_id, :invalid) if self.parent.reservoir?
      if self.parent_id == self.id or self.parent_ids.include?(self.id) or self.child_ids.include?(self.id)
        errors.add(:parent_id, :invalid)
      end
    end
  end

  protect(:on => :destroy) do
    dependencies = 0
    for k, v in self.class.reflections.select{|k, v| v.macro == :has_many}
      dependencies += self.send(k).size
    end
    return dependencies <= 0
  end


  def can_receive?(product_id)
    #raise Exception.new product_id.inspect+self.reservoir.inspect
    reception = true
    if self.reservoir
      stocks = Stock.where(:product_id => self.product_id, :warehouse_id => self.id)
      if !stocks.first.nil?
        reception = ((self.product_id == product_id) || (stocks.first.quantity <= 0))
        self.update_attributes!(:product_id => product_id) if stocks.first.quantity <= 0
        #if stocks.first.quantity <= 0
        for ps in stocks
          ps.destroy if ps.product_id != product_id and ps.quantity <=0
        end
        #end
      else
        self.update_attributes!(:product_id=>product_id)
      end
    end
    reception
  end

  # # obsolete
  # def can_receive(product_id)
  #   self.can_receive?(product_id)
  # end

  # Returns parent ids
  def parent_ids
    if self.parent
      return [self.parent_id] + self.parent.parent_ids
    else
      return []
    end
  end

  # Return child ids
  def child_ids
    ids = []
    for child in self.children
      ids << child.id
      ids += child.child_ids
    end
    return ids
  end


end
