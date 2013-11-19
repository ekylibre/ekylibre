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
#  description  :text             
#  harvest_year :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  number       :string(60)       not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#
class Campaign < Ekylibre::Record::Base
  # attr_accessible :description, :name, :closed

  has_many :productions
  has_many :interventions, :through => :productions

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :harvest_year, allow_nil: true, only_integer: true
  validates_length_of :number, allow_nil: true, maximum: 60
  validates_length_of :name, allow_nil: true, maximum: 255
  validates_inclusion_of :closed, in: [true, false]
  validates_presence_of :name, :number
  #]VALIDATORS]

  validates :harvest_year, length: {is: 4}, allow_nil: true
  before_validation :set_default_values, on: :create

  acts_as_numbered :number, :readonly => false
  # default_scope -> { where(:closed => false).order(:name) }
  scope :currents, -> { where(:closed => false).reorder(:harvest_year) }

  protect(on: :destroy) do
    self.productions.count.zero? and self.interventions.count.zero?
  end

  # Sets name
  def set_default_values
    self.name = self.harvest_year.to_s if self.name.blank? and self.harvest_year
  end

  def shape_area
    return self.productions.collect{|p| p.shape_area.to_s.to_f}.sum
  end

end
