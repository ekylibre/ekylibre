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
#  extjuncted            :boolean          not null
#  financial_asset_id    :integer
#  id                    :integer          not null, primary key
#  identification_number :string
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_geolocation   :spatial({:srid=>4326, :type=>"point"})
#  initial_mother_id     :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :spatial({:srid=>4326, :type=>"geometry"})
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


class ProductGroup < Product
  enumerize :variety, in: Nomen::Varieties.all(:product_group), predicates: {prefix: true}
  belongs_to :parent, class_name: "ProductGroup"
  has_many :memberships, class_name: "ProductMembership", foreign_key: :group_id, dependent: :destroy
  has_many :members, through: :memberships

  scope :groups_of, lambda { |member, viewed_at|
    where("id IN (SELECT group_id FROM #{ProductMembership.table_name} WHERE member_id = ? AND nature = ? AND ? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?))", member.id, "interior", viewed_at, viewed_at, viewed_at)
  }

  # FIXME
  # accepts_nested_attributes_for :memberships, :reject_if => :all_blank, :allow_destroy => true

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]

  # Add a member to the group
  def add(member, started_at = nil)
    unless member.is_a?(Product)
      raise ArgumentError, "Product expected, got #{member.class}:#{member.inspect}"
    end
    self.memberships.create!(member: member, started_at: (started_at || Time.now), nature: :interior)
  end

  # Remove a member from the group
  def remove(member, stopped_at = nil)
    unless member.is_a?(Product)
      raise ArgumentError, "Product expected, got #{member.class}:#{member.inspect}"
    end
    self.memberships.create!(member: member, started_at: (stopped_at || Time.now), nature: :exterior)
  end


  # Returns members of the group at a given time (or now by default)
  def members_at(viewed_at = nil)
    Product.members_of(self, viewed_at || Time.now)
  end

end
