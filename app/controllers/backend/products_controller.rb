# == License
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
module Backend
  class ProductsController < Backend::BaseController
    manage_restfully t3e: { nature: :nature_name }, subclass_inheritance: true, multipart: true
    manage_restfully_picture

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    before_action :check_variant_availability, only: :new
    before_action :clean_attachments, only: [:update]

    unroll :name, :number, :work_number, :identification_number, container: :name # , 'population:!', 'unit_name:!'

    # params:
    #   :q Text search
    #   :working_set
    def self.list_conditions
      code = search_conditions(products: %i[name work_number number description uuid], product_nature_variants: [:name]) + " ||= []\n"
      code << "unless params[:working_set].blank?\n"
      code << "  item = Nomen::WorkingSet.find(params[:working_set])\n"
      code << "  c[0] << \" AND products.nature_id IN (SELECT id FROM product_natures WHERE \#{WorkingSet.to_sql(item.expression)})\"\n"
      code << "end\n"

      # State
      code << "if params[:s] == 'available'\n"
      code << "  c[0] << ' AND #{Product.table_name}.dead_at IS NULL'\n"
      code << "elsif params[:s] == 'consume'\n"
      code << "  c[0] << ' AND #{Product.table_name}.dead_at IS NOT NULL'\n"
      code << "end\n"

      # Label
      code << "if params[:label_id].to_i > 0\n"
      code << "  c[0] << ' AND #{Product.table_name}.id IN (SELECT product_id FROM product_labellings WHERE label_id IN (?))'\n"
      code << "  c << params[:label_id].to_i\n"
      code << "end\n"

      # Period
      code << "if params[:period].to_s != 'all'\n"
      code << "  started_on = params[:started_on]\n"
      code << "  stopped_on = params[:stopped_on]\n"
      code << "  c[0] << ' AND #{Product.table_name}.born_at::DATE BETWEEN ? AND ?'\n"
      code << "  c << started_on\n"
      code << "  c << stopped_on\n"
      code << "  if params[:s] == 'consume'\n"
      code << "    c[0] << ' AND #{Product.table_name}.dead_at::DATE BETWEEN ? AND ?'\n"
      code << "    c << started_on\n"
      code << "    c << stopped_on\n"
      code << "  end\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :work_number
      t.column :name, url: true
      t.column :variant, url: true
      t.column :variety
      t.column :population
      t.column :unit_name
      t.column :container, url: true
      t.column :description
      t.column :derivative_of
    end

    # Lists contained products of the current product
    list(:contained_products, model: :product_localizations, conditions: { container_id: 'params[:id]'.c, stopped_at: nil }, order: { started_at: :desc }) do |t|
      t.column :product, url: true
      t.column :nature, hidden: true
      t.column :intervention, url: true
      t.column :started_at
      t.column :stopped_at, hidden: true
    end

    # Lists carried linkages of the current product
    list(:carried_linkages, model: :product_linkages, conditions: { carrier_id: 'params[:id]'.c }, order: { started_at: :desc }) do |t|
      t.column :carried, url: true
      t.column :point
      t.column :nature
      t.column :intervention, url: true
      t.column :started_at, through: :intervention, datatype: :datetime
      t.column :stopped_at, through: :intervention, datatype: :datetime
    end

    # Lists carrier linkages of the current product
    list(:carrier_linkages, model: :product_linkages, conditions: { carried_id: 'params[:id]'.c }, order: { started_at: :desc }) do |t|
      t.column :carrier, url: true
      t.column :point
      t.column :nature
      t.column :intervention, url: true
      t.column :started_at
      t.column :stopped_at
    end

    # Lists fixed_assets of a product
    list(:fixed_assets, conditions: { product_id: 'params[:id]'.c }, order: { started_on: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :name, url: true
      t.column :depreciable_amount, currency: true
      t.column :net_book_value, currency: true
      t.column :started_on
      t.column :stopped_on
    end

    # Lists groups of the current product
    list(:inspections, conditions: { product_id: 'params[:id]'.c }, order: { sampled_at: :desc }) do |t|
      t.column :number, url: true
      t.column :position
      t.column :sampled_at
      # t.column :item_count
      # t.column :net_mass, datatype: :measure
    end

    # Lists groups of the current product
    list(:groups, model: :product_memberships, conditions: { member_id: 'params[:id]'.c }, order: { started_at: :desc }) do |t|
      t.column :group, url: true
      t.column :intervention, url: true
      t.column :started_at
      t.column :stopped_at
    end

    # Lists issues of the current product
    list(:issues, conditions: { target_id: 'params[:id]'.c, target_type: 'Product' }, order: { observed_at: :desc }) do |t|
      t.action :new, url: { controller: :interventions, issue_id: 'RECORD.id'.c, id: nil }
      t.column :nature, url: true
      t.column :observed_at
      t.status
    end

    # Lists intervention product parameters of the current product
    list(:intervention_product_parameters, model: :intervention_parameters, conditions: { interventions: { nature: :record }, product_id: 'params[:id]'.c }, order: 'interventions.started_at DESC') do |t|
      t.column :intervention, url: true
      # t.column :roles, hidden: true
      t.column :reference, label_method: :name, sort: :reference_name
      t.column :started_at, through: :intervention, datatype: :datetime
      t.column :stopped_at, through: :intervention, datatype: :datetime, hidden: true
      t.column :human_activities_names, through: :intervention
      t.column :actions, label_method: :human_actions_names, through: :intervention
      # t.column :intervention_activities
      t.column :human_working_duration, through: :intervention
      t.column :human_working_zone_area, through: :intervention
    end

    # Lists members of the current product
    list(:members, model: :product_memberships, conditions: { group_id: 'params[:id]'.c }, order: :started_at) do |t|
      t.column :member, url: true
      t.column :intervention, url: true
      t.column :started_at
      t.column :stopped_at
    end

    # Lists parcel items of the current product
    list(:reception_items, model: :parcel_item_storings, joins: :parcel_item, conditions: { product_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :reception, label_method: :reception_number, url: { controller: :receptions, id: 'RECORD.parcel_item.parcel_id'.c }
      t.column :nature, label_method: :reception_nature
      t.column :given_at, label_method: :reception_given_at, datatype: :datetime
      t.column :population, label_method: :quantity
      t.column :product_identification_number, through: :parcel_item
    end

    # Lists parcel items of the current product
    list(:shipment_items, model: :shipment_items, conditions: { product_id: 'params[:id]'.c, parcels: { nature: :outgoing } }, order: { created_at: :desc }) do |t|
      t.column :shipment, url: { controller: :shipments }
      t.column :nature, through: :shipment
      t.column :given_at, through: :shipment, datatype: :datetime
      t.column :population
      t.column :product_identification_number
    end

    # Lists localizations of the current product
    list(:places, model: :product_localizations, conditions: { product_id: 'params[:id]'.c }, order: { started_at: :desc }) do |t|
      t.action :edit
      t.column :nature
      t.column :container, url: true
      t.column :intervention, url: true
      t.column :started_at
      t.column :stopped_at
    end

    # Lists readings of the current product
    list(:readings, model: :product_readings, conditions: { product_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :indicator_name
      t.column :read_at
      t.column :value
    end

    # Lists readings of the current product
    list(:trackings, conditions: { product_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :active
      t.column :name, url: true
      t.column :created_at
      t.column :description
      t.column :serial
      t.column :producer, hidden: true
    end

    # Returns value of an indicator
    def take
      return unless @product = find_and_check
      indicator = Nomen::Indicator.find(params[:indicator])
      unless indicator
        head :unprocessable_entity
        return
      end

      value = @product.get(indicator)
      if indicator.datatype == :measure
        if unit = Nomen::Unit[params[:unit]]
          value = value.convert(unit)
        end
        value = { unit: value.unit, value: value.to_d.round(4) }
      elsif %i[integer decimal].include? indicator.datatype
        value = { value: value.to_d.round(4) }
      end
      render json: value
    end

    def edit_many
      activity = Activity.find_by(id: params[:activity_id]) if params[:activity_id]
      targetable_products = Product.where(type: %w[Animal])

      @targets = activity.present? ? targetable_products.where(activity_production_id: activity.productions.pluck(:id).push(nil)) : targetable_products
      @targets = @targets.order(:activity_production_id)

      @activity_productions = ActivityProduction.all
      @activity_productions = @activity_productions.of_activity(activity) if activity
    end

    def update_many
      activity = Activity.find_by(id: params[:activity_id]) if params[:activity_id]
      @activity_productions = ActivityProduction.all
      @activity_productions = @activity_productions.of_activity(activity) if activity
      saved = true
      @targets = if params[:target_distributions]
                   params[:target_distributions].map do |_id, target_distribution|
                     product = Product.find(target_distribution[:target_id])
                     activity_production_id = target_distribution[:activity_production_id]
                     if activity_production_id.empty? && product.activity_production_id.present?
                       saved = false unless product.update(activity_production_id: nil)
                     elsif !activity_production_id.empty? && product.activity_production_id != activity_production_id.to_i
                       saved = false unless product.update(activity_production_id: activity_production_id)
                     end
                     product
                   end.sort { |a, b| a.activity_production_id <=> b.activity_production_id || (b.activity_production_id && 1) || -1 }
                 else
                   []
                 end
      if saved
        redirect_to params[:redirect] || backend_activities_path
      else
        render 'edit_many'
      end
    end

    protected

    def check_variant_availability
      unless ProductNatureVariant.of_variety(controller_name.to_s.underscore.singularize).any?
        redirect_to new_backend_product_nature_path
        false
      end
    end

    def clean_attachments
      if permitted_params.include?('attachments_attributes')
        permitted_params['attachments_attributes'].each do |k, v|
          permitted_params['attachments_attributes'].delete(k) if v.key?('id') && !Attachment.exists?(v['id'])
        end
      end
    end
  end
end
