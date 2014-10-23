# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: teams
#
#  created_at       :datetime         not null
#  creator_id       :integer
#  depth            :integer          default(0), not null
#  description      :text
#  id               :integer          not null, primary key
#  lft              :integer
#  lock_version     :integer          default(0), not null
#  name             :string(255)      not null
#  parent_id        :integer
#  rgt              :integer
#  sales_conditions :text
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class Team < Ekylibre::Record::Base
  has_many :employees, class_name: "Entity"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :depth, :lft, :rgt, allow_nil: true, only_integer: true
  validates_length_of :name, allow_nil: true, maximum: 255
  validates_presence_of :depth, :name
  #]VALIDATORS]
  validates_uniqueness_of :name

  acts_as_nested_set

end
