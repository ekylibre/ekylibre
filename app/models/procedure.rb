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
# == Table: procedures
#
#  activity_id  :integer          not null
#  campaign_id  :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  incident_id  :integer
#  lock_version :integer          default(0), not null
#  nomen        :string(255)      not null
#  parent_id    :integer
#  state        :string(255)      default("undone"), not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#  version      :string(255)      not null
#
class Procedure < Ekylibre::Record::Base
  belongs_to :incident, :class_name => "Incident"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nomen, :state, :version, :allow_nil => true, :maximum => 255
  validates_presence_of :nomen, :state, :version
  #]VALIDATORS]
  # belongs_to :nature, :class_name => "ProcedureNature"

end
