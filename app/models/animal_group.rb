# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: products
#
#  activity_production_id       :integer
#  address_id                   :integer
#  birth_date_completeness      :string
#  birth_farm_number            :string
#  born_at                      :datetime
#  category_id                  :integer          not null
#  codes                        :jsonb
#  country                      :string
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  custom_fields                :jsonb
#  dead_at                      :datetime
#  default_storage_id           :integer
#  derivative_of                :string
#  description                  :text
#  end_of_life_reason           :string
#  father_country               :string
#  father_identification_number :string
#  father_variety               :string
#  filiation_status             :string
#  first_calving_on             :datetime
#  fixed_asset_id               :integer
#  id                           :integer          not null, primary key
#  identification_number        :string
#  initial_born_at              :datetime
#  initial_container_id         :integer
#  initial_dead_at              :datetime
#  initial_enjoyer_id           :integer
#  initial_father_id            :integer
#  initial_geolocation          :geometry({:srid=>4326, :type=>"st_point"})
#  initial_mother_id            :integer
#  initial_movement_id          :integer
#  initial_owner_id             :integer
#  initial_population           :decimal(19, 4)   default(0.0)
#  initial_shape                :geometry({:srid=>4326, :type=>"multi_polygon"})
#  lock_version                 :integer          default(0), not null
#  member_variant_id            :integer
#  mother_country               :string
#  mother_identification_number :string
#  mother_variety               :string
#  name                         :string           not null
#  nature_id                    :integer          not null
#  number                       :string           not null
#  origin_country               :string
#  origin_identification_number :string
#  originator_id                :integer
#  parent_id                    :integer
#  person_id                    :integer
#  picture_content_type         :string
#  picture_file_name            :string
#  picture_file_size            :integer
#  picture_updated_at           :datetime
#  reading_cache                :jsonb            default("{}")
#  team_id                      :integer
#  tracking_id                  :integer
#  type                         :string
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  uuid                         :uuid
#  variant_id                   :integer          not null
#  variety                      :string           not null
#  work_number                  :string
#

class AnimalGroup < ProductGroup
  refers_to :variety, scope: :animal_group
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  # ]VALIDATORS]

  # Add a member to the group
  def add(member, options = {})
    unless member.is_a?(Animal)
      raise ArgumentError, "Animal expected, got #{member.class}:#{member.inspect}"
    end
    super(member, options)
  end

  # Remove a member from the group
  def remove(member, options = {})
    unless member.is_a?(Animal)
      raise ArgumentError, "Animal expected, got #{member.class}:#{member.inspect}"
    end
    super(member, options)
  end

  # Returns members of the group at a given time (or now by default)
  def members_at(viewed_at = nil)
    Animal.members_of(self, viewed_at || Time.zone.now)
  end

  def places(viewed_at = nil)
    animals = members_at(viewed_at || Time.zone.now)
    animals.collect(&:container).uniq.compact
  end

  # DOC
  def members_with_places_at(viewed_at = nil)
    places_and_animals = []
    all_places = places(viewed_at)
    all_places.each do |place|
      places_and_animals.push(place: Product.select(:id, :name).find(place.id), animals: Animal.select(:id, :name, :identification_number, :nature_id, :dead_at).members_of(self, viewed_at || Time.zone.now).members_of_place(place, viewed_at || Time.zone.now).to_json(methods: %i[picture_path sex_text status]))
    end
    places_and_animals
  end

  def daily_nitrogen_production(viewed_at = nil)
    quantity = []
    for animal in members_at(viewed_at)
      quantity << animal.daily_nitrogen_production.to_d
    end
    quantity.compact.sum.in_kilogram_per_day
  end

  def add_animals(animals, options = {})
    procedure_natures = []
    procedure_natures << :animal_group_changing
    procedure_natures << :animal_moving if options[:container_id].present?
    procedure_natures << :animal_evolution if options[:variant_id].present?

    Intervention.write(*procedure_natures, short_name: :animal_changing, started_at: options[:started_at], stopped_at: options[:stopped_at], production_support: ActivityProduction.find_by(id: options[:production_support_id])) do |i|
      i.cast :caregiver, Product.find_by(id: options[:worker_id]), role: 'animal_moving-doer', position: 1 if options[:worker_id]
      ah = nil
      ag = nil
      av = nil
      if procedure_natures.include?(:animal_moving)
        ah = i.cast :animal_housing, Product.find_by(id: options[:container_id]), role: ['animal_moving-target'], position: 2
      end
      if procedure_natures.include?(:animal_group_changing)
        ag = i.cast :herd, self, role: ['animal_group_changing-target'], position: 3
      end
      if procedure_natures.include?(:animal_evolution)
        av = i.cast :new_animal_variant, ProductNatureVariant.find_by(id: options[:variant_id]), role: ['animal_evolution-variant'], position: 4, variant: true
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
  end
end
