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
#  depth        :integer
#  id           :integer          not null, primary key
#  incident_id  :integer
#  lft          :integer
#  lock_version :integer          default(0), not null
#  nomen        :string(255)      not null
#  parent_id    :integer
#  rgt          :integer
#  state        :string(255)      default("undone"), not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#  version      :string(255)
#
class Procedure < Ekylibre::Record::Base
  attr_accessible :nomen, :activity_id, :campaign_id
  attr_readonly :nomen, :activity_id, :campaign_id
  belongs_to :activity
  belongs_to :campaign
  belongs_to :incident
  has_many :variables, :class_name => "ProcedureVariable", :inverse_of => :procedure
  has_many :operations, :inverse_of => :procedure
  enumerize :nomen, :in => Procedures.names
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :depth, :lft, :rgt, :allow_nil => true, :only_integer => true
  validates_length_of :nomen, :state, :version, :allow_nil => true, :maximum => 255
  validates_presence_of :activity, :campaign, :nomen, :state
  #]VALIDATORS]
  validates_inclusion_of :nomen, :in => self.nomen.values
  validates_presence_of :version

  acts_as_nested_set

  scope :roots, -> { where(:parent_id => nil) }

  before_validation(:on => :create) do
    if self.reference
      self.version = self.reference.version
    end
  end

  def reference
    Procedures[self.nomen]
  end

  # Returns variable names
  def variables_names
    self.variables.map(&:name).sort.to_sentence
  end

  def name
    self.nomen.text
  end

  # Return root procedure
  def root
    return (self.parent.nil? ? self : self.parent.root)
  end

  # Return the next procedure (depth course)
  def followings
    []
  end

end
