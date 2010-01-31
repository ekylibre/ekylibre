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
# == Table: shapes
#
#  area_measure :decimal(16, 4)   default(0.0), not null
#  area_unit_id :integer          
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  description  :text             
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  master       :boolean          default(TRUE), not null
#  name         :string(255)      not null
#  number       :string(255)      
#  parent_id    :integer          
#  polygon      :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#

class Shape < ActiveRecord::Base
  acts_as_tree
  attr_readonly :company_id
  belongs_to :company
  belongs_to :area_unit, :class_name=>Unit.name
  has_many :operations, :as=>:target
  has_many :shapes
  validates_presence_of :area_unit

  def before_validation
    self.master = false if self.master.nil?
    self.polygon ||= "[NotUsed]"
  end

end
