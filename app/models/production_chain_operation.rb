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
# == Table: production_chain_operations
#
#  check_states        :string(16)       
#  comment             :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  expected_duration   :decimal(16, 4)   
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  name                :string(255)      not null
#  nature              :string(255)      not null
#  operation_nature_id :integer          not null
#  parent_id           :integer          
#  production_chain_id :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer          
#

class ProductionChainOperation < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :company
  belongs_to :operation_nature
  has_many :lines, :class_name=>ProductionChainOperationLine.name, :foreign_key=>:operation_id
  has_many :uses,  :class_name=>ProductionChainOperationUse.name,  :foreign_key=>:operation_id

  @@natures = [:input, :output]

  def self.natures_list
    @@natures.collect{|x| [tc("natures.#{x}"), x.to_s]}
  end

end
