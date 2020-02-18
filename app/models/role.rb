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
# == Table: roles
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  name           :string           not null
#  reference_name :string
#  rights         :text
#  updated_at     :datetime         not null
#  updater_id     :integer
#

class Role < Ekylibre::Record::Base
  include Rightable
  has_many :users, dependent: :restrict_with_exception
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :name, presence: true, length: { maximum: 500 }
  validates :reference_name, length: { maximum: 500 }, allow_blank: true
  validates :rights, length: { maximum: 500_000 }, allow_blank: true
  # ]VALIDATORS]
  validates :name, uniqueness: true

  protect(on: :destroy) do
    users.any?
  end

  # Impact changes and only changes on users
  before_update do
    new_rights_array = rights_array
    old_rights_array = old_record.rights_array
    granted_rights = new_rights_array - old_rights_array
    revoked_rights = old_rights_array - new_rights_array

    users.find_each do |user|
      user.rights ||= {}

      # Remove revoked rights
      revoked_rights.each do |right|
        resource, action = right.split('-')
        if user.rights[resource]
          user.rights[resource].delete(action)
          user.rights.delete(resource) if user.rights[resource].blank?
        end
      end

      # Add granted rights
      granted_rights.each do |right|
        resource, action = right.split('-')
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
  def self.import_from_nomenclature(reference_name, _force = false)
    unless item = Nomen::Role[reference_name]
      raise ArgumentError, "The role #{reference_name.inspect} is not known"
    end

    # parse rights
    rights = item.accesses.each_with_object({}) do |right, hash|
      array = right.to_s.split('-')
      array.insert(0, 'all') if array.size < 3
      array << 'all' if array.size < 3
      resource = array.second
      action = array.third
      action = Ekylibre::Access.interactions_of(resource) if action == 'all'
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
    role = create!(attributes)

    role
  end

  def self.import_from_lexicon(reference_name, _force = false)
    unless item = UserRole.find_by_reference_name(reference_name)
      raise ArgumentError, "The role #{reference_name.inspect} is not known"
    end

    rights = item.accesses.each_with_object({}) do |right, hash|
      array = right.to_s.split('-')
      array.insert(0, 'all') if array.size < 3
      array << 'all' if array.size < 3
      resource = array.second
      action = array.third
      action = Ekylibre::Access.interactions_of(resource) if action == 'all'
      hash[resource] ||= []
      hash[resource] += [action].flatten.map(&:to_s)
      hash
    end

    create!(name: item.name[I18n.locale.to_s] || item.reference_name.humanize, reference_name: item.reference_name, rights: rights)
  end
end
