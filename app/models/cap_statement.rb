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
# == Table: cap_statements
#
#  campaign_id       :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  entity_id         :integer
#  exploitation_name :string           not null
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  pacage_number     :string           not null
#  siret_number      :string           not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class CapStatement < Ekylibre::Record::Base
  belongs_to :campaign
  belongs_to :entity
  has_many :cap_islets, class_name: 'CapIslet', dependent: :destroy
  has_many :cap_land_parcels, through: :cap_islets
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :campaign, :exploitation_name, :pacage_number, :siret_number
  # ]VALIDATORS]
  delegate :harvest_year, to: :campaign, prefix: false

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      unless campaign.is_a?(Campaign)
        fail ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}")
      end
    end
    where(campaign_id: campaigns.map(&:id))
  }

  def net_surface_area(_unit = :hectare)
    total_net_surface_area = cap_islets.map(&:net_surface_area).flatten.sum
  end
end
