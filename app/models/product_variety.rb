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
# == Table: product_varieties
#
#  code         :integer          
#  comment      :text             
#  created_at   :datetime         not null
#  creator_id   :integer          
#  description  :text             
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  parent_id    :integer          
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class ProductVariety < CompanyRecord
  attr_accessible :name, :code, :comment, :description, :parent_id
  has_many :products, :foreign_key => :variety_id
  # has_many :posologies, :class_name => "AnimalPosology", :foreign_key => :animal_race_id
  belongs_to :parent, :class_name => "ProductVariety"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :code, :allow_nil => true, :only_integer => true
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_presence_of :name
  #]VALIDATORS]
   validates_uniqueness_of :name
end
