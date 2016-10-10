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
  has_many :cap_statements, dependent: :restrict_with_exception
  has_many :activity_budgets, inverse_of: :campaign, dependent: :restrict_with_exception
  has_one :selected_manure_management_plan, -> { selecteds }, class_name: 'ManureManagementPlan', foreign_key: :campaign_id, inverse_of: :campaign

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :closed, inclusion: { in: [true, false] }
  validates :closed_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :harvest_year, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :harvest_year, length: { is: 4 }, allow_nil: true
  validates :harvest_year, uniqueness: true

  has_and_belongs_to_many :activities
  has_and_belongs_to_many :interventions
  has_and_belongs_to_many :activity_productions

  scope :current, -> { where(closed: false).reorder(:harvest_year) }
  scope :at, ->(searched_at = Time.zone.now) { where(harvest_year: searched_at.year) }
  scope :of_activity_production, lambda { |activity_production|
    where('id IN (SELECT campaign_id FROM activity_productions_campaigns WHERE activity_production_id = ?)', activity_production.id)
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

  # Returns all CampaignProduction. These productions always last the campaign
  # duration
  def productions
    CampaignProduction.of(self)
  end

  # Returns the cost of production for the given campaign. It's the sum of all
  # "campaign production" production cost
  def productions_cost_amount
    productions.map(:cost_amount).sum
  end

  # FIXME: Not generic. Some activities have no shape
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
