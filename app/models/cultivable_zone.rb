# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  extjuncted            :boolean          default(FALSE), not null
#  financial_asset_id    :integer
#  id                    :integer          not null, primary key
#  identification_number :string
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_geolocation   :geometry({:srid=>4326, :type=>"point"})
#  initial_mother_id     :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :geometry({:srid=>4326, :type=>"geometry"})
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
#  variant_id            :integer          not null
#  variety               :string           not null
#  work_number           :string
#


class CultivableZone < Zone
  enumerize :variety, in: Nomen::Varieties.all(:cultivable_zone), predicates: {prefix: true}
  has_many :supports, class_name: "ProductionSupport", foreign_key: :storage_id
  has_many :productions, class_name: "Production", through: :supports
  has_many :memberships, class_name: "CultivableZoneMembership", foreign_key: :group_id
  has_many :members, class_name: "Product", through: :memberships
  has_many :land_parcels, class_name: "LandParcel", through: :memberships, source: :member

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      unless campaign.is_a?(Campaign)
        raise ArgumentError, "Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}"
      end
    end
    joins(:productions).where('campaign_id IN (?)', campaigns.map(&:id))
  }

  scope :of_production, lambda { |*productions|
    productions.flatten!
    for production in productions
      raise ArgumentError.new("Expected Production, got #{production.class.name}:#{production.inspect}") unless production.is_a?(Production)
    end
    joins(:productions).where('production_id IN (?)', productions.map(&:id))
  }

  after_create do
    # Compute population
    if self.initial_shape
      self.initial_shape = Charta::Geometry.new(self.initial_shape).multi_polygon
      if self.variable_indicators_list.include?(:net_surface_area)
        self.read!(:net_surface_area, ::Charta::Geometry.new(self.initial_shape).area, at: self.initial_born_at)
      end
      if self.variable_indicators_list.include?(:population)
        self.initial_population = ::Charta::Geometry.new(self.initial_shape).area / self.variant.net_surface_area
      end
    end
  end

  protect(on: :destroy) do
    self.supports.any?
  end

  # Returns members of the group at a given time (or now by default)
  def members_at(viewed_at = nil)
    LandParcel.zone_members_of(self)
  end

  # return the work_number of LandParcelClusters if exist for a CultivableLAndParcel
  def clusters_work_number(viewed_at = nil)
    land_parcels = self.members_at(viewed_at)
    numbers = []
    if land_parcels.any?
      for land_parcel in land_parcels
        groups = land_parcel.groups
        for group in groups
          if group.is_a?(LandParcelCluster)
            numbers << group.work_number
          end
        end
      end
      return numbers.to_sentence
    end
    return nil
  end

  # return the variety of all land_parcel members of the cultivable land parcel
  def soil_varieties(viewed_at = nil)
    land_parcels = self.members_at(viewed_at)
    varieties = []
    if land_parcels.any?
      for land_parcel in land_parcels
        varieties << land_parcel.soil_nature if land_parcel.soil_nature
      end
      return varieties.to_sentence
    else
      return nil
    end
  end

  # return the last_production before the production in parameter where the cultivable land parcel is a support
  # @TODO replace created_at by started_at when an input field will exist
  def last_production_before(production)
    if production.is_a?(Production) and production.started_at
      last_support = self.supports.where('created_at <= ? ',production.started_at).reorder('created_at DESC').limit(2).last
      if last_support
        return last_support.production.name
      else
        return nil
      end
    else
      return nil
    end
  end


  def administrative_area
    address = Entity.of_company.default_mail_address
    # raise address.mail_country.inspect
    if address.mail_country == "fr"
      return Nomen::AdministrativeAreas.where(code: "FR-#{address.mail_postal_code.to_s[0..1]}").first.name
    else
      return nil
    end
  end

  def estimated_soil_nature
    for land_parcel in self.land_parcels
      if nature = land_parcel.soil_nature
        return nature
      end
    end
    return nil
  end

end
