# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: yield_observations
#
#  activity_id  :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
#  geolocation  :geometry({:srid=>4326, :type=>"st_point"})
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  number       :string
#  observed_at  :datetime
#  vegetative_stage_id     :integer
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class YieldObservation < ApplicationRecord
  include Attachable
  include Providable
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :number, length: { maximum: 500 }, allow_blank: true
  validates :observed_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :activity, presence: true
  # ]VALIDATORS]
  has_many :products_yield_observations, class_name: 'ProductsYieldObservation', foreign_key: :yield_observation_id, dependent: :destroy
  has_many :plants, through: :products_yield_observations, source: :plant
  has_many :issues_yield_observations, class_name: 'IssuesYieldObservation'
  has_many :issues, through: :issues_yield_observations
  belongs_to :activity
  belongs_to :vegetative_stage
  has_geometry :geolocation, type: :point
  acts_as_numbered

  accepts_nested_attributes_for :products_yield_observations, :issues, allow_destroy: true

  def plants_name
    plants.pluck(:name).join(', ')
  end

  def issues_name
    issues.joins(:issue_nature).pluck('issue_natures.label').join(', ')
  end

  def issues_of_same_issue_nature(id)
    nature_id = issues.find(id).issue_nature_id
    issues = self.issues.where(issue_nature_id: nature_id)
    issues
  end
end
