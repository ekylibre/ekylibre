# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: supervision_items
#
#  color          :string
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  sensor_id      :integer          not null
#  supervision_id :integer          not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#
class SupervisionItem < Ekylibre::Record::Base
  belongs_to :sensor
  belongs_to :supervision, inverse_of: :items
  has_many :analyses, through: :sensor
  has_many :analysis_items, through: :analyses, source: :items
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :color, length: { maximum: 500 }, allow_blank: true
  validates :sensor, :supervision, presence: true
  # ]VALIDATORS]

  delegate :name, to: :sensor
  delegate :time_window, to: :supervision

  def indicator_names
    list = analysis_items.pluck(:indicator_name)
    list.uniq
  end

  def historic_of(indicator_name)
    analysis_items.includes(:analysis).where(indicator_name: indicator_name).where('sampled_at > ?', Time.now - time_window).collect do |item|
      [item.analysis.sampled_at.to_usec, item.value.to_f]
    end
  end

  def geolocation_path
    analyses.where('sampled_at > ?', Time.now - time_window)
  end

  def geolocalized?
    true
  end
end
