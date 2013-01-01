# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: events
#
#  created_at     :datetime         not null
#  creator_id     :integer          
#  duration       :integer          
#  entity_id      :integer          not null
#  id             :integer          not null, primary key
#  location       :string(255)      
#  lock_version   :integer          default(0), not null
#  nature_id      :integer          not null
#  reason         :text             
#  responsible_id :integer          not null
#  started_at     :datetime         not null
#  started_sec    :integer          not null
#  updated_at     :datetime         not null
#  updater_id     :integer          
#


class Event < CompanyRecord
  belongs_to :entity
  belongs_to :nature, :class_name=>"EventNature"
  belongs_to :responsible, :class_name=>"Entity"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :duration, :started_sec, :allow_nil => true, :only_integer => true
  validates_length_of :location, :allow_nil => true, :maximum => 255
  validates_presence_of :entity, :nature, :responsible, :started_at, :started_sec
  #]VALIDATORS]
  validates_presence_of :responsible, :nature, :entity

  before_validation do
    self.started_at ||= Time.now
    self.started_sec = self.started_at.to_i
  end

end
