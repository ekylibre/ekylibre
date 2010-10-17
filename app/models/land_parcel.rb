# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
# == Table: land_parcels
#
#  area_measure :decimal(16, 4)   default(0.0), not null
#  area_unit_id :integer          
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  description  :text             
#  group_id     :integer          not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  number       :string(255)      
#  started_on   :date             not null
#  stopped_on   :date             
#  updated_at   :datetime         not null
#  updater_id   :integer          
#

class LandParcel < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :area_unit, :class_name=>Unit.name
  belongs_to :company
  belongs_to :group, :class_name=>LandParcelGroup.name
  has_many :operations, :as=>:target
  has_many :parent_kinships, :class_name=>LandParcelKinship.name, :foreign_key=>:child_land_parcel_id
  has_many :child_kinships, :class_name=>LandParcelKinship.name, :foreign_key=>:parent_land_parcel_id
  validates_presence_of :area_unit

  def prepare
    #self.master = false if self.master.nil?
    #self.polygon ||= "-"
    self.started_on ||= Date.today
  end

  def divide(subdivisions, divided_on)
    if (total = subdivisions.collect{|s| s[:area_measure].to_f}.sum) != self.area_measure.to_f
      errors.add :area_measure, :invalid, :measure=>total, :expected_measure=>self.area_measure, :unit=>self.area_unit.name
      return false
    end
    return false unless divided_on > self.started_on
    return false unless divided_on.is_a? Date
    for subdivision in subdivisions
      child = self.company.land_parcels.create!(subdivision.merge(:started_on=>divided_on+1, :group_id=>self.group_id, :area_unit_id=>self.area_unit_id))
      self.company.land_parcel_kinships.create!(:parent_land_parcel=>self, :child_land_parcel=>child, :nature=>"divide")
    end
    self.update_attribute(:stopped_on, divided_on)
  end

  def area(unit=nil)
    return Unit.convert(self.area_measure, self.area_unit, unit)
  end
  
  def operations_on(viewed_on=Date.today)
    self.operations.where("(moved_on IS NULL AND planned_on=?) OR (moved_on IS NOT NULL AND moved_on=?)", viewed_on, viewed_on)
  end

end
