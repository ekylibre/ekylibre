# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: activity_tactics
#
#  activity_id  :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  mode         :string
#  mode_delta   :integer
#  name         :string           not null
#  planned_on   :date
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ActivityTactic < ApplicationRecord
  enumerize :mode, in: %i[sowed harvested], default: :sowed

  belongs_to :activity, class_name: 'Activity', inverse_of: :tactics
  belongs_to :campaign, class_name: 'Campaign', inverse_of: :tactics
  belongs_to :technical_workflow, class_name: 'TechnicalWorkflow', inverse_of: :tactics
  belongs_to :technical_sequence, class_name: 'TechnicalSequence', inverse_of: :tactics
  belongs_to :technical_itinerary, class_name: 'TechnicalItinerary'
  has_many :productions, class_name: 'ActivityProduction', inverse_of: :tactic, foreign_key: :tactic_id

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :default, inclusion: { in: [true, false] }, allow_blank: true
  validates :mode_delta, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :planned_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }, allow_blank: true
  validates :activity, presence: true
  # ]VALIDATORS]

  scope :default, -> { where(default: true) }

  scope :of_campaign, lambda { |campaign| where(campaign: campaign)}

  scope :of_activity, lambda { |activity| where(activity: activity)}

  before_validation do
    set_default_name
    set_planned_on
  end

  def set_default_name
    if name.blank? && campaign
      if technical_itinerary
        self.name = "#{technical_itinerary.name} #{campaign.name}"
      elsif technical_workflow
        self.name =  "#{technical_workflow.translation.send(Preference[:language])} #{campaign.name}"
      elsif technical_sequence
        self.name = "#{technical_sequence.translation.send(Preference[:language])} #{campaign.name}"
      end
    end
  end

  def set_planned_on
    year_delta = activity.production_started_on_year
    if planned_on.blank? && year_delta && technical_workflow && campaign
      self.planned_on = Date.new((campaign.harvest_year + year_delta), technical_workflow.start_month, technical_workflow.start_day)
    end
  end

  def of_family
    Activity.where(id: activity_id).map(&:family).join.to_sym
  end

  def mode_unit_name
    :day
  end

  def mode_unit_name=(value)
    raise ArgumentError.new('Mode unit must be: day') unless value.to_s == 'day'
  end
end
