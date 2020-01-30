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
# == Table: map_layers
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
#  nature         :string
#  opacity        :integer
#  position       :integer
#  reference_name :string
#  subdomains     :string
#  tms            :boolean          default(FALSE), not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#  url            :string           not null
#
class MapLayer < Ekylibre::Record::Base
  enumerize :nature, in: %i[background overlay], default: :background, predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :attribution, :reference_name, :subdomains, length: { maximum: 500 }, allow_blank: true
  validates :by_default, :enabled, :managed, :tms, inclusion: { in: [true, false] }
  validates :max_zoom, :min_zoom, :opacity, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, :url, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :url, format: { with: URI.regexp(%w[http https]) }
  validates :opacity, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_blank: true

  selects_among_all subset: :backgrounds

  scope :available, -> { where(enabled: true) }
  scope :availables, -> { available }

  scope :backgrounds, -> { where(nature: :background) }
  scope :overlays, -> { where(nature: :overlay) }

  scope :available_backgrounds, -> { available.backgrounds.order(by_default: :desc) }
  scope :available_overlays, -> { available.overlays }
  scope :default_backgrounds, -> { available_backgrounds }

  before_validation do
    self.opacity ||= 50
  end

  def self.default_background
    default_backgrounds.first
  end

  def self.load_defaults(**_options)
    Map::Layer.find_each do |item|
      attrs = {
        name: item.label,
        nature: item.type.to_sym,
        reference_name: item.reference_name,
        enabled: item.enabled,
        by_default: item.by_default,
        url: item.url,
        attribution: item.options.try(:[], :attribution),
        subdomains: item.options.try(:[], :subdomains),
        min_zoom: item.options.try(:[], :min_zoom),
        max_zoom: item.options.try(:[], :max_zoom),
        managed: true,
        opacity: item.options.try(:[], :opacity)
      }
      where(reference_name: item.reference_name).first_or_create!(attrs)
    end

    default = Map::Layer.of_type(:background).select(&:by_default)
    where(reference_name: default.first.reference_name).first.update!(by_default: true) if default.present? && default.first.reference_name && find_by(reference_name: default.first.reference_name)
  end

  def to_json_object
    JSON.parse(to_json).compact.reject { |_, value| value == '' }.deep_transform_keys { |key| key.to_s.camelize(:lower) }
  end
end
