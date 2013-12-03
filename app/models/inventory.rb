# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Mérigon
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
# == Table: inventories
#
#  changes_reflected :boolean          
#  comment           :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  date              :date             not null
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  responsible_id    :integer          
#  updated_at        :datetime         not null
#  updater_id        :integer          
#

class Inventory < ActiveRecord::Base

  belongs_to :company
  belongs_to :responsible, :class_name=>User.name
  has_many :lines, :class_name=>InventoryLine.name

  attr_readonly :company_id


  def before_validation
    self.date ||= Date.today
  end

  def after_update
    if self.changes_reflected
      for line in self.lines
        line.save
      end
    end
  end

  def before_destroy
    for line in self.lines
      line.destroy
    end
  end


end
