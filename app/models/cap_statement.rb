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
# == Table: cap_statements
#
#  campaign_id   :integer(4)       not null
#  created_at    :datetime         not null
#  creator_id    :integer(4)
#  declarant_id  :integer(4)
#  farm_name     :string
#  id            :integer(4)       not null, primary key
#  lock_version  :integer(4)       default(0), not null
#  pacage_number :string
#  siret_number  :string
#  updated_at    :datetime         not null
#  updater_id    :integer(4)
#

class CapStatement < ApplicationRecord
  belongs_to :campaign
  belongs_to :declarant, class_name: 'Entity'
  has_many :islets, class_name: 'CapIslet', dependent: :destroy
  has_many :cap_neutral_areas, dependent: :destroy
  has_many :cap_islets, dependent: :destroy
  has_many :cap_land_parcels, through: :cap_islets
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :farm_name, :pacage_number, :siret_number, length: { maximum: 500 }, allow_blank: true
  validates :campaign, presence: true
  # ]VALIDATORS]
  validates :farm_name, :pacage_number, :siret_number, presence: true

  alias_attribute :entity, :declarant

  delegate :harvest_year, to: :campaign, prefix: false

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    campaigns.each do |campaign|
      unless campaign.is_a?(Campaign)
        raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}")
      end
    end
    where(campaign_id: campaigns.map(&:id))
  }

  def net_surface_area(unit = :hectare)
    cap_islets.map(&:net_surface_area).sum.in(unit)
  end

  def human_net_surface_area(unit = :hectare)
    net_surface_area(unit).round(2)
  end
end
