# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
# == Table: production_chain_work_centers
#
#  building_id         :integer          not null
#  comment             :text
#  created_at          :datetime         not null
#  creator_id          :integer
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  name                :string(255)      not null
#  nature              :string(255)      not null
#  operation_nature_id :integer          not null
#  position            :integer
#  production_chain_id :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class ProductionChainWorkCenter < CompanyRecord
  acts_as_list :scope => :production_chain
  enumerize :nature, :in => [:input, :output]
  belongs_to :building, :class_name => "Warehouse"
  belongs_to :operation_nature
  belongs_to :production_chain
  has_many :uses,  :class_name => "ProductionChainWorkCenterUse",  :foreign_key => :work_center_id
  has_many :output_conveyors, :dependent => :nullify, :class_name => "ProductionChainConveyor", :foreign_key => :source_id # :as => :source
  has_many :input_conveyors, :dependent => :nullify, :class_name => "ProductionChainConveyor", :foreign_key => :target_id # :as => :target
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :nature, :allow_nil => true, :maximum => 255
  validates_presence_of :building, :name, :nature, :operation_nature, :production_chain
  #]VALIDATORS]
  validates_uniqueness_of :name
end
