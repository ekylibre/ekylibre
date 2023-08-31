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
# == Table: project_tasks
#
#  billing_method         :string
#  comment                :text
#  created_at             :datetime         not null
#  creator_id             :integer
#  forecast_duration      :decimal(9, 2)
#  forecast_duration_unit :string
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  name                   :string           not null
#  project_id             :integer          not null
#  responsible_id         :integer
#  sale_contract_item_id  :integer
#  started_on             :date
#  stopped_on             :date
#  updated_at             :datetime         not null
#  updater_id             :integer
#  work_number            :string
#
class ProjectTask < ApplicationRecord
  enumerize :forecast_duration_unit, in: %i[hour day], default: :hour, predicates: { prefix: true }
  enumerize :billing_method, in: %i[elapsed_time fixed], default: :fixed, predicates: { prefix: true }
  belongs_to :project
  belongs_to :responsible, class_name: 'User'
  belongs_to :sale_contract_item, inverse_of: :project_tasks
  belongs_to :sale_item, inverse_of: :project_tasks
  belongs_to :purchase_item, inverse_of: :project_tasks
  has_many :logs, class_name: 'WorkerTimeLog', dependent: :destroy, inverse_of: :project_task
  has_one :team, through: :project
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :comment, length: { maximum: 500_000 }, allow_blank: true
  validates :forecast_duration, numericality: { greater_than: -10_000_000, less_than: 10_000_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :started_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :stopped_on, timeliness: { on_or_after: ->(project_task) { project_task.started_on || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }, allow_blank: true
  validates :project, presence: true
  # ]VALIDATORS]
  # acts_as_list scope: :project_id

  protect on: :destroy do
    logs.any?
  end

  def real_duration(start_on = nil, stop_on = nil, unit = :hour)
    duration = 0.0
    if logs.any? && (start_on.nil? || stop_on.nil?)
      duration = logs.sum(:duration)
    elsif logs.any?
      duration = logs.between(start_on, stop_on).sum(:duration)
    end
    duration&.in(:second)&.convert(unit)&.round(2)&.l
  end

  def time_ratio
    if forecast_duration && forecast_duration != 0.0
      (real_duration.to_f / forecast_duration.to_f).round(2) * 100
    end
  end
end
