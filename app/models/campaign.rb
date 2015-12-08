# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: campaigns
#
#  closed       :boolean          default(FALSE), not null
#  closed_at    :datetime
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  harvest_year :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string           not null
#  number       :string           not null
#  started_on   :date
#  stopped_on   :date
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Campaign < Ekylibre::Record::Base
  has_many :cap_statements
  has_one :selected_manure_management_plan, -> { selecteds }, class_name: 'ManureManagementPlan', foreign_key: :campaign_id, inverse_of: :campaign
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_date :started_on, :stopped_on, allow_blank: true, on_or_after: Date.civil(1, 1, 1)
  validates_datetime :closed_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :harvest_year, allow_nil: true, only_integer: true
  validates_inclusion_of :closed, in: [true, false]
  validates_presence_of :name, :number
  # ]VALIDATORS]
  validates_length_of :number, allow_nil: true, maximum: 60
  validates :harvest_year, length: { is: 4 }, allow_nil: true
  validates_uniqueness_of :name, :harvest_year

  acts_as_numbered :number, readonly: false

  scope :current, -> { where(closed: false).reorder(:harvest_year) }
  scope :at, ->(searched_at = Time.zone.now) { where(harvest_year: searched_at.year) }
  scope :of_activity_production, lambda { |activity_production|
    where('(started_on, stopped_on) OVERLAPS (COALESCE(?, started_on), COALESCE(?, stopped_on))', activity_production.started_on, activity_production.stopped_on)
  }
  scope :of_production, ->(production) { of_activity_production(production) }

  protect(on: :destroy) do
    interventions.any?
  end

  before_validation(on: :create) do
    if harvest_year
      self.name = harvest_year.to_s if name.blank?
      self.started_on ||= Date.new(harvest_year, 1, 1)
      self.stopped_on ||= Date.new(harvest_year, 12, 31)
    end
  end

  def self.first_of_all
    Campaign.reorder(:started_on, :harvest_year, :id).first
  end

  def activity_productions
    ActivityProduction.of_campaign(self)
  end

  def activities
    Activity.of_campaign(self)
  end

  def interventions
    Intervention.of_campaign(self)
  end

  def net_surface_area
    activity_productions.map(&:shape_area).sum
  end
  alias_method :shape_area, :net_surface_area

  def previous
    self.class.where('harvest_year < ?', harvest_year)
  end

  # Return the previous campaign
  def preceding
    self.class.where('harvest_year < ?', harvest_year).order(harvest_year: :desc).first
  end

  # Return the following campaign
  def following
    self.class.where('harvest_year > ?', harvest_year).order(:harvest_year).first
  end

  def opened?
    !closed
  end

  def close
    update_column(closed: true)
    Ekylibre::Hook.publish(:campaign_closing, campaign_id: id)
  end

  def reopen
    update_column(closed: false)
    Ekylibre::Hook.publish(:campaign_reopening, campaign_id: id)
  end
end
