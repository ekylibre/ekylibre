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
# == Table: products
#
#  address_id            :integer
#  born_at               :datetime
#  category_id           :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  dead_at               :datetime
#  default_storage_id    :integer
#  derivative_of         :string
#  description           :text
#  fixed_asset_id        :integer
#  id                    :integer          not null, primary key
#  identification_number :string
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_geolocation   :geometry({:srid=>4326, :type=>"point"})
#  initial_mother_id     :integer
#  initial_movement_id   :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :geometry({:srid=>4326, :type=>"multi_polygon"})
#  lock_version          :integer          default(0), not null
#  name                  :string           not null
#  nature_id             :integer          not null
#  number                :string           not null
#  parent_id             :integer
#  person_id             :integer
#  picture_content_type  :string
#  picture_file_name     :string
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  tracking_id           :integer
#  type                  :string
#  updated_at            :datetime         not null
#  updater_id            :integer
#  uuid                  :uuid
#  variant_id            :integer          not null
#  variety               :string           not null
#  work_number           :string
#
class Plant < Bioproduct
  refers_to :variety, scope: :plant

  has_shape

  # Return all Plant object who is alive in the given campaigns
  scope :of_campaign, lambda { |campaign|
    unless campaign.is_a?(Campaign)
      fail ArgumentError, "Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}"
    end
    started_at = Date.new(campaign.harvest_year.to_f, 01, 01)
    stopped_at = Date.new(campaign.harvest_year.to_f, 12, 31)
    where('born_at <= ? AND (dead_at IS NULL OR dead_at <= ?)', stopped_at, stopped_at)
  }

  after_validation do
    # Compute population
    if initial_shape && nature
      # self.initial_shape = ::Charta.new_geometry(initial_shape).multi_polygon
      if variable_indicators_list.include?(:net_surface_area)
        self.read!(:net_surface_area, ::Charta.new_geometry(initial_shape).area, at: initial_born_at)
      end
      if variable_indicators_list.include?(:population)
        self.initial_population = ::Charta.new_geometry(initial_shape).area / variant.net_surface_area
      end
    end
  end

  def status
    if self.dead_at?
      return :stop
    elsif issues.any?
      return (issues.where(state: :opened).any? ? :caution : :go)
    else
      return :go
    end
  end
end
