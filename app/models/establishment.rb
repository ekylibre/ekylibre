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
# == Table: establishments
#
#  comment      :text             
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nic          :string(5)        not null
#  siret        :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Establishment < Ekylibre::Record::Base
  attr_accessible :name, :comment, :nic
  has_many :warehouses
  has_many :employees, :class_name => "Entity"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nic, :allow_nil => true, :maximum => 5
  validates_length_of :name, :siret, :allow_nil => true, :maximum => 255
  validates_presence_of :name, :nic, :siret
  #]VALIDATORS]
  validates_uniqueness_of :name
  validates_uniqueness_of :siret

  before_validation do
    if eoc = Entity.of_company
      self.siret = eoc.siren.to_s + self.nic.to_s
    end
  end
end
