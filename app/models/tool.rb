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
# == Table: tools
#
#  company_id   :integer          not null
#  consumption  :decimal(16, 4)   
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(8)        not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Tool < CompanyRecord

  belongs_to :company
  has_many :uses, :class_name=>OperationUse.name

  attr_readonly :company_id

  @@natures = [:tractor, :towed, :other] 
  
  def self.natures
    @@natures.collect{|x| [tc('natures.'+x.to_s), x] }
  end
  
  def text_nature
    tc('natures.'+self.nature)
  end

  def usage_duration_sum
    sum = 0
    self.uses.each do |usage|
      sum += usage.operation.duration
    end
    sum/60
  end

  def usage_duration
    return Operation.sum(:duration, :conditions=>["moved_on IS NOT NULL AND id IN (SELECT operation_id FROM #{OperationUse.table_name} WHERE tool_id=?)", self.id])
  end

  def remaining_duration
    return Operation.sum(:duration, :conditions=>["moved_on IS NULL AND id IN (SELECT operation_id FROM #{OperationUse.table_name} WHERE tool_id=?)", self.id])
  end

    

end
