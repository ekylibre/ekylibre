# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: guide_analyses
#
#  acceptance_status :string           not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  execution_number  :integer          not null
#  guide_id          :integer          not null
#  id                :integer          not null, primary key
#  latest            :boolean          default(FALSE), not null
#  lock_version      :integer          default(0), not null
#  started_at        :datetime         not null
#  stopped_at        :datetime         not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class GuideAnalysis < Ekylibre::Record::Base
  belongs_to :guide, inverse_of: :analyses
  has_many :points, class_name: 'GuideAnalysisPoint', inverse_of: :analysis, foreign_key: :analysis_id, dependent: :destroy
  enumerize :acceptance_status, in: %i[passed passed_with_warnings failed errored], predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :acceptance_status, :guide, presence: true
  validates :execution_number, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :latest, inclusion: { in: [true, false] }
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :stopped_at, presence: true, timeliness: { on_or_after: ->(guide_analysis) { guide_analysis.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  validates :acceptance_status, inclusion: { in: acceptance_status.values }

  scope :latests, -> { where(latest: true) }
  selects_among_all :latest, scope: :guide_id

  delegate :name, to: :guide, prefix: true

  before_validation :set_execution_number, on: :create
  before_create :set_execution_number
  after_create :set_latest!

  # Sets the execution number with the last number incremented by 1
  def set_execution_number
    if guide&.analyses
      self.execution_number = guide.analyses.maximum(:execution_number).to_i + 1
    end
  end

  def status
    { passed: :go, failed: :stop, errored: :stop, passed_with_warnings: :caution }.with_indifferent_access[acceptance_status]
  end

  def points_count(status)
    points.where(acceptance_status: status).count
  end
end
