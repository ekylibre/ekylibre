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
# == Table: product_groups
#
#  color        :string(255)
#  created_at   :datetime         not null
#  creator_id   :integer
#  depth        :integer          default(0), not null
#  description  :text
#  id           :integer          not null, primary key
#  lft          :integer
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  parent_id    :integer
#  rgt          :integer
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class ProductGroup < Ekylibre::Record::Base
  attr_accessible :description, :description, :name, :parent_id, :memberships_attributes

  belongs_to :parent, :class_name => "ProductGroup"
  has_many :memberships, :class_name => "ProductMembership", :foreign_key => :group_id
  has_many :products, :through => :memberships

  default_scope -> { order(:name) }
  scope :groups_of, lambda { |product, viewed_at| where("id IN (SELECT group_id FROM #{ProductMembership.table_name} WHERE product_id = ? AND ? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?))", product.id, viewed_at, viewed_at, viewed_at) }

  accepts_nested_attributes_for :memberships,    :reject_if => :all_blank, :allow_destroy => true

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :depth, :lft, :rgt, :allow_nil => true, :only_integer => true
  validates_length_of :color, :name, :allow_nil => true, :maximum => 255
  validates_presence_of :depth, :name
  #]VALIDATORS]
  validates_uniqueness_of :name

  # Add a product to the group
  def add(product, started_at = nil)
    raise ArgumentError.new("Product expected, got #{product.class}:#{product.inspect}") unless product.is_a?(Product)
    unless
      self.memberships.create!(:product_id => product_id, :started_at => (started_at || Time.now))
    end
  end

  # Remove a product from the group
  def remove(product, stopped_at = nil)
    raise ArgumentError.new("Product expected, got #{product.class}:#{product.inspect}") unless product.is_a?(Product)
    stopped_at ||= Time.now
    if membership = ProductMembership.where(:group_id => self.id, :product_id => product.id).where("stopped_at IS NULL AND COALESCE(started_at, ?) <= ?", stopped_at, stopped_at).order(:started_at)
      membership.stopped_at = stopped_at
      membership.save!
    else
      self.memberships.create!(:product_id => product_id, :stopped_at => stopped_at)
    end
  end


  # Returns products of the group at a given time (or now by default)
  def products_at(viewed_at = nil)
    Product.members_of(self, viewed_at || Time.now)
  end

end
