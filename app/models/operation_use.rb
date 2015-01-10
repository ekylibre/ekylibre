# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
# == Table: operation_uses
#
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  operation_id :integer          not null
#  tool_id      :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class OperationUse < CompanyRecord
  attr_readonly :company_id
  belongs_to :company
  belongs_to :operation
  belongs_to :tool
  validates_uniqueness_of :tool_id, :scope=>[:operation_id]

  before_validation do
    self.company_id = self.operation.company_id if self.operation
  end

  validate do
    if self.operation and self.tool
      errors.add_to_base(:company_error) unless self.operation.company_id == self.tool.company_id
    end
  end

end
