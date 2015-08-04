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

class Backend::ProductionsController < Backend::BaseController
  manage_restfully(t3e: { name: :name }, campaign_id: '(params[:campaign_id] ? params[:campaign_id] : current_campaign ? current_campaign.id : nil)'.c)

  unroll :name, { activity: :name, campaign: :name, cultivation_variant: :name }, order: :name

  # params:
  #   :q Text search
  #   :s State search
  #   :campaign_id
  #   :cultivation_variant_id
  def self.productions_conditions
    code = ''
    code = search_conditions(productions: [:state], activities: [:name], product_nature_variants: [:name]) + " ||= []\n"
    # code << "unless params[:s].blank?\n"
    # code << "  unless params[:s] == 'all'\n"
    # code << "    c[0] << \" AND state = ?\"\n"
    # code << "    c << params[:s]\n"
    # code << "  end\n"
    # code << "end\n "
    code << "if current_campaign\n"
    code << "  c[0] << \" AND \#{Campaign.table_name}.id = ?\"\n"
    code << "  c << current_campaign.id\n"
    code << "end\n"
    code << "if params[:cultivation_variant_id].to_i > 0\n"
    code << "  c[0] << \" AND \#{ProductNatureVariant.table_name}.id = ?\"\n"
    code << "  c << params[:cultivation_variant_id].to_i\n"
    code << "end\n"
    code << "c\n "
    code.c
  end

  list(conditions: productions_conditions) do |t|
    t.action :edit
    t.action :destroy, if: :destroyable?
    t.column :name, url: true
    t.column :activity, url: true
    t.column :campaign, url: true
    t.column :cultivation_variant, url: true
    t.column :state_label
  end

  before_action only: [:index] do
    if Activity.any?
      unless Campaign.any?
        notify :a_campaign_must_be_opened
        redirect_to controller: :campaigns, action: :new, redirect: request.fullpath
      end
    else
      notify :an_activity_must_be_defined
      redirect_to controller: :activities, action: :new, redirect: request.fullpath
    end
  end

  # List supports for one production
  list(:supports, model: :production_supports, conditions: { production_id: 'params[:id]'.c }, order: { created_at: :desc }, per_page: 10) do |t|
    t.action :new, url: { controller: :interventions, production_support_id: 'RECORD.id'.c, id: nil }
    t.column :name, url: true
    t.column :work_number, hidden: true
    t.column :irrigated, hidden: true
    t.column :population, through: :storage, datatype: :decimal, hidden: true
    t.column :unit_name, through: :storage, hidden: true
  end

  # List budgets for one production
  list(:budgets, conditions: { production_id: 'params[:id]'.c }, model: :production_budgets, order: { direction: :desc }) do |t|
    t.column :variant, url: true
    t.column :amount, currency: true
  end

  # List interventions for one production
  list(:interventions, conditions: { production_id: 'params[:id]'.c }, order: { created_at: :desc }, line_class: :status, per_page: 10) do |t|
    t.column :name, url: true
    t.status
    t.column :issue, url: true
    t.column :started_at
    t.column :stopped_at, hidden: true
    # t.column :provisional
  end
end
