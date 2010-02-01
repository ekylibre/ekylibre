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
# == Table: locations
#
#  account_id       :integer          not null
#  comment          :text             
#  company_id       :integer          not null
#  contact_id       :integer          
#  created_at       :datetime         not null
#  creator_id       :integer          
#  establishment_id :integer          
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  name             :string(255)      not null
#  number           :integer          
#  parent_id        :integer          
#  product_id       :integer          
#  quantity_max     :float            
#  reservoir        :boolean          
#  unit_id          :integer          
#  updated_at       :datetime         not null
#  updater_id       :integer          
#  x                :string(255)      
#  y                :string(255)      
#  z                :string(255)      
#

class Location < ActiveRecord::Base
  belongs_to :account
  belongs_to :company
  belongs_to :contact
  belongs_to :establishment
  belongs_to :product
  has_many :stocks, :foreign_key=>:location_id
  has_many :purchase_order_lines
  has_many :sale_order_lines
  has_many :locations
  has_many :stock_moves
  has_many :stock_transfers

  attr_readonly :company_id

  validates_presence_of :account_id

  acts_as_tree


  def before_validation_on_create
    self.reservoir = true if !self.product_id.nil?
  end
  
  def can_receive?(product_id)
    #raise Exception.new product_id.inspect+self.reservoir.inspect
    reception = true
    if self.reservoir 
      stock = Stock.find(:all, :conditions=>{:company_id=>self.company_id, :product_id=>self.product_id, :location_id=>self.id}) 
      if !stock[0].nil?
        reception = (self.product_id == product_id || stock[0].quantity <= 0)
        self.update_attributes!(:product_id=>product_id) if stock[0].quantity <= 0
        #if stock[0].quantity <= 0
        for ps in stock
          ps.destroy if ps.product_id != product_id and ps.quantity <=0
        end
        #end
      else
        self.update_attributes!(:product_id=>product_id)
      end
    end
    reception
  end

  # obsolete
  def can_receive(product_id)
    self.can_receive?(product_id)
  end

end
