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
# == Table: products
#
#  active                   :boolean          not null
#  address_id               :integer          
#  area_measure             :decimal(19, 4)   
#  area_unit_id             :integer          
#  asset_id                 :integer          
#  born_at                  :datetime         
#  comment                  :text             
#  content_maximal_quantity :decimal(19, 4)   default(0.0), not null
#  content_nature_id        :integer          
#  content_unit_id          :integer          
#  created_at               :datetime         not null
#  creator_id               :integer          
#  dead_at                  :datetime         
#  description              :text             
#  external                 :boolean          not null
#  father_id                :integer          
#  id                       :integer          not null, primary key
#  lock_version             :integer          default(0), not null
#  maximal_quantity         :decimal(19, 4)   default(0.0), not null
#  minimal_quantity         :decimal(19, 4)   default(0.0), not null
#  mother_id                :integer          
#  name                     :string(255)      not null
#  nature_id                :integer          not null
#  number                   :string(255)      
#  owner_id                 :integer          
#  parent_warehouse_id      :integer          
#  picture_content_type     :string(255)      
#  picture_file_name        :string(255)      
#  picture_file_size        :integer          
#  picture_updated_at       :datetime         
#  producer_id              :integer          
#  reproductor              :boolean          not null
#  reservoir                :boolean          not null
#  serial_number            :string(255)      
#  sex                      :string(255)      
#  shape                    :spatial({:srid=> 
#  type                     :string(255)      not null
#  unit_id                  :integer          not null
#  updated_at               :datetime         not null
#  updater_id               :integer          
#


class Warehouse < Place
  # TODO: Use acts_as_nested_set
  # acts_as_tree
  attr_accessible :address_id, :comment, :establishment_id, :reservoir, :unit_id, :product_id, :maximal_quantity
  attr_readonly :reservoir
  # belongs_to :address, :class_name => "EntityAddress"
  # belongs_to :establishment
  belongs_to :content_nature, :class_name => "ProductNature"
  has_many :purchase_lines
  has_many :sale_lines
  has_many :stocks, :class_name => "ProductStock"
  has_many :stock_moves, :class_name => "ProductStockMove"
  has_many :stock_transfers, :class_name => "ProductTransfer"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, :allow_nil => true, :only_integer => true
  validates_numericality_of :area_measure, :content_maximal_quantity, :maximal_quantity, :minimal_quantity, :allow_nil => true
  validates_length_of :name, :number, :picture_content_type, :picture_file_name, :serial_number, :sex, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :external, :reproductor, :reservoir, :in => [true, false]
  validates_presence_of :content_maximal_quantity, :maximal_quantity, :minimal_quantity, :name, :nature, :unit
  #]VALIDATORS]
  validates_presence_of :content_nature, :if => :reservoir?

  default_scope order(:name)
  scope :of_product, lambda { |product|
    where("(product_id = ? AND reservoir = ?) OR reservoir = ?", product.id, true, false)
  }

  validate do
    # TODO: Describe errors more precisely
    # if self.parent
    #   errors.add(:parent_id, :invalid) if self.parent.reservoir?
    #   if self.parent_id == self.id or self.parent_ids.include?(self.id) or self.child_ids.include?(self.id)
    #     errors.add(:parent_id, :invalid)
    #   end
    # end
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
      stocks = ProductStock.where(:product_id => self.product_id, :warehouse_id => self.id)
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
