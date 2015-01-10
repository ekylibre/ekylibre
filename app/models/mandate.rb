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
# == Table: mandates
#
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  entity_id    :integer          not null
#  family       :string(255)      not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  organization :string(255)      not null
#  started_on   :date             
#  stopped_on   :date             
#  title        :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Mandate < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :family, :organization, :title, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  attr_readonly :company_id
  belongs_to :entity
  belongs_to :company

  validates_presence_of :started_on, :stopped_on

end
