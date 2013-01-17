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
# == Table: product_stock_periods
#
#  created_at   :datetime         not null
#  creator_id   :integer          
#  decimal      :decimal(19, 4)   default(0.0), not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  mode         :string(32)       not null
#  move_id      :integer          not null
#  product_id   :integer          not null
#  quantity     :decimal(19, 4)   default(0.0), not null
#  started_at   :datetime         
#  stock_id     :integer          not null
#  stopped_at   :datetime         
#  unit_id      :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#  warehouse_id :integer          not null
#
class ProductStockPeriod < CompanyRecord
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal, :quantity, :allow_nil => true
  validates_length_of :mode, :allow_nil => true, :maximum => 32
  validates_presence_of :decimal, :mode, :move, :product, :quantity, :stock, :unit
  #]VALIDATORS]
  belongs_to :move, :class_name => "ProductStockMove"
  belongs_to :stock, :class_name => "ProductStock"
  belongs_to :product, :class_name => "Product"
  belongs_to :unit
end
