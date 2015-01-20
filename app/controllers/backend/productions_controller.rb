# coding: utf-8
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

# -*- coding: utf-8 -*-
class Backend::ProductionsController < BackendController
  manage_restfully(t3e: {name: :name}, state: :draft)

  unroll

  # params:
  #   :q Text search
  #   :s State search
  #   :campaign_id
  #   :product_nature_id
  def self.productions_conditions
    code = ""
    code = search_conditions(productions: [:state], activities: [:name], product_nature_variants: [:name]) + " ||= []\n"
    code << "unless params[:s].blank?\n"
    code << "  unless params[:s] == 'all'\n"
    code << "    c[0] << \" AND state = ?\"\n"
    code << "    c << params[:s]\n"
    code << "  end\n"
    code << "end\n "
    code << "if params[:campaign_id].to_i > 0\n"
    code << "  c[0] << \" AND \#{Campaign.table_name}.id = ?\"\n"
    code << "  c << params[:campaign_id].to_i\n"
    code << "end\n"
    code << "if params[:variant_id].to_i > 0\n"
    code << "  c[0] << \" AND \#{ProductNatureVariant.table_name}.id = ?\"\n"
    code << "  c << params[:variant_id].to_i\n"
    code << "end\n"
    code << "c\n "
    return code.c
  end

  list(conditions: productions_conditions) do |t|
    t.column :name, url: true
    t.column :activity, url: true
    t.column :campaign, url: true
    t.column :variant, url: true
    t.column :state_label
    t.action :edit, if: :draft?
    # t.action :print, if: :validated?
    t.action :destroy, if: :destroyable?
  end

  # List supports for one production
  list(:supports, model: :production_supports, conditions: {production_id: 'params[:id]'.c}, order: {created_at: :desc}) do |t|
    t.column :name, url: true
    t.column :work_number, hidden: true
    t.column :irrigated, hidden: true
    t.column :population, through: :storage, datatype: :decimal, hidden: true
    t.column :unit_name, through: :storage, hidden: true
    t.column :started_at
    t.column :stopped_at
    t.action :new, url: {controller: :interventions, production_support_id: 'RECORD.id'.c, id: nil}
  end

  # List supports for one production
  list(:markers, conditions: {production_supports: {production_id: 'params[:id]'.c}}, model: :production_support_markers, order: {created_at: :desc}) do |t|
    t.column :name, through: :support, url: true
    t.column :indicator_name
    t.column :value
  end

  # List procedures for one production
  list(:interventions, conditions: {production_id: 'params[:id]'.c}, order: {created_at: :desc}, line_class: :status) do |t|
    t.column :name, url: true
    t.status
    t.column :issue, url: true
    t.column :started_at
    t.column :stopped_at, hidden: true
    # t.column :provisional
  end
  def indicator_measure
    storage = Product.find(params[:storage_id]) rescue nil
    variant = ProductNatureVariant.find(params[:variant_id]) rescue nil
    indicator = params[:indicator]
    unit = params[:unit]
    if storage && indicator && unit
      measure = storage.send(indicator).convert(unit)
      render json: {value: measure.to_f, unit: measure.unit}
    elsif variant
      indicators = variant.frozen_indicators.map(&:name)
      variant_nomen_item = Nomen::ProductNatureVariants.where(nature: variant.reference_name.to_sym).first
      unit = Nomen::Units[variant_nomen_item.unit_name]
      indicator = indicators.select{|i|i.to_s.end_with? unit.dimension.to_s}.first
      render json: {indicators: indicators, default: "#{indicator}-#{unit.name}"}
    else
      render status: :not_found, json: nil
    end
  end
end
