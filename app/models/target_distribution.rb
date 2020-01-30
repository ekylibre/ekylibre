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
# == Table: target_distributions
#
#  activity_id            :integer          not null
#  activity_production_id :integer          not null
#  created_at             :datetime         not null
#  creator_id             :integer
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  started_at             :datetime
#  stopped_at             :datetime
#  target_id              :integer          not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#
class TargetDistribution < Ekylibre::Record::Base
  belongs_to :activity
  belongs_to :activity_production
  belongs_to :target, class_name: 'Product', inverse_of: :distributions

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(target_distribution) { target_distribution.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :activity, :activity_production, :target, presence: true
  # ]VALIDATORS]

  before_validation do
    raise 'TargetDistribution is deprecated'
  end

  after_initialize do
    raise 'TargetDistribution is deprecated'
  end

  def method_missing(**_args)
    raise 'TargetDistribution is deprecated'
  end
end
