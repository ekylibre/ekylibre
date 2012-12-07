# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
#  consumption  :decimal(19, 4)
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
  attr_accessible :nature_id, :asset_id, :picture, :name, :comment, :purchased_on, :ceded_on, :consumption, :state
  has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "100x100>" }
  has_many :uses, :class_name=>"OperationUse"
  belongs_to :nature, :class_name=>"ToolNature"
  belongs_to :asset, :class_name=>"Asset"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :consumption, :allow_nil => true
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_presence_of :name, :nature
  #]VALIDATORS]

  default_scope order(:name)

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
