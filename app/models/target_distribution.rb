# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
  include TimeLineable
  belongs_to :activity
  belongs_to :activity_production
  belongs_to :target, class_name: 'Product', inverse_of: :distributions
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(target_distribution) { target_distribution.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :activity, :activity_production, :target, presence: true
  # ]VALIDATORS]

  delegate :name, :work_number, to: :target, prefix: true

  scope :of_campaign, lambda { |campaign|
    where(activity_production_id: ActivityProduction.of_campaign(campaign))
  }

  scope :of_activity, lambda { |activity|
    where(activity: activity)
  }

  before_validation do
    if activity_production
      self.activity = activity_production.activity
      # self.started_at ||= activity_production.started_on
      # self.stopped_at ||= activity_production.stopped_on
    end
  end

  def siblings
    target.distributions unless target.nil?
  end

  def started_on
    return started_at.to_date unless started_at.nil? || started_at == Time.new(1, 1, 1, 0, 0, 0, '+00:00')
    on = begin
           Date.civil(stopped_at.year, stopped_at.month, stopped_at.day)
         rescue
           begin
             Date.civil(stopped_at.year, stopped_at.month, stopped_at.day) - 1
           rescue
             Date.today
           end
         end

    on -= 1.year
    on.to_date.beginning_of_month
  end

  def stopped_on
    return stopped_at.to_date unless stopped_at.nil?
    on = begin
           Date.civil(started_on.year, started_on.month, started_on.day)
         rescue
           Date.civil(started_on.year, started_on.month, started_on.day) - 1
         end

    on += 1.year
    on.to_date.end_of_month
  end

  class << self
    def distributed?
      InterventionTarget.where.not(product_id: TargetDistribution.select(:target_id)).select(:product_id).distinct.none?
    end
  end
end
