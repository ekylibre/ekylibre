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
# == Table: guide_analyses
#
#  acceptance_status :string(255)      not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  execution_number  :integer          not null
#  guide_id          :integer          not null
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  started_at        :datetime         not null
#  stopped_at        :datetime         not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class GuideAnalysis < Ekylibre::Record::Base
  belongs_to :guide, inverse_of: :analyses
  has_many :points, class_name: "GuideAnalysisPoint", inverse_of: :analysis
  enumerize :acceptance_status, in: [:passed, :failed, :errored, :passed_with_warnings], predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :execution_number, allow_nil: true, only_integer: true
  validates_length_of :acceptance_status, allow_nil: true, maximum: 255
  validates_presence_of :acceptance_status, :execution_number, :guide, :started_at, :stopped_at
  #]VALIDATORS]
  validates_inclusion_of :acceptance_status, in: self.acceptance_status.values

  delegate :name, to: :guide, prefix: true

  before_validation :set_execution_number, on: :create
  before_create :set_execution_number

  # Sets the execution number with the last number incremented by 1
  def set_execution_number
    self.execution_number = self.guide.analyses.max(:execution_number) + 1
  end

  def status
    {passed: :go, failing: :stop, errored: :stop, passed_with_warnings: :caution}
  end

end
