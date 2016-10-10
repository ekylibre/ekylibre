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
    manage_restfully

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
    list(:intervention_product_parameters, conditions: { interventions: { nature: :record }, product_id: 'params[:target_id]'.c }, order: 'interventions.started_at DESC') do |t|
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

    def edit_many
      targets = Product.mine_or_undefined

      if params[:activity_id]
        activity = Activity.find_by(id: params[:activity_id])
        if activity
          targets = targets.of_variety(activity.cultivation_variety, activity.support_variety)
        end
      else
        targets = targets.where(type: %w(Animal AnimalGroup Plant LandParcel Equipment EquipmentFleet)) # .where(id: InterventionTarget.includes(:product)) #.where.not(product_id: TargetDistribution.select(:target_id)))
      end

      @target_distributions = TargetDistribution.where(target_id: targets).joins(:target).order('products.name')
      new_id = -1
      targets.order(:name).each do |target|
        unless @target_distributions.detect { |d| d.target_id == target.id }
          @target_distributions << @target_distributions.build(id: new_id, target: target, activity_production: target.best_activity_production)
        end
        new_id -= 1
      end
    end

    def update_many
      saved = true
      @target_distributions = params[:target_distributions].map do |id, target_distribution_params|
        target_distribution = TargetDistribution.find_by(id: id) || TargetDistribution.new
        target_distribution.attributes = target_distribution_params.permit(:target_id, :activity_production_id)
        if target_distribution_params[:activity_production_id].present?
          saved = false unless target_distribution.save
        end
        target_distribution
      end.sort_by(&:target_name)
      if saved
        redirect_to params[:redirect] || backend_activities_path
      else
        render 'edit_many'
      end
    end
  end
end
