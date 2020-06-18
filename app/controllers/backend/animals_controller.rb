# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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
  class AnimalsController < Backend::MattersController
    respond_to :json
    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    def self.list_conditions
      code = ''
      code = search_conditions(products: %i[name work_number number description uuid], product_nature_variants: [:name]) + " ||= []\n"
      code << "unless (params[:period].blank? or params[:period].is_a? Symbol)\n"
      code << "  if params[:period] != 'all'\n"
      code << "    if params[:period] == 'interval' \n"
      code << "      started_on = params[:started_on] \n"
      code << "      stopped_on = params[:stopped_on] \n"
      code << "    else \n"
      code << "      interval = params[:period].split('_')\n"
      code << "      started_on = interval.first\n"
      code << "      stopped_on = interval.last\n"
      code << "    end \n"
      code << "    c[0] << \" AND #{Animal.table_name}.born_at::DATE BETWEEN ? AND ?\"\n"
      code << "    c << started_on\n"
      code << "    c << stopped_on\n"
      code << "  end\n "
      code << "end\n "
      # code << "unless (params[:s].blank? or params[:s].is_a? Symbol)\n"
      # code << "  if params[:s] != 'all'\n"
      # code << "    if params[:s] == 'healthy'\n"
      # code << "      c[0] << \" AND #{ProductReading.table_name}.product_id=#{Animal.table_name}.id AND #{ProductReading.table_name}.indicator_name='healthy' AND #{ProductReading.table_name}.boolean_value=true\"\n"
      # code << "    end\n "
      # code << "    if params[:s] == 'illness'\n"
      # code << "      c[0] << \" AND #{ProductReading.table_name}.product_id=#{Animal.table_name}.id AND #{ProductReading.table_name}.indicator_name='healthy' AND #{ProductReading.table_name}.boolean_value=false\"\n"
      # code << "    end\n "
      # code << "  end\n "
      # code << "end\n "
      code << "  if params[:variant_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{ProductNatureVariant.table_name}.id = ?\"\n"
      code << "    c << params[:variant_id].to_i\n"
      code << "  end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions, joins: :variants) do |t|
      t.action :add_to_group, on: :both
      # t.action :add_to_variant, on: :both
      # t.action :add_to_container, on: :both
      # t.action :new_issue,        on: :both, url: {action: :new, controller: :issues}
      # t.action :new_intervention, on: :both, url: {action: :new, controller: :interventions}
      t.action :edit
      t.action :destroy
      t.column :work_number, url: true
      t.column :name, url: true
      t.column :born_at
      t.column :sex, label_method: :sex_text, label: :sex
      t.status
      t.column :state, hidden: true
      t.column :net_mass, datatype: :measure
      t.column :container, url: true
      # t.column :groups, url: true
      t.column :mother, url: true, hidden: true
      t.column :father, url: true, hidden: true
    end

    def load_animals
      @read_at = params[:scope] == 'now' ? { at: Time.zone.now } : @read_at = { at: false }

      @animal_groups = AnimalGroup.availables(@read_at).order(:name)
      @animals = Animal.availables(@read_at).order(:name)
    end

    def change
      # params[:animals_id]
      # params[:container]
      # params[:group]
      # params[:worker]
      # params[:variant]
      # params[:started_at]
      # params[:stopped_at]
      # check animal exist
      if params[:animals_id]
        animals = params[:animals_id].split(',').collect do |animal_id|
          find_and_check(id: animal_id.to_i)
        end.compact
      end

      errors = []

      begin
        started_at = Date.parse(params[:started_at])
      rescue StandardError => e
        errors = notify_error(e.message.parameterize('_').to_sym.tn, type: :started_at)
      end

      begin
        stopped_at = Date.parse(params[:stopped_at])
      rescue StandardError => e
        errors = notify_error(e.message.parameterize('_').to_sym.tn, type: :stopped_at)
      end

      group = AnimalGroup.find_by(id: params[:group])

      if group.nil? || params[:group].blank?
        errors = notify_error(:unavailable_resource, type: AnimalGroup.model_name.human, id: params[:group].to_s)
      end

      container = Product.find_by(id: params[:container])

      if container.nil? || params[:container].blank?
        errors = notify_error(:unavailable_resource, type: Product.human_attribute_name(:container), id: params[:container].to_s)
      end

      procedure_natures = []

      # massive assignment
      procedure_natures << :animal_moving if params[:container].present?
      procedure_natures << :animal_evolution if params[:variant].present?

      procedure_natures << :animal_group_changing if params[:group].present?

      if errors.any?
        render json: { errors: errors }, status: :unprocessable_entity
      else
        render json: { result: 'ok' }, status: :created
      end
    end

    # Insert a group
    def add_group
      if params[:name] && variant = ProductNatureVariant.find_by(id: params[:variant_id])
        group = ProductGroup.create!(name: params[:name], variant: variant)
        render json: { id: group.id, name: group.name }, status: :ok
      else
        render json: 'Cannot save group. Parameters are missing.', status: :unprocessable_entity
      end
    end

    # Show a list of animal groups
    def index
      @animals = Animal.all
      # passing a parameter to Jasper for company full name and id
      @entity_of_company_full_name = Entity.of_company.full_name
      @entity_of_company_id = Entity.of_company.id

      respond_with @animals, methods: %i[picture_path sex_text variety_text], include: %i[initial_father initial_mother nature variant]
    end

    # Children list
    list(:children, model: :product_links, conditions: { linked_id: 'params[:id]'.c, nature: %w[father mother] }, order: { started_at: :desc }) do |t|
      t.column :name, through: :product, url: true
      t.column :born_at, through: :product, datatype: :datetime
      t.column :sex, through: :product, label_method: :sex_text, label: :sex
    end

    # Show one animal with params_id
    def show
      return unless @animal = find_and_check
      # TODO: remove it. On animal show dialog (Golumn), add issue. Break redirect on submit.
      params.delete('dialog')

      t3e @animal, nature: @animal.nature_name
      respond_with(@animal, methods: %i[picture_path sex_text variety_text], include: [:father, :mother, :variant, :nature, :variety,
                                                                                       { readings: {} },
                                                                                       { intervention_product_parameters: { include: :intervention } },
                                                                                       { memberships: { include: :group } },
                                                                                       { localizations: { include: :container } }])
    end

    def keep
      return head :unprocessable_entity unless params[:id].nil? || (params[:id] && find_all)

      begin
        current_user.prefer! 'products_for_intervention', params[:id], :string
      end

      render json: { id: 'products_for_intervention' }
    end

    def matching_interventions
      return head :unprocessable_entity unless params[:id].nil? || (params[:id] && find_all)
      varieties = Animal.where(id: @ids).pluck(:variety).uniq if @ids

      respond_to do |format|
        format.js { render partial: 'matching_interventions', locals: { varieties: varieties } }
      end
    end

    def add_to_group
      return unless find_all
      targets = @ids.collect do |id|
        { product_id: id, reference_name: :animal }
      end
      parameters = {
        procedure_name: :animal_group_changing,
        intervention: {
          targets_attributes: targets
        }
      }
      redirect_to new_backend_intervention_path(parameters)
    end

    def add_to_variant
      return unless find_all
      if request.post?
        variant = ProductNatureVariant.find(params[:variant_id])
        activity_production = ActivityProduction.find(params[:activity_production_id])
        # TODO: fix intervention
        variant.add_products(@ids, at: params[:started_at], activity_production: activity_production)
        redirect_to params[:redirect] || backend_product_nature_variant_path(variant)
      else
        params[:started_at] ||= Time.zone.now
      end
    end

    def add_to_container
      return unless find_all
      if request.post?
        container = Product.find(params[:container_id])
        activity_production = ActivityProduction.find(params[:activity_production_id])
        # TODO: fix intervention
        container.add_content_products(@ids, at: params[:started_at], activity_production: activity_production)
        redirect_to params[:redirect] || backend_product_path(container)
      else
        params[:started_at] ||= Time.zone.now
      end
    end

    protected

    def find_all
      @ids = []
      params[:id].split(',').each do |id|
        return false unless find_and_check(id: id)
        @ids << id
      end
    end
  end
end
