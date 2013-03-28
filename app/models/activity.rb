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
# == Table: activities
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  depth        :integer
#  description  :string(255)
#  family       :string(255)      not null
#  id           :integer          not null, primary key
#  lft          :integer
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(255)      not null
#  nomen        :string(255)
#  parent_id    :integer
#  rgt          :integer
#  started_at   :datetime
#  stopped_at   :datetime
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Activity < Ekylibre::Record::Base
  attr_accessible :started_at, :stopped_at, :nature, :description, :family, :nomen, :name, :parent_id
  enumerize :nature, :in => [:main, :auxiliary, :none], :default => :main
  enumerize :family, :in => [:vegetal, :perenne_vegetal, :animal, :processing, :service, :none]
  has_many :repartitions, :class_name => "ActivityRepartition"

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :depth, :lft, :rgt, :allow_nil => true, :only_integer => true
  validates_length_of :description, :family, :name, :nature, :nomen, :allow_nil => true, :maximum => 255
  validates_presence_of :family, :name, :nature
  #]VALIDATORS]

  default_scope -> { where(:closed => false).order(:name) }

  acts_as_nested_set
end
