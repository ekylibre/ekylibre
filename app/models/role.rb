# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: roles
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  name           :string(255)      not null
#  reference_name :string(255)
#  rights         :text
#  updated_at     :datetime         not null
#  updater_id     :integer
#


class Role < Ekylibre::Record::Base
  has_many :users
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :reference_name, allow_nil: true, maximum: 255
  validates_presence_of :name
  #]VALIDATORS]
  validates_uniqueness_of :name
  serialize :rights

  protect(on: :destroy) do
    self.users.any?
  end

  before_validation do
    self.rights = self.rights.to_hash if self.rights
  end

  # after_save(on: :update) do
  #   old_rights_array = []
  #   new_rights_array = []
  #   old_rights = Role.find_by_id(self.id).rights.to_s.split(" ")

  #   for right in old_rights
  #     old_rights_array << right.to_sym
  #   end
  #   for right in self.rights.split(/\s+/)
  #     new_rights_array << right.to_sym
  #   end

  #   added_rights = new_rights_array-old_rights_array
  #   deleted_rights = old_rights_array- new_rights_array

  #   for user in User.where(role_id: self.id, administrator: false)
  #     # puts user.rights.inspect
  #     user_rights_array = []
  #     for right in user.rights.split(/\s+/)
  #       user_rights_array << right.to_sym
  #     end

  #     user_rights_array.delete_if {|r| deleted_rights.include?(r) }
  #     for added_right in added_rights
  #       user_rights_array << added_right unless user_rights_array.include?(added_right)
  #     end

  #     user.rights = ""
  #       for right in user_rights_array
  #         user.rights += right.to_s+" "
  #       end
  #     user.save
  #     # puts user.rights.inspect
  #   end
  # end

  # def rights_array
  #   self.rights.to_s.split(/\s+/).collect{|x| x.to_sym}
  # end

  # def rights_array=(array)
  #   self.rights = array.select{|x| User.rights_list.include?(x.to_sym)}.join(" ")
  # end

  # def diff_more
  #   ''
  # end

  # def diff_less
  #   ''
  # end

  # Load a role from nomenclature
  def self.import_from_nomenclature(reference_name, force = false)
    unless item = Nomen::Roles[reference_name]
      raise ArgumentError, "The role #{reference_name.inspect} is not known"
    end

    # parse rights
    rights = item.accesses.inject({}) do |hash, right|
      array = right.to_s.split("-")
      array.insert(0, "all") if array.size < 3
      array << "all" if array.size < 3
      resource, action = array.second, array.third
      unless Nomen::EnterpriseResources[resource]
        raise resource.inspect
      end
      action = Nomen::EnterpriseResources[resource].accesses if action == "all"
      hash[resource] ||= []
      hash[resource] += [action].flatten.map(&:to_s)
      hash
    end

    # build attributes
    attributes = {
      :name => item.human_name,
      :reference_name => item.name,
      :rights => rights
    }

    # create role
    role = self.create!(attributes)

    return role
  end

end
