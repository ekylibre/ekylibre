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
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class Campaign < Ekylibre::Record::Base
  has_many :cap_statements
  has_many :activity_budgets, inverse_of: :campaign
  has_one :selected_manure_management_plan, -> { selecteds }, class_name: 'ManureManagementPlan', foreign_key: :campaign_id, inverse_of: :campaign
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :closed_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :harvest_year, allow_nil: true, only_integer: true
  validates_inclusion_of :closed, in: [true, false]
  validates_presence_of :name
  # ]VALIDATORS]
  validates :harvest_year, length: { is: 4 }, allow_nil: true
  validates_uniqueness_of :harvest_year

  has_many :activity_productions

  scope :current, -> { where(closed: false).reorder(:harvest_year) }
  scope :at, ->(searched_at = Time.zone.now) { where(harvest_year: searched_at.year) }
  scope :of_activity_production, lambda { |activity_production|
    joins(:activity_productions).where(activity_productions: { id: activity_production.id })
  }
  scope :of_production, ->(production) { of_activity_production(production) }

  protect(on: :destroy) do
    interventions.any?
  end

  before_validation do
    self.name = harvest_year.to_s
  end

  class << self
    def of(year)
      raise 'Invalid year: ' + year.inspect unless year.to_s =~ /\A\d+\z/
      find_or_create_by!(harvest_year: year)
    end

    def first_of_all
      Campaign.reorder(:harvest_year, :id).first
    end
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
    activity_productions.map(&:support_shape_area).sum
  end
  alias shape_area net_surface_area

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
