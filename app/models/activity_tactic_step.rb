# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: activity_tactic_steps
#
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  name             :string           not null
#  procedure_action :string           not null
#  started_on       :date
#  stopped_on       :date
#  tactic_id        :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#
class ActivityTacticStep < Ekylibre::Record::Base

  refers_to :procedure_action, class_name: 'ProcedureAction'
  belongs_to :tactic, class_name: 'ActivityTactic', inverse_of: :tactic_steps

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :started_on, :stopped_on, timeliness: { allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, timeliness: { allow_blank: true, on_or_after: :started_on }, if: ->(activity_tactic_step) { activity_tactic_step.stopped_on && activity_tactic_step.started_on }
  validates :name, :procedure_action, :tactic, presence: true
  # ]VALIDATORS]

end
