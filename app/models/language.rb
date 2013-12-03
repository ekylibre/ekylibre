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
# == Table: languages
#
#  company_id   :integer          
#  created_at   :datetime         
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  iso2         :string(2)        not null
#  iso3         :string(3)        not null
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  native_name  :string(255)      not null
#  updated_at   :datetime         
#  updater_id   :integer          
#

class Language < ActiveRecord::Base
  has_many :entities
  has_many :document_templates
  has_many :users
  belongs_to :company

  attr_readonly :company_id
end
