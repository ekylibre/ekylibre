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
# == Table: map_backgrounds
#
#  attribution    :string
#  by_default     :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  creator_id     :integer
#  enabled        :boolean          default(FALSE), not null
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  managed        :boolean          default(FALSE), not null
#  max_zoom       :integer
#  min_zoom       :integer
#  name           :string           not null
#  reference_name :string
#  subdomains     :string
#  tms            :boolean          default(FALSE), not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#  url            :string           not null
#
class MapBackground < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :attribution, :reference_name, :subdomains, length: { maximum: 500 }, allow_blank: true
  validates :by_default, :enabled, :managed, :tms, inclusion: { in: [true, false] }
  validates :max_zoom, :min_zoom, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, :url, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :url, format: { with: URI.regexp(%w(http https)) }

  scope :availables, -> { where(enabled: true).order(by_default: :desc) }
  scope :by_default, -> { availables.first }

  selects_among_all

  def self.load_defaults
    if MapBackgrounds::Layer.items.empty? && Rails.env.development?
      raise 'MapBackground: Layers array is empty.'
    end
    MapBackgrounds::Layer.items.each do |item|
      attrs = {
        name: item.label,
        reference_name: item.reference_name,
        enabled: item.enabled,
        by_default: item.by_default,
        url: item.url,
        attribution: item.options.try(:[], :attribution),
        subdomains: item.options.try(:[], :subdomains),
        min_zoom: item.options.try(:[], :min_zoom),
        max_zoom: item.options.try(:[], :max_zoom),
        managed: true
      }
      where(reference_name: item.reference_name).first_or_create(attrs)
    end

    default = MapBackgrounds::Layer.items.select(&:by_default)

    if default.size >= 1 && default.first.reference_name
      where(reference_name: default.first.reference_name).first.update!(by_default: true)
    end
  end

  def to_json_object
    JSON.parse(to_json).compact.select { |_, value| value != '' }.deep_transform_keys { |key| key.to_s.camelize(:lower) }
  end
end
