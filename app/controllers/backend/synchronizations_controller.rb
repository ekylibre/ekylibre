# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier, David Joulin
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
  class SynchronizationsController < Backend::BaseController
    def index; end

    def run
      cooperative_cartodb if params[:id] == 'cooperative_cartodb'
      redirect_to params[:redirect] || { action: :index }
    end

    protected

    # for testing data upload for unicoque traceability in cartodb account
    # Activity :orchard_crops
    def cooperative_cartodb
      if (account = Identifier.find_by(nature: :cooperative_cartodb_account)) &&
         (key = Identifier.find_by(nature: :cooperative_cartodb_key))
        @cooperative_config = { account: account.value, key: key.value }
        @cooperative_config[:member] = Entity.of_company.name.downcase
        conn = CartoDBConnection.new(@cooperative_config[:account], @cooperative_config[:key])
        data = []
        company = @cooperative_config[:member]
        activities = Activity.of_families(:arboriculture)
        Intervention.includes(:production, :production_support, :issue, :recommender, :activity, :campaign, :storage).of_activities(activities).find_each do |intervention|
          line = {
            company: company,
            campaign:   intervention.campaign.name,
            activity:   intervention.activity.name,
            production: intervention.production.name,
            intervention_recommended: intervention.recommended,
            intervention_recommender_name: (intervention.recommended ? intervention.recommender.name : nil),
            intervention_name: intervention.name,
            intervention_reference: intervention.procedure.human_name,
            intervention_start_time: intervention.start_time,
            intervention_duration: (intervention.duration.to_d / 3600).round(2),
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
          q = 'INSERT INTO interventions (' + insert.join(', ') + ') SELECT ' + values.join(', ')
          conn.exec(q)
        end
      end
    end

    class CartoDBConnection
      def initialize(account, key)
        @account = account
        @key = key
      end

      def exec(sql)
        Rails.logger.debug "[#{@account}] #{sql}"
        Rails.logger.debug "[#{@account}] " + Net::HTTP.get(URI.parse("http://#{@account}.cartodb.com/api/v2/sql?q=#{URI.encode(sql)}&api_key=#{@key}"))
      end
    end
  end
end
