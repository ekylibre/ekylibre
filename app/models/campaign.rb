# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
  has_many :productions
  has_many :production_supports, through: :productions, source: :supports
  has_many :interventions, through: :productions
  has_one :selected_manure_management_plan, -> { selected }, class_name: "ManureManagementPlan", foreign_key: :campaign_id, inverse_of: :campaign
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :harvest_year, allow_nil: true, only_integer: true
  validates_length_of :number, allow_nil: true, maximum: 60
  validates_length_of :name, allow_nil: true, maximum: 255
  validates_inclusion_of :closed, in: [true, false]
  validates_presence_of :name, :number
  #]VALIDATORS]
  validates :harvest_year, length: {is: 4}, allow_nil: true
  before_validation :set_default_values, on: :create

  acts_as_numbered :number, readonly: false
  scope :currents, -> { where(closed: false).reorder(:harvest_year) }

  protect(on: :destroy) do
    self.productions.any? or self.interventions.any?
  end

  # Sets name
  def set_default_values
    self.name = self.harvest_year.to_s if self.name.blank? and self.harvest_year
  end

  def shape_area
    return self.productions.map(&:shape_area).sum
  end

  def previous
    self.class.where("harvest_year < ?", self.harvest_year)
  end

end
