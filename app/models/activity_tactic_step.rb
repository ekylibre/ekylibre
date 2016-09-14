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
#  action              :string
#  created_at          :datetime         not null
#  creator_id          :integer
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  name                :string           not null
#  procedure_categorie :string           not null
#  procedure_name      :string
#  started_on          :date             not null
#  stopped_on          :date             not null
#  tactic_id           :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#

class ActivityTacticStep < Ekylibre::Record::Base
  refers_to :procedure_categorie, class_name: 'ProcedureCategory'
  refers_to :action, class_name: 'ProcedureAction'

  belongs_to :tactic, class_name: 'ActivityTactic', inverse_of: :steps

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :name, presence: true, length: { maximum: 500 }
  validates :procedure_categorie, :tactic, presence: true
  validates :procedure_name, length: { maximum: 500 }, allow_blank: true
  validates :started_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :stopped_on, presence: true, timeliness: { on_or_after: ->(activity_tactic_step) { activity_tactic_step.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  # ]VALIDATORS]

  def of_procedures_name
    Procedo.procedures_of_main_category(procedure_categorie)
  end

  def of_actions
    Procedo.find(procedure_name).optional_actions_selection
  end
end
