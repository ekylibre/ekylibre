# = Informations
#
# == License
#
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: products
#
#  address_id            :integer
#  born_at               :datetime
#  category_id           :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  dead_at               :datetime
#  default_storage_id    :integer
#  derivative_of         :string
#  description           :text
#  extjuncted            :boolean          default(FALSE), not null
#  fixed_asset_id        :integer
#  id                    :integer          not null, primary key
#  identification_number :string
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_geolocation   :geometry({:srid=>4326, :type=>"point"})
#  initial_mother_id     :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :geometry({:srid=>4326, :type=>"geometry"})
#  lock_version          :integer          default(0), not null
#  name                  :string           not null
#  nature_id             :integer          not null
#  number                :string           not null
#  parent_id             :integer
#  person_id             :integer
#  picture_content_type  :string
#  picture_file_name     :string
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  tracking_id           :integer
#  type                  :string
#  updated_at            :datetime         not null
#  updater_id            :integer
#  variant_id            :integer          not null
#  variety               :string           not null
#  work_number           :string
#


class AnimalGroup < ProductGroup
  enumerize :variety, in: Nomen::Varieties.all(:animal_group), predicates: {prefix: true}
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]

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
    Animal.members_of(self, viewed_at || Time.now)
  end


  def places(viewed_at = nil)
    animals = self.members_at(viewed_at || Time.now)
    # containers = []
    # byebug
    # animals.each do |animal|
    #   containers << animal.container
    # end
    # return containers.uniq
    return animals.collect{|a| a.container}.uniq
  end

  def members_with_places_at(viewed_at = nil)
    places_and_animals = []
    all_places = self.places(viewed_at)
    all_places.each do |place|

      places_and_animals.push({:place => BuildingDivision.select(:id,:name).find(place.id),:animals => Animal.select(:id, :name, :identification_number, :nature_id, :dead_at).members_of(self,viewed_at || Time.now).members_of_place(place,viewed_at || Time.now).to_json(:methods => [:picture_path, :sex_text, :status])})

    end
    places_and_animals
  end

  def daily_nitrogen_production(viewed_at = nil)
    quantity = []
    for animal in self.members_at(viewed_at)
      quantity << animal.daily_nitrogen_production.to_d
    end
    return quantity.compact.sum.in_kilogram_per_day
  end


  def add_animals(animals, options = {})
    Intervention.write(:group_inclusion, options) do |i|
      i.cast :group, self, as: 'group_inclusion-target'
      animals.each do |a|
        animal = (a.is_a?(Animal) ? a : Animal.find(a))
        member = i.cast :member, animal, as: 'group_inclusion-includer'
        i.group_inclusion :group, member
      end
    end
  end

end
