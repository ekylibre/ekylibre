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
# == Table: versions
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  creator_name :string
#  event        :string           not null
#  id           :integer          not null, primary key
#  item_changes :text
#  item_id      :integer
#  item_object  :text
#  item_type    :string
#

class Version < ActiveRecord::Base
  extend Enumerize
  cattr_accessor :current_user
  belongs_to :creator, class_name: 'User'
  belongs_to :item, polymorphic: true
  enumerize :event, in: %i[create update destroy], predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  # ]VALIDATORS]

  scope :creations,    -> { where(event: 'create') }
  scope :updates,      -> { where(event: 'update') }
  scope :destructions, -> { where(event: 'destroy') }
  scope :after,   ->(at) { where('created_at > ?', at) }
  scope :before,  ->(at) { where('created_at < ?', at) }
  scope :between, lambda { |started_at, stopped_at|
    where(created_at: started_at..stopped_at).order(created_at: :desc)
  }

  serialize :item_object,  HashWithIndifferentAccess
  serialize :item_changes, HashWithIndifferentAccess

  before_save do
    self.item_type = item.class.base_class.name if item
    self.created_at ||= Time.zone.now
    self.creator ||= Version.current_user
    self.creator_name ||= self.creator.name if self.creator
    self.item_object = item.version_object
    if previous
      self.item_changes = self.class.diff(previous.item_object, item_object)
    end
  end

  before_update do
    raise StandardError, 'Cannot update a past version'
  end

  before_destroy do
    raise StandardError, 'Cannot destroy a past version'
  end

  def self.diff(a, b)
    # return a.diff(b)
    a.dup
     .delete_if { |k, v| b[k] == v }
     .merge!(b.dup.delete_if { |k, _v| a.key?(k) })
  end

  def siblings
    item.versions
  end

  def following
    @following ||= siblings.after(self.created_at).first
  end

  def previous
    @previous ||= siblings.before(self.created_at).first
  end

  def changes
    @changes ||= item_changes.collect do |name, value|
      VersionChange.new(self, name, value, item_object[name])
    end
  end

  def visible_changes
    @changes ||= item_changes.collect do |name, value|
      unless value.blank? && item_object[name].blank?
        VersionChange.new(self, name, value, item_object[name])
      end
    end
  end

  # Adds method for CustomFields
  def self.customizable?
    false
  end
end
