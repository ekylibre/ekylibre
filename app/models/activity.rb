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
# == Table: activities
#
#  analytical_center_type    :string(255)      not null
#  area_unit_id              :integer
#  closed                    :boolean          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  description               :string(255)
#  family                    :string(255)      not null
#  favored_product_nature_id :integer
#  id                        :integer          not null, primary key
#  lock_version              :integer          default(0), not null
#  name                      :string(255)      not null
#  net_margin                :boolean          not null
#  nomen                     :string(255)
#  parent_id                 :integer
#  updated_at                :datetime         not null
#  updater_id                :integer
#  work_unit_id              :integer
#
class Activity < Ekylibre::Record::Base
  attr_accessible :closed, :net_margin, :favored_product_nature_id, :area_unit_id, :work_unit_id, :analytical_center_type, :description, :family, :nomen, :name, :parent_id
  enumerize :analytical_center_type, :in => [:main, :ancillary, :none], :default=> :main
  enumerize :family, :in => [:vegetal, :perenne_vegetal, :animal, :processing, :service, :none]

  belongs_to :area_unit, :class_name => "Unit"
  belongs_to :work_unit, :class_name => "Unit"
  belongs_to :parent, :class_name => "Activity"
  belongs_to :favored_product_nature, :class_name => "ProductNature"
  has_many :repartitions, :class_name => "AnalyticRepartition", :foreign_key => :activity_id

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :analytical_center_type, :description, :family, :name, :nomen, :allow_nil => true, :maximum => 255
  validates_inclusion_of :closed, :net_margin, :in => [true, false]
  validates_presence_of :analytical_center_type, :family, :name
  #]VALIDATORS]

  default_scope -> { where(:closed => false).order(:name) }

end
