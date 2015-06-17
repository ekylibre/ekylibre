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
  def self.animals_conditions
    code = ""
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
    return code.c
  end

  list(conditions: animals_conditions, joins: :variants) do |t|
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :new,     on: :none
    t.action :add_to_group, on: :both
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

    user_pref.deep_symbolize_keys!()

    if user_pref[:positions].present?

      user_pref[:positions].each do |g|

        @grouped_animals.each do |h|

          if h[:group].id == g[:id]
            @sorted << h
          end
        end
      end

    else
      @sorted = @grouped_animals

    end


    without_container = []

    Animal.select(:id, :name, :identification_number, :nature_id, :dead_at).each do |a|
      if a.container.nil? or a.memberships.length == 0
        without_container << { animal: a.to_json(:methods => [:picture_path, :sex_text, :status]) }
      end
    end

    @sorted << {others: without_container}


    render :json => @sorted.to_json()

  end

  def load_containers

    @containers = Product.select(:id,:name).of_expression('can store(bos_taurus)')

    render :json => @containers
  end

  def load_workers

    @workers = Worker.select(:id,:name).all

    render :json => @workers
  end

  def load_natures

    @natures = ProductNatureVariant.of_variety(:animal).select(:id,:name).all

    render :json => @natures
  end




  def change

    # params[:animals_id]
    # params[:container_id]
    # params[:group_id]

    #check animal exist
    if params[:animals_id]
      for animal in animals = params[:animals_id].split(',')
        return unless find_and_check(id: animal)
      end
    end

    procedure_natures = []

    if params[:container_id].present?
      procedure_natures << :animal_moving
    end
    if params[:group_id].present?
      procedure_natures << :animal_group_changing
    end
    if params[:variant_id].present?
      procedure_natures << :animal_evolution
    end

    Intervention.write(*procedure_natures, short_name: :animal_changing, started_at: params[:started_at], stopped_at: params[:stopped_at], production_support: ProductionSupport.find_by(id: params[:production_support_id])) do |i|
      i.cast :caregiver, role: 'animal_moving-doer'
      animals.each do |a|
        i.cast :animal, a, role: ['animal_moving-target', 'animal_group_changing-target','animal_evolution-target']
        if procedure_natures.include?(:animal_moving)
          i.cast :localizable, params[:container_id], role: ['animal_moving-localizable']
          i.movement :animal, :localizable, :caregiver
        end
        if procedure_natures.include?(:animal_group_changing)
          i.cast :group, params[:group_id], role: ['animal_group_changing-includer']
          i.group_inclusion :animal, :group
        end
        if procedure_natures.include?(:animal_evolution)
          i.cast :nature, params[:variant_id], role: ['animal_evolution-variant']
          i.evolution :animal, :nature
        end
      end
    end

    render json: {result: 'ok'}
  end


  def add_group
    if params[:name]
      #Insert a group
    end
    render :json => {id: 222, name: params[:name]}, :status => :ok
  end

  # Show a list of animal groups
  def index
    @animals = Animal.all
    # passing a parameter to Jasper for company full name and id
    @entity_of_company_full_name = Entity.of_company.full_name
    @entity_of_company_id = Entity.of_company.id

    respond_with @animals, :methods => [:picture_path, :sex_text, :variety_text], :include => [:initial_father, :initial_mother, :nature ,:variant]
  end

  # Children list
  list(:children, model: :product_links, conditions: {linked_id: 'params[:id]'.c, nature: %w(father mother)}, order: {started_at: :desc}) do |t|
    t.column :name, through: :product, url: true
    t.column :born_at, through: :product, datatype: :datetime
    t.column :sex, through: :product
  end

  # Show one animal with params_id
  def show
    return unless @animal = find_and_check
    t3e @animal, nature: @animal.nature_name
    respond_with(@animal, :methods => [:picture_path, :sex_text, :variety_text], :include => [:father, :mother, :variant, :nature, :variety,
                                                                                              {:readings => {}},
                                                                                              {:intervention_casts => {:include => :intervention}},
                                                                                              {:memberships => {:include => :group}},
                                                                                              {:localizations => {:include => :container}}])

  end

  def add_to_group
    for id in ids = params[:id].split(',')
      return unless find_and_check(id: id)
    end
    if request.post?
      if group = AnimalGroup.find(params[:group_id])  and production = Production.find_by(id: params[:production_id]) and params[:started_at]
        group.add_animals(ids, at: params[:started_at], production: production, production_support: production.supports.find_by(id: params[:production_support_id]))
        redirect_to params[:redirect] || backend_animal_group_url(group)
      else
        # redirect to a form to select group / started_at / stopped_at
      end
    else
      params[:started_at] ||= Time.now
    end
  end

end
