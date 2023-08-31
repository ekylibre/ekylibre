# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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
# == Table: projects
#
#  activity_id      :integer
#  closed           :boolean          default(FALSE), not null
#  comment          :text
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  name             :string           not null
#  nature           :string           not null
#  responsible_id   :integer
#  sale_contract_id :integer
#  started_on       :date
#  stopped_on       :date
#  team_id          :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#  work_number      :string
#
class Project < ApplicationRecord
  include Attachable
  enumerize :nature, in: %i[direct_earning indirect_earning], predicates: { prefix: true }
  belongs_to :activity
  belongs_to :team
  belongs_to :sale_contract
  belongs_to :responsible, class_name: 'User'
  has_many :members, class_name: 'ProjectMember', dependent: :destroy, inverse_of: :project
  has_many :tasks, class_name: 'ProjectTask', dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :closed, inclusion: { in: [true, false] }
  validates :comment, length: { maximum: 500_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :nature, presence: true
  validates :started_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :stopped_on, timeliness: { on_or_after: ->(project) { project.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :work_number, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]

  accepts_nested_attributes_for :members

  protect on: :destroy do
    tasks.any?
  end

  def full_name
    name + ' | ' + forecast_duration
  end

  def forecast_duration
    duration = 0.0
    if tasks.any?
      tasks.each do |t|
        if t.forecast_duration && t.forecast_duration.to_f > 0.0
          if t.forecast_duration_unit == :hour
            duration += t.forecast_duration.to_f
          elsif t.forecast_duration_unit == :day
            duration += (t.forecast_duration.to_f * 7)
          end
        end
      end
    end
    duration.in(:hour).round(2).l
  end

  def real_duration(start_on = nil, stop_on = nil)
    duration = 0.0
    if tasks.any?
      tasks.each do |t|
        duration += t.real_duration(start_on, stop_on).to_f
      end
    end
    duration.in(:hour).round(2).l
  end

  def time_ratio
    if forecast_duration && forecast_duration.to_f != 0.0
      (real_duration.to_f / forecast_duration.to_f).round(2) * 100
    end
  end

  # Returns timeleft in seconds of the project
  def timeleft(at = Time.zone.now)
    return nil if stopped_on.nil? || stopped_on.to_time <= at

    (stopped_on.to_time - at)
  end
end
