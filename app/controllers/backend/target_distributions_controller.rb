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

      targets = if params[:activity_id] && activity = Activity.find_by(id: params[:activity_id])
                  targets.of_variety(activity.cultivation_variety, activity.support_variety)
                else
                  targets.generic_supports
                end

      @target_distributions = if params[:activity_id] && activity = Activity.find_by(id: params[:activity_id])
                                TargetDistribution.where(target_id: targets, activity: activity).joins(:target).order('products.name')
                              else
                                TargetDistribution.where(target_id: targets).joins(:target).order('products.name')
                              end

      targets = targets.where.not(id: @target_distributions.pluck(:target_id))

      activity_productions = ActivityProduction.where(id:
        targets.joins('JOIN activity_productions ON activity_productions.support_id = products.id')
               .select('MAX(activity_productions.id)')
               .group('products.id'))

      activity_productions = activity_productions.pluck(:support_id, :id).to_h

      targets.order(:name).pluck(:id).each_with_index do |target_id, id|
        @target_distributions << @target_distributions.build(
          id: -id,
          target_id: target_id,
          activity_production_id: activity_productions[target_id]
        )
      end
    end

    def update_many
      saved = true
      @target_distributions = params[:target_distributions].map do |id, target_distribution_params|
        target_distribution = TargetDistribution.find_by(id: id) || TargetDistribution.new
        target_distribution.attributes = target_distribution_params.permit(:target_id, :activity_production_id)
        if target_distribution_params[:activity_production_id].present? && target_distribution_params[:activity_production_id] != target_distribution.id
          saved = false unless target_distribution.save
        elsif target_distribution_params[:activity_production_id].empty? && !target_distribution.id.nil?
          saved = false unless target_distribution.destroy
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
