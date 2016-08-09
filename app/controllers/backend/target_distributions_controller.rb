# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier, David Joulin
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
  class TargetDistributionsController < Backend::BaseController
    manage_restfully except: [:create]

    list order: { started_at: :desc } do |t|
      t.action :edit
      t.action :destroy
      t.column :target, url: true
      t.column :activity, url: true
      t.column :activity_production, url: true
      t.column :started_at
      t.column :stopped_at
    end

    # Lists intervention product parameters of the current product
    list(:intervention_product_parameters, conditions: { product_id: 'params[:target_id]'.c }, order: 'interventions.started_at DESC') do |t|
      t.column :intervention, url: true
      # t.column :roles, hidden: true
      t.column :name, sort: :reference_name
      t.column :started_at, through: :intervention, datatype: :datetime
      t.column :stopped_at, through: :intervention, datatype: :datetime, hidden: true
      t.column :human_activities_names, through: :intervention
      # t.column :intervention_activities
      t.column :human_working_duration, through: :intervention
      t.column :human_working_zone_area, through: :intervention
    end

    def create
      @target_distributions = TargetDistribution.create! (permitted_params.key?(:collection) ? permitted_params[:collection].values : permitted_params).reject { |d| d['activity_production_id'].blank? }

      redirect_to params[:redirect] || backend_campaign_path('current') if @target_distributions
    end

    def distribute
      @target_distribution = TargetDistribution.new
      @targets = InterventionTarget.where.not(product_id: TargetDistribution.select(:target_id)).includes(:product)
    end
  end
end
