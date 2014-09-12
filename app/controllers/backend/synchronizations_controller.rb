# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::SynchronizationsController < BackendController
  before_action :load_config

  class CartoDBConnection
    def initialize(account, key)
      @account = account
      @key = key
    end

    def exec(sql)
      puts "[#{@account}] #{sql}"
      puts "[#{@account}] " + Net::HTTP.get(URI.parse("http://#{@account}.cartodb.com/api/v2/sql?q=#{URI.encode(sql)}&api_key=#{@key}"))
    end
  end


  def index
    if params[:campaign_ids]
      @campaigns = Campaign.find(params[:campaign_ids])
    else
      @campaigns = Campaign.currents.last
    end
  end

  # for testing data upload for unicoque traceability in cartodb account
  # Activity :orchard_crops
  def update
    if @cooperative_config

      conn = CartoDBConnection.new(@cooperative_config[:account], @cooperative_config[:key])
      data = []
      company = @cooperative_config[:member]
      activities = Activity.of_families(:orchard_crops)
      Intervention.includes(:production, :production_support, :issue, :recommender, :activity, :campaign, :storage).of_activities(activities).find_each do |intervention|
        line = {
          company: company,
          campaign:   intervention.campaign.name,
          activity:   intervention.activity.name,
          production: intervention.production.name,
          intervention_recommended: intervention.recommended,
          intervention_recommender_name: (intervention.recommended ? intervention.recommender.name : nil),
          intervention_name:    intervention.name,
          intervention_reference:    intervention.reference.human_name,
          intervention_start_time:    intervention.start_time,
          intervention_duration:    (intervention.duration.to_d / 3600).round(2),
          support: intervention.storage.name,
          the_geom:   (intervention.storage.shape ? intervention.storage.shape_to_ewkt : nil),
          tool_cost:  intervention.cost(:tool).to_s.to_f.round(2),
          input_cost: intervention.cost(:input).to_s.to_f.round(2),
          time_cost:  intervention.cost(:doer).to_s.to_f.round(2)
        }
        data << line
      end
      conn.exec("DELETE FROM interventions WHERE company='#{company}'")
      for line in data
        insert = []
        values = []
        for name, value in line
          insert << name
          values << ActiveRecord::Base.connection.quote(value)
        end
        q = "INSERT INTO interventions (" + insert.join(', ') + ") SELECT " + values.join(', ')
        conn.exec(q)
      end

    end
    render(:show)
  end


  protected

  def load_config
    if cooperative_cartodb_account = Identifier.find_by_nature(:cooperative_cartodb_account) and cooperative_cartodb_key = Identifier.find_by_nature(:cooperative_cartodb_key)
      @cooperative_config = {account: cooperative_cartodb_account.value, key: cooperative_cartodb_key.value}
      @cooperative_config[:member] = Entity.of_company.name.downcase
    end
  end

end
