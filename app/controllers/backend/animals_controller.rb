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

class Backend::AnimalsController < Backend::MattersController
  # params:
  #   :q Text search
  #   :s State search
  #   :period Two Dates with _ separator
  #   :variant_id
  def self.list_conditions
    code = ''
    code = search_conditions(product_nature_variants: [:name]) + " ||= []\n"
    code << "unless (params[:period].blank? or params[:period].is_a? Symbol)\n"
    code << "  if params[:period] != 'all'\n"
    code << "    interval = params[:period].split('_')\n"
    code << "    first_date = interval.first\n"
    code << "    last_date = interval.last\n"
    code << "    c[0] << \" AND #{Animal.table_name}.born_at BETWEEN ? AND ?\"\n"
    code << "    c << first_date\n"
    code << "    c << last_date\n"
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
    t.column :sex
    t.status
    t.column :net_mass, datatype: :measure
    t.column :container, url: true
    # t.column :groups, url: true
    t.column :mother, url: true, hidden: true
    t.column :father, url: true, hidden: true
  end

  def load_animals
    @grouped_animals = []
    AnimalGroup.all.select(:id, :name).each do |group|
      @grouped_animals << { group: group, places_and_animals: group.members_with_places_at }
    end

    preference = current_user.preference("golumn.#{params[:golumn_id]}", {}.to_yaml)
    user_pref = YAML.load(preference.value)

    @sorted = []
    user_pref.deep_symbolize_keys!
    if user_pref[:positions].present?
      user_pref[:positions].each do |g|
        @grouped_animals.each do |h|
          @sorted << h if h[:group].id == g[:id]
        end
      end
    else
      @sorted = @grouped_animals
    end

    without_container = []
    Animal.of_enjoyer(Entity.of_company).select(:id, :name, :identification_number, :nature_id, :dead_at).each do |a|
      if a.container.nil? || a.memberships.length == 0
        without_container << { animal: a.to_json(methods: [:picture_path, :sex_text, :status]) }
      end
    end
    @sorted << { others: without_container } if without_container.any?
    render json: @sorted.to_json
  end

  def load_containers
    @containers = Product.select(:id, :name).of_expression('can store(animal)')
    render json: @containers
  end

  def load_workers
    @workers = Worker.select(:id, :name).all
    render json: @workers
  end

  def load_natures
    @natures = ProductNatureVariant.of_variety(:animal).select(:id, :name).all
    render json: @natures
  end

  def load_production_supports
    prod = {}
    arr = []
    ActivityProduction.where(storage: params[:group_id]).each do |p|
      prod[:id] = p.id
      prod[:name] = p.production.name + " (#{p.production.campaign.name})"
      arr << prod
    end
    render json: arr, status: 200
  end

  def change
    # params[:animals_id]
    # params[:container_id]
    # params[:group_id]
    # check animal exist
    if params[:animals_id]
      animals = params[:animals_id].split(',').collect do |animal_id|
        find_and_check(id: animal_id.to_i)
      end.compact
    end

    procedure_natures = []

    procedure_natures << :animal_moving if params[:container_id].present?
    procedure_natures << :animal_group_changing if params[:group_id].present?
    procedure_natures << :animal_evolution if params[:variant_id].present?

    Intervention.write(*procedure_natures, short_name: :animal_changing, started_at: params[:started_at], stopped_at: params[:stopped_at], production_support: ActivityProduction.find_by(id: params[:production_support_id])) do |i|
      i.cast :caregiver, Product.find_by(id: params[:worker_id]), role: 'animal_moving-doer', position: 1
      ah = nil
      ag = nil
      av = nil
      if procedure_natures.include?(:animal_moving)
        ah = i.cast :animal_housing, Product.find_by(id: params[:container_id]), role: ['animal_moving-target'], position: 2
      end
      if procedure_natures.include?(:animal_group_changing)
        ag = i.cast :herd, Product.find_by(id: params[:group_id]), role: ['animal_group_changing-target'], position: 3
      end
      if procedure_natures.include?(:animal_evolution)
        av = i.cast :new_animal_variant, ProductNatureVariant.find_by(id: params[:variant_id]), role: ['animal_evolution-variant'], position: 4, variant: true
      end
      animals.each_with_index do |a, index|
        ac = i.cast :animal, a, role: ['animal_moving-input', 'animal_group_changing-input', 'animal_evolution-target'], position: index + 5
        if procedure_natures.include?(:animal_moving)
          i.task :entering, product: ac, localizable: ah
        end
        if procedure_natures.include?(:animal_group_changing)
          i.task :group_inclusion, member: ac, group: ag
          # i.group_inclusion :animal, :herd
        end
        if procedure_natures.include?(:animal_evolution)
          i.task :variant_cast, product: ac, variant: av
          # i.variant_cast :animal, :new_animal_variant
        end
      end
    end

    render json: { result: 'ok' }
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

    respond_with @animals, methods: [:picture_path, :sex_text, :variety_text], include: [:initial_father, :initial_mother, :nature, :variant]
  end

  # Children list
  list(:children, model: :product_links, conditions: { linked_id: 'params[:id]'.c, nature: %w(father mother) }, order: { started_at: :desc }) do |t|
    t.column :name, through: :product, url: true
    t.column :born_at, through: :product, datatype: :datetime
    t.column :sex, through: :product
  end

  # Show one animal with params_id
  def show
    return unless @animal = find_and_check
    t3e @animal, nature: @animal.nature_name
    respond_with(@animal, methods: [:picture_path, :sex_text, :variety_text], include: [:father, :mother, :variant, :nature, :variety,
                                                                                        { readings: {} },
                                                                                        { intervention_casts: { include: :intervention } },
                                                                                        { memberships: { include: :group } },
                                                                                        { localizations: { include: :container } }])
  end

  def add_to_group
    return unless find_all
    if request.post?
      group = AnimalGroup.find(params[:group_id])
      activity_production = ActivityProduction.find(params[:activity_production_id])
      group.add_animals(@ids, at: params[:started_at], activity_production: activity_production)
      redirect_to params[:redirect] || backend_animal_group_url(group)
    else
      params[:started_at] ||= Time.zone.now
    end
  end

  def add_to_variant
    return unless find_all
    if request.post?
      variant = ProductNatureVariant.find(params[:variant_id])
      activity_production = ActivityProduction.find(params[:activity_production_id])
      variant.add_products(@ids, at: params[:started_at], activity_production: activity_production)
      redirect_to params[:redirect] || backend_product_nature_variant_url(variant)
    else
      params[:started_at] ||= Time.zone.now
    end
  end

  def add_to_container
    return unless find_all
    if request.post?
      container = Product.find(params[:container_id])
      activity_production = ActivityProduction.find(params[:activity_production_id])
      container.add_content_products(@ids, at: params[:started_at], activity_production: activity_production)
      redirect_to params[:redirect] || backend_product_url(container)
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
