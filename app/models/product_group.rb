# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: products
#
#  active                   :boolean          not null
#  address_id               :integer
#  asset_id                 :integer
#  born_at                  :datetime
#  content_indicator        :string(255)
#  content_indicator_unit   :string(255)
#  content_maximal_quantity :decimal(19, 4)   default(0.0), not null
#  content_nature_id        :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  dead_at                  :datetime
#  description              :text
#  external                 :boolean          not null
#  father_id                :integer
#  id                       :integer          not null, primary key
#  identification_number    :string(255)
#  lock_version             :integer          default(0), not null
#  mother_id                :integer
#  name                     :string(255)      not null
#  nature_id                :integer          not null
#  number                   :string(255)      not null
#  owner_id                 :integer          not null
#  parent_id                :integer
#  picture_content_type     :string(255)
#  picture_file_name        :string(255)
#  picture_file_size        :integer
#  picture_updated_at       :datetime
#  reproductor              :boolean          not null
#  reservoir                :boolean          not null
#  sex                      :string(255)
#  shape                    :spatial({:srid=>
#  tracking_id              :integer
#  type                     :string(255)
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variant_id               :integer          not null
#  variety                  :string(127)      not null
#  work_number              :string(255)
#


class ProductGroup < Product
  attr_accessible :active, :external, :description, :name, :variety, :unit, :nature_id, :reproductor, :reservoir, :parent_id, :memberships_attributes

  belongs_to :parent, :class_name => "ProductGroup"
  has_many :memberships, :class_name => "ProductMembership", :foreign_key => :group_id
  has_many :members, :through => :memberships

  default_scope -> { order(:name) }
  scope :groups_of, lambda { |member, viewed_at| where("id IN (SELECT group_id FROM #{ProductMembership.table_name} WHERE member_id = ? AND ? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?))", member.id, viewed_at, viewed_at, viewed_at) }

  # FIXME
  # accepts_nested_attributes_for :memberships, :reject_if => :all_blank, :allow_destroy => true

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]
  validates_uniqueness_of :name

  # Add a member to the group
  def add(member, started_at = nil)
    raise ArgumentError.new("Product expected, got #{member.class}:#{member.inspect}") unless member.is_a?(Product)
    unless
      self.memberships.create!(:member_id => member.id, :started_at => (started_at || Time.now))
    end
  end

  # Remove a member from the group
  def remove(member, stopped_at = nil)
    raise ArgumentError.new("Product expected, got #{member.class}:#{member.inspect}") unless member.is_a?(Product)
    stopped_at ||= Time.now
    if membership = ProductMembership.where(:group_id => self.id, :member_id => member.id).where("stopped_at IS NULL AND COALESCE(started_at, ?) <= ?", stopped_at, stopped_at).order(:started_at)
      membership.stopped_at = stopped_at
      membership.save!
    else
      self.memberships.create!(:member_id => member.id, :stopped_at => stopped_at)
    end
  end


  # Returns members of the group at a given time (or now by default)
  def members_at(viewed_at = nil)
    Product.members_of(self, viewed_at || Time.now)
  end

end
