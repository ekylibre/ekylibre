# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: intervention_cast_groups
#
#  created_at           :datetime         not null
#  creator_id           :integer
#  group_id             :integer
#  id                   :integer          not null, primary key
#  intervention_id      :integer          not null
#  lock_version         :integer          default(0), not null
#  parameter_group_name :string           not null
#  updated_at           :datetime         not null
#  updater_id           :integer
#

class InterventionCastGroup < Ekylibre::Record::Base
  belongs_to :intervention
  belongs_to :group, class_name: 'InterventionCastGroup'
  has_many :casts, class_name: 'InterventionCast', foreign_key: :group_id
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :intervention, :parameter_group_name
  # ]VALIDATORS]

  delegate :procedure, to: :intervention

  def parameter_group
    procedure.find(self.parameter_group_name, :parameter_group)
  end

end
