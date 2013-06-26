# -*- coding: utf-8 -*-
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
#  content_maximal_quantity :decimal(19, 4)   default(0.0), not null
#  content_nature_id        :integer
#  content_unit             :string(255)
#  created_at               :datetime         not null
#  creator_id               :integer
#  current_place_id         :integer
#  dead_at                  :datetime
#  description              :text
#  external                 :boolean          not null
#  father_id                :integer
#  id                       :integer          not null, primary key
#  identification_number    :string(255)
#  lock_version             :integer          default(0), not null
#  maximal_quantity         :decimal(19, 4)   default(0.0), not null
#  minimal_quantity         :decimal(19, 4)   default(0.0), not null
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
#  real_quantity            :decimal(19, 4)   default(0.0), not null
#  reproductor              :boolean          not null
#  reservoir                :boolean          not null
#  sex                      :string(255)
#  shape                    :spatial({:srid=>
#  tracking_id              :integer
#  type                     :string(255)
#  unit                     :string(255)      not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variety                  :string(127)      not null
#  virtual_quantity         :decimal(19, 4)   default(0.0), not null
#  work_number              :string(255)
#


class Product < Ekylibre::Record::Base
  attr_accessible :nature_id, :number, :identification_number, :work_number, :born_at, :sex, :picture, :owner_id, :parent_id
  # raise Nomenclatures["varieties:root"].children.keys.inspect
  enumerize :variety, :in => Nomenclatures["varieties-product"].list, :predicates => {:prefix => true}
  belongs_to :nature, :class_name => "ProductNature"
  # belongs_to :variety, :class_name => "ProductVariety"
  enumerize :unit, :in => Nomenclatures["units"].list, :default => Nomenclatures["units"].list.first, :predicates => {:prefix => true}
  # belongs_to :unit
  # belongs_to :area_unit, :class_name => "Unit"
  belongs_to :tracking
  belongs_to :content_nature, :class_name => "ProductNature"
  belongs_to :father, :class_name => "Product"
  belongs_to :mother, :class_name => "Product"
  belongs_to :owner, :class_name => "Entity"
  has_many :memberships, :class_name => "ProductMembership", :foreign_key => :member_id
  has_many :groups, :through => :memberships
  has_many :indicator_data, :class_name => "ProductIndicatorDatum", :dependent => :destroy
  has_many :operation_tasks, :foreign_key => :subject_id
  has_many :product_localizations
  has_many :incidents, :class_name => "Incident", :as => :target
  has_attached_file :picture, {
    :url => '/backend/:class/:id/picture/:style',
    :path => ':rails_root/private/:class/:attachment/:id_partition/:style.:extension',
    :styles => {
      :thumb => ["64x64#", :jpg],
      :identity => ["180x180", :jpg]
      # :large => ["600x600", :jpg]
    }
  }

  default_scope -> { order(:name) }
  scope :members_of, lambda { |group, viewed_at| where("id IN (SELECT member_id FROM #{ProductMembership.table_name} WHERE group_id = ? AND ? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?))", group.id, viewed_at, viewed_at, viewed_at)}
  # scope :saleables, -> { joins(:nature).where(:active => true, :product_natures => {:saleable => true}) }
  scope :saleables, -> { where(true) }


  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, :allow_nil => true, :only_integer => true
  validates_numericality_of :content_maximal_quantity, :maximal_quantity, :minimal_quantity, :real_quantity, :virtual_quantity, :allow_nil => true
  validates_length_of :variety, :allow_nil => true, :maximum => 127
  validates_length_of :content_unit, :identification_number, :name, :number, :picture_content_type, :picture_file_name, :sex, :unit, :work_number, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :external, :reproductor, :reservoir, :in => [true, false]
  validates_presence_of :content_maximal_quantity, :maximal_quantity, :minimal_quantity, :name, :nature, :number, :owner, :real_quantity, :unit, :variety, :virtual_quantity
  #]VALIDATORS]
  validates_presence_of :nature, :name, :owner

  accepts_nested_attributes_for :memberships, :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :indicator_data, :reject_if => :all_blank, :allow_destroy => true
  acts_as_numbered
  delegate :serial_number, :producer, :to => :tracking
  delegate :name, :to => :nature, :prefix => true
  delegate :subscribing?, :deliverable?, :to => :nature
  before_validation :set_variety_and_unit, :on => :create

  validate do
    # TODO: Check variety is the variety or a sub-variety of the (product) nature.
  end

  # TODO: Removes this ASAP
  def deliverable?
    false
  end

  def set_variety_and_unit
    if self.nature
      self.variety ||= self.nature.variety
      self.unit    ||= self.nature.unit
    end
  end


  # Returns the matching model for the record
  def matching_model
    return ProductNature.matching_model(self.variety)
  end


  # Returns the price for the product.
  # It's a shortcut for ProductPrice::give
  def price(options = {})
    return ProductPriceTemplate.price(self, options)
  end

  # Add an operation for the product
  def operate(action, *args)
    options = (args[-1].is_a?(Hash) ? options.delete_at(-1) : {})
    if operand = (args[0].is_a?(Product) ? args[0] : nil)
      options[:operand] = operand
    end
    return self.operations.create(options)
  end

  # Returns groups of the product at a given time (or now by default)
  def groups_at(viewed_at = nil)
    ProductGroup.groups_of(self, viewed_at || Time.now)
  end

  def picture_path(style=:original)
    self.picture.path(style)
  end

end
