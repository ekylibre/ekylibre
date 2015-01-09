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
# == Table: versions
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  creator_name :string(255)
#  event        :string(255)      not null
#  id           :integer          not null, primary key
#  item_changes :text
#  item_id      :integer
#  item_object  :text
#  item_type    :string(255)
#

class Version < ActiveRecord::Base
  extend Enumerize
  cattr_accessor :current_user
  belongs_to :creator, class_name: "User"
  belongs_to :item, polymorphic: true
  enumerize :event, in: [:create, :update, :destroy], predicates: true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]

  scope :creations,    -> { where(event: "create") }
  scope :updates,      -> { where(event: "update") }
  scope :destructions, -> { where(event: "destroy") }
  scope :after,   lambda { |at| where("created_at > ?", at) }
  scope :before,  lambda { |at| where("created_at < ?", at) }
  scope :between, lambda { |started_at, stopped_at|
    where(created_at: started_at..stopped_at).order(created_at: :desc)
  }

  serialize :item_object,  HashWithIndifferentAccess
  serialize :item_changes, HashWithIndifferentAccess

  before_save do
    if self.item
      self.item_type = self.item.class.name
    end
    self.created_at ||= Time.now
    self.creator ||= Version.current_user
    if self.creator
      self.creator_name ||= self.creator.name
    end
    self.item_object = self.item.version_object
    if previous = self.previous
      self.item_changes = self.class.diff(previous.item_object, self.item_object)
    end
  end

  before_update do
    raise StandardError, "Cannot update a past version"
  end

  before_destroy do
    raise StandardError, "Cannot destroy a past version"
  end

  def self.diff(a, b)
    # return a.diff(b)
    return a.dup.
      delete_if { |k, v| b[k] == v }.
      merge!(b.dup.delete_if { |k, v| a.has_key?(k) })
  end

  def siblings
    self.item.versions
  end

  def following
    @following ||= self.siblings.after(self.created_at).first
  end

  def previous
    @previous ||= self.siblings.before(self.created_at).first
  end

  def changes
    return @changes ||= self.item_changes.collect do |name, value|
      VersionChange.new(self, name, value, self.item_object[name])
    end
  end

  def visible_changes
    return @changes ||= self.item_changes.collect do |name, value|
      unless value.blank? and self.item_object[name].blank?
        VersionChange.new(self, name, value, self.item_object[name])
      end
    end
  end

end
