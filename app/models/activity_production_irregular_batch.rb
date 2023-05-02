# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: activity_production_irregular_batches
#
#  activity_production_batch_id :integer(4)
#  area                         :decimal(, )
#  created_at                   :datetime         not null
#  estimated_sowing_date        :date
#  id                           :integer(4)       not null, primary key
#  updated_at                   :datetime         not null
#

class ActivityProductionIrregularBatch < ApplicationRecord

  belongs_to :activity_production_batch, class_name: 'ActivityProductionBatch', foreign_key: :activity_production_batch_id, required: true

  # Sowing date should be between the period of the activity production
  validate :sowing_date_between_period_of_activity_production
  validates :estimated_sowing_date, :area, presence: true

  def sowing_date_between_period_of_activity_production
    activity_production = activity_production_batch&.activity_production
    if activity_production.present?
      if estimated_sowing_date.present? && estimated_sowing_date < activity_production.started_on
        errors.add(:estimated_sowing_date, :date_should_be_after_start_date_of_production)
      end

      if estimated_sowing_date.present? && estimated_sowing_date > activity_production.stopped_on
        errors.add(:estimated_sowing_date, :date_should_be_before_end_of_production)
      end
    end
  end
end
