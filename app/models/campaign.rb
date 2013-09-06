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
# == Table: campaigns
#
#  closed       :boolean          not null
#  closed_at    :datetime
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :string(255)
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Campaign < Ekylibre::Record::Base
  # attr_accessible :description, :name, :closed

  has_many :productions
  has_many :procedures, :through => :productions

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :description, :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :closed, :in => [true, false]
  validates_presence_of :name
  #]VALIDATORS]

  # default_scope -> { where(:closed => false).order(:name) }
  scope :currents, -> { }

  def shape_area
    return self.productions.collect{|p| p.shape_area.to_s.to_f}.sum
  end

  def name_with_surface_area
    "#{self.name} (#{(self.shape_area*0.0001).round(2)} ha)"
  end

end
