# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: worker_time_logs
#
#  created_at    :datetime         not null
#  creator_id    :integer(4)
#  custom_fields :jsonb            default("{}")
#  description   :text
#  duration      :integer(4)       not null
#  id            :integer(4)       not null, primary key
#  lock_version  :integer(4)       default(0), not null
#  provider      :jsonb            default("{}")
#  started_at    :datetime         not null
#  stopped_at    :datetime         not null
#  updated_at    :datetime         not null
#  updater_id    :integer(4)
#  worker_id     :integer(4)       not null
#

class WorkerTimeLog < ApplicationRecord
  include Customizable
  include Providable
  belongs_to :worker
  has_one :person, through: :worker
  has_one :user, through: :person

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :duration, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :stopped_at, presence: true, timeliness: { on_or_after: ->(worker_time_log) { worker_time_log.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :worker, presence: true
  # ]VALIDATORS]
  validates :duration, presence: true, numericality: { greater_than: 0, less_than: 86_400 }
  validate :duration_is_between_0_and_24h, if: :duration
  validate :stopped_at_is_valid, if: :stopped_at

  scope :between, lambda { |started_at, stopped_at|
    where(started_at: started_at..stopped_at)
  }

  scope :of_year, lambda { |year|
    where('EXTRACT(YEAR FROM started_at) = ?', year)
  }

  scope :of_workers, lambda { |workers|
    where(worker: workers)
  }

  scope :provisional, -> { where('stopped_at > ?', Time.zone.now) }
  scope :real, -> { where('stopped_at <= ?', Time.zone.now) }

  before_validation do
    if started_at && stopped_at
      self.duration = (stopped_at - started_at).to_i
    elsif started_at && duration
      self.stopped_at = started_at + duration
    elsif duration
      self.started_at ||= Time.zone.now
      self.stopped_at ||= self.started_at + duration
    end
    true
  end

  after_save do
    WorkerTimeIndicator.refresh # refresh view
  end

  def start_name
    "#{started_at.l} - #{worker.name}"
  end

  def human_period
    "#{started_at.l(format: '%H:%M')} - #{stopped_at.l(format: '%H:%M')} | #{human_duration}"
  end

  def human_duration(unit = :hour)
    duration&.in(:second)&.convert(unit)&.round(2)&.l(precision: 2)
  end

  private

    def duration_is_between_0_and_24h
      if duration >= 86_400
        errors.add(:duration, :less_than, count: '24H')
      end
      if duration < 0
        errors.add(:duration, :greater_than, count: '0H')
      end
    end

    def stopped_at_is_valid
      if started_at && stopped_at <= started_at
        errors.add(:stopped_at, :posterior, to: started_at.l)
      end
      if stopped_at > Time.zone.now
        errors.add(:stopped_at, :before, restriction: Time.zone.now.l)
      end
    end

end
