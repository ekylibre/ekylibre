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
# == Table: worker_time_indicators
#
#  duration  :interval
#  start_at  :datetime
#  stop_at   :datetime
#  worker_id :integer(4)
#

class WorkerTimeIndicator < ApplicationRecord
  include HasInterval

  belongs_to :worker

  has_interval :duration

  scope :between, lambda { |started_at, stopped_at|
    where(start_at: started_at..stopped_at)
  }

  scope :of_year, lambda { |year|
    where('EXTRACT(YEAR FROM start_at) = ?', year)
  }

  scope :of_workers, lambda { |workers|
    where(worker: workers)
  }

  class << self
    def refresh
      Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
    end

    def durations(unit = :hour)
      total = self.sum(:duration)
      if total == "0"
        minutes = 0.00
      else
        minutes = ActiveSupport::Duration.parse(total).in_full(:minute)
      end
      Measure.new(minutes, :minute).convert(unit).round(2)
    end
  end

  def readonly?
    true
  end

end
