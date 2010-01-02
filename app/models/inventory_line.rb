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
# == Table: inventory_lines
#
#  company_id         :integer          not null
#  created_at         :datetime         not null
#  creator_id         :integer          
#  id                 :integer          not null, primary key
#  inventory_id       :integer          not null
#  location_id        :integer          not null
#  lock_version       :integer          default(0), not null
#  product_id         :integer          not null
#  theoric_quantity   :decimal(16, 2)   not null
#  tracking_id        :integer          
#  updated_at         :datetime         not null
#  updater_id         :integer          
#  validated_quantity :decimal(16, 2)   not null
#

class InventoryLine < ActiveRecord::Base

  belongs_to :company
  belongs_to :inventory
  belongs_to :location, :class_name=>StockLocation.name
  belongs_to :product

  attr_readonly :company_id

  def after_save
    if self.inventory.changes_reflected
      self.reflect_changes
    end
  end
  
  def reflect_changes
    if self.validated_quantity != self.theoric_quantity
      rslt =  (self.validated_quantity.to_f != self.theoric_quantity.to_f)
      puts rslt
      input = self.validated_quantity < self.theoric_quantity ? false : true
      #raise Exception.new self.theoric_quantity.to_s+" "+self.validated_quantity.to_s+"   "+input.to_s
      if input
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.validated_quantity - self.theoric_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id, :generated=>true)
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.validated_quantity - self.theoric_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id ,:generated=>true)
      else
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.theoric_quantity - self.validated_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id ,:generated=>true)
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.theoric_quantity - self.validated_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id ,:generated=>true)
      end
    end
  end

end
