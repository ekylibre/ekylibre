# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
#  opacity        :integer
#  position       :integer
#  reference_name :string
#  subdomains     :string
#  tms            :boolean          default(FALSE), not null
#  type           :string
#  updated_at     :datetime         not null
#  updater_id     :integer
#  url            :string           not null
#
class MapBackground < MapLayer
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  # ]VALIDATORS]
  validates :by_default, inclusion: { in: [true, false] }

  scope :availables, -> { where(enabled: true).order(by_default: :desc) }
  scope :by_default, -> { availables.first }

  selects_among_all

  def self.load_defaults
    super

    default = MapLayers::Layer.of_type(model_name.name.underscore).select(&:by_default)

    where(reference_name: default.first.reference_name).first.update!(by_default: true) if default.present? && default.first.reference_name
  end
end
