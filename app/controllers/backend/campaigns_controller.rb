# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class CampaignsController < Backend::BaseController
    manage_restfully

    unroll

    list do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :harvest_year
      t.column :closed
    end

    # List of productions for one campaign
    list(:activity_productions, conditions: "campaign = Campaign.find(params[:id])\n['(started_on, stopped_on) OVERLAPS (?, ?)', campaign.started_on, campaign.stopped_on]".c, order: { started_at: :desc }) do |t|
      t.column :name, url: true
      # t.column :product_nature, url: true
      t.column :state
      t.column :started_at
      t.column :stopped_at
    end
  end
end
