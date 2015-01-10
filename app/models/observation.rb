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
# == Table: observations
#
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  description  :text             not null
#  entity_id    :integer          not null
#  id           :integer          not null, primary key
#  importance   :string(10)       not null
#  lock_version :integer          default(0), not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Observation < CompanyRecord
  belongs_to :company
  belongs_to :entity
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :importance, :allow_nil => true, :maximum => 10
  #]VALIDATORS]

  attr_readonly :company_id
  
  
  def self.importances
    [:important, :normal, :notice].collect{|x| [tc('importances.'+x.to_s), x] }
  end


  before_validation do
    self.company ||= self.entity.company if self.entity
    self.importance ||= "notice"
  end

  def text_importance
    tc('importances.'+self.importance.to_s)
  end

  def status
    status = ""
    case self.importance
    when "important"
      status = "critic"
    when "normal"
      status = "minimum"
    end
    status
  end
  
end
