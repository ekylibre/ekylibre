# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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
# == Table: activity_distributions
#
#  activity_id            :integer          not null
#  affectation_percentage :decimal(19, 4)   not null
#  created_at             :datetime         not null
#  creator_id             :integer
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  main_activity_id       :integer          not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#
class ActivityDistribution < Ekylibre::Record::Base
  belongs_to :activity, inverse_of: :distributions
  belongs_to :main_activity, class_name: 'Activity'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :affectation_percentage, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :activity, :main_activity, presence: true
  # ]VALIDATORS]
  validates :affectation_percentage, numericality: { greater_than: 0 }

  delegate :name, to: :main_activity, prefix: true
end
