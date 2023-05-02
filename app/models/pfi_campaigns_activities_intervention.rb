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
# == Table: pfi_campaigns_activities_interventions
#
#  activity_id                      :integer(4)
#  activity_pfi_value               :decimal(, )
#  activity_production_id           :integer(4)
#  activity_production_pfi_value    :decimal(, )
#  activity_production_surface_area :decimal(19, 4)
#  campaign_id                      :integer(4)
#  crop_id                          :integer(4)
#  crop_pfi_value                   :decimal(, )
#  crop_surface_area                :decimal(19, 4)
#  segment_code                     :string
#

class PfiCampaignsActivitiesIntervention < ApplicationRecord
  belongs_to :campaign
  belongs_to :activity
  belongs_to :activity_production
  belongs_to :crop, class_name: 'Product'

  scope :of_campaign, ->(campaign) { where(campaign: campaign) }
  scope :of_activity, ->(activity) { where(activity: activity) }
  scope :of_activity_production, ->(activity_production) { where(activity_production: activity_production) }
  scope :of_segment, ->(segment_code) { where(segment_code: segment_code) }

  def readlonly?
    true
  end

  def self.pfi_value_on_activity_campaign(activity, campaign)
    of_activity(activity).of_campaign(campaign).sum(:activity_pfi_value)
  end

  def self.pfi_value_on_activity_production_campaign(activity_production, campaign)
    of_activity_production(activity_production).of_campaign(campaign).sum(:activity_production_pfi_value)
  end

end
