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
#  area_measure             :decimal(19, 4)   
#  area_unit_id             :integer          
#  asset_id                 :integer          
#  born_at                  :datetime         
#  comment                  :text             
#  content_maximal_quantity :decimal(19, 4)   default(0.0), not null
#  content_nature_id        :integer          
#  content_unit_id          :integer          
#  created_at               :datetime         not null
#  creator_id               :integer          
#  dead_at                  :datetime         
#  description              :text             
#  external                 :boolean          not null
#  father_id                :integer          
#  id                       :integer          not null, primary key
#  lock_version             :integer          default(0), not null
#  maximal_quantity         :decimal(19, 4)   default(0.0), not null
#  minimal_quantity         :decimal(19, 4)   default(0.0), not null
#  mother_id                :integer          
#  name                     :string(255)      not null
#  nature_id                :integer          not null
#  number                   :string(255)      
#  owner_id                 :integer          
#  parent_warehouse_id      :integer          
#  picture_content_type     :string(255)      
#  picture_file_name        :string(255)      
#  picture_file_size        :integer          
#  picture_updated_at       :datetime         
#  producer_id              :integer          
#  reproductor              :boolean          not null
#  reservoir                :boolean          not null
#  serial_number            :string(255)      
#  sex                      :string(255)      
#  shape                    :spatial({:srid=> 
#  type                     :string(255)      not null
#  unit_id                  :integer          not null
#  updated_at               :datetime         not null
#  updater_id               :integer          
#  variety_id               :integer          not null
#


class Product < CompanyRecord
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, :allow_nil => true, :only_integer => true
  validates_numericality_of :area_measure, :content_maximal_quantity, :maximal_quantity, :minimal_quantity, :allow_nil => true
  validates_length_of :name, :number, :picture_content_type, :picture_file_name, :serial_number, :sex, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :external, :reproductor, :reservoir, :in => [true, false]
  validates_presence_of :content_maximal_quantity, :maximal_quantity, :minimal_quantity, :name, :nature, :unit, :variety
  #]VALIDATORS]
  belongs_to :nature
  belongs_to :variety
  belongs_to :unit
  has_many :memberships, :class_name => "ProductMembership"
  has_many :indicators, :class_name => "ProductIndicator"
  has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "100x100>" }

  accepts_nested_attributes_for :memberships, :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :indicators, :reject_if => :all_blank, :allow_destroy => true

  validates_presence_of :nature, :name, :number
end
