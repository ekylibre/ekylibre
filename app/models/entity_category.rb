# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Merigon
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
# == Table: entity_categories
#
#  by_default   :boolean          not null
#  code         :string(8)        
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  description  :text             
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class EntityCategory < CompanyRecord
  attr_readonly :company_id
  belongs_to :company
  has_many :entities, :foreign_key=>:category
  has_many :prices, :foreign_key=>:category
  validates_uniqueness_of :code, :scope=>:company_id

  before_validation do
    EntityCategory.update_all({:by_default=>false}, ["company_id=? AND id!=?", self.company_id, self.id||0]) if self.by_default
    self.code = self.name.to_s.codeize if self.code.blank?
    self.code = self.code[0..7]
  end

  protect_on_destroy do
    self.entities.size <= 0 and self.prices.size <= 0
  end
  
end
