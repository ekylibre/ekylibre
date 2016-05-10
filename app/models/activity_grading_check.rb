# coding: utf-8
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
# == Table: activity_grading_checks
#
#  activity_id           :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  id                    :integer          not null, primary key
#  lock_version          :integer          default(0), not null
#  maximal_calibre_value :decimal(19, 4)
#  minimal_calibre_value :decimal(19, 4)
#  nature                :string           not null
#  position              :integer
#  quality_criterion_id  :integer
#  updated_at            :datetime         not null
#  updater_id            :integer
#

class ActivityGradingCheck < Ekylibre::Record::Base
  belongs_to :activity
  belongs_to :quality_criterion, class_name: 'GradingQualityCriterion'
  enumerize :nature, in: [:calibre, :quality], default: :calibre, predicates: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :maximal_calibre_value, :minimal_calibre_value, allow_nil: true
  validates_presence_of :activity, :nature
  # ]VALIDATORS]
  validates_presence_of :quality_criterion, if: :quality?

  delegate :grading_calibre_unit, to: :activity

  # FIXME: Not i18nized!
  def name
    if quality?
      quality_criterion.name
    else
      "#{minimal_calibre_value.in(grading_calibre_unit).l(precision: 0)} → #{maximal_calibre_value.in(grading_calibre_unit).l(precision: 0)}"
    end
  end
end
