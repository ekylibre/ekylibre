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
  include Rightable
  has_many :users
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :reference_name, allow_nil: true, maximum: 255
  validates_presence_of :name
  #]VALIDATORS]
  validates_uniqueness_of :name

  protect(on: :destroy) do
    self.users.any?
  end

  # Impact changes and only changes on users
  before_update do
    new_rights_array = self.rights_array
    old_rights_array = old_record.rights_array
    granted_rights = new_rights_array - old_rights_array
    revoked_rights = old_rights_array - new_rights_array

    self.users.find_each do |user|
      # Remove revoked rights
      revoked_rights.each do |right|
        resource, action = right.split("-")
        if user.rights[resource]
          user.rights[resource].delete(action)
          user.rights.delete(resource) if user.rights[resource].blank?
        end
      end

      # Add granted rights
      granted_rights.each do |right|
        resource, action = right.split("-")
        user.rights[resource] = [] unless user.rights[resource].is_a?(Array)
        unless user.rights[resource].include?(action)
          user.rights[resource] << action
        end
      end

      # Save
      user.save!
    end
  end

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
        raise StandardError, "Unknown enterprise resource: #{resource.inspect}"
      end
      action = Nomen::EnterpriseResources[resource].accesses if action == "all"
      hash[resource] ||= []
      hash[resource] += [action].flatten.map(&:to_s)
      hash
    end

    # build attributes
    attributes = {
      name: item.human_name,
      reference_name: item.name,
      rights: rights
    }

    # create role
    role = self.create!(attributes)

    return role
  end

end
