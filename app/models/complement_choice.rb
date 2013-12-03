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
# == Table: complement_choices
#
#  company_id    :integer          not null
#  complement_id :integer          not null
#  created_at    :datetime         not null
#  creator_id    :integer          
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  name          :string(255)      not null
#  position      :integer          
#  updated_at    :datetime         not null
#  updater_id    :integer          
#  value         :string(255)      not null
#

class ComplementChoice < ActiveRecord::Base
  belongs_to :company
  belongs_to :complement
  has_many :data, :class_name=>ComplementDatum.to_s
  acts_as_list :scope=>:complement_id

  def before_validation
    self.value = self.name.to_s.codeize if self.value.blank?
  end

  def to_s
    self.name
  end

end
