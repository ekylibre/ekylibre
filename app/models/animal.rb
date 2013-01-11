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
# == Table: animals
#
#  born_on               :date             
#  comment               :text             
#  created_at            :datetime         not null
#  creator_id            :integer          
#  description           :text             
#  father_id             :integer          
#  group_id              :integer          not null
#  id                    :integer          not null, primary key
#  identification_number :string(255)      not null
#  income_on             :date             
#  income_reasons        :string(255)      
#  is_external           :boolean          not null
#  is_reproductor        :boolean          not null
#  lock_version          :integer          default(0), not null
#  mother_id             :integer          
#  name                  :string(255)      not null
#  outgone_on            :date             
#  outgone_reasons       :string(255)      
#  owner_id              :integer          
#  picture_content_type  :string(255)      
#  picture_file_name     :string(255)      
#  picture_file_size     :integer          
#  picture_updated_at    :datetime         
#  race_id               :integer          
#  sex                   :string(16)       default("male"), not null
#  updated_at            :datetime         not null
#  updater_id            :integer          
#  working_number        :string(255)      
#


class Animal < CompanyRecord
  attr_accessible :custom_field_data_attributes, :reproductor, :arrival_reasons, :departure_reasons, :external, :born_on, :comment, :description, :father_id, :mother_id, :group_id, :identification_number, :arrived_on, :name, :departed_on, :picture, :race_id, :sex, :work_number
  enumerize :sex, :in => [:male, :female]
  enumerize :arrival_reasons, :in => [:birth, :purchase, :housing, :other], :default=> :birth
  enumerize :departure_reasons, :in => [:dead, :sale, :autoconsumption, :other], :default=> :sale
  belongs_to :group, :class_name => "AnimalGroup"
  belongs_to :race, :class_name => "AnimalRace"
  belongs_to :father, :class_name => "Animal", :conditions => {:sex => :male, :reproductor => 'true'}
  belongs_to :mother, :class_name => "Animal", :conditions => {:sex => :female}
  has_many :events, :class_name => "AnimalEvent",:foreign_key => :animal_id
  has_many :treatments, :class_name => "AnimalTreatment", :through => :events
  has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "100x100>" }

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, :allow_nil => true, :only_integer => true
  validates_length_of :sex, :allow_nil => true, :maximum => 16
  validates_length_of :identification_number, :arrival_reasons, :name, :departure_reasons, :picture_content_type, :picture_file_name, :working_number, :allow_nil => true, :maximum => 255
  validates_inclusion_of :external, :reproductor, :in => [true, false]
  validates_presence_of :group, :identification_number, :name, :sex
  #]VALIDATORS]
  validates_uniqueness_of :name, :identification_number
  validates_inclusion_of :sex, :in => self.sex.values
  validates_length_of :work_number, :allow_nil => true, :maximum => 4


  default_scope order(:name)
  scope :father, where("sex = 'male' AND reproductor = true").order(:name)
  scope :mother, where("sex = 'female'").order(:name)
  scope :here, where("external = ? AND (departed_on IS NULL or departed_on > ?)", false, Time.now).order(:name)


end
