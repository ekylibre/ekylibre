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
# == Table: entity_links
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  entity_1_id  :integer          not null
#  entity_2_id  :integer          not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  nature       :string(255)      not null
#  started_at   :datetime
#  stopped_at   :datetime
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class EntityLink < Ekylibre::Record::Base
  # attr_accessible :description, :entity_1_id, :entity_2_id, :nature, :started_at, :stopped_at
  belongs_to :entity_1, :class_name => "Entity"
  belongs_to :entity_2, :class_name => "Entity"
  # belongs_to :nature, :class_name => "EntityLinkNature"
  enumerize :nature, :in => Nomen::EntityLinkNatures.all

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :allow_nil => true, :maximum => 255
  validates_presence_of :entity_1, :entity_2, :nature
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values

  scope :of_entity, lambda { |entity| where("stopped_at IS NULL AND ? IN (entity_1_id, entity_2_id)", entity.id) }
  scope :actives, -> {
    now = Time.now
    where("? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?)", now, now, now)
  }

  before_validation do
    self.started_at ||= Time.now
  end

end
