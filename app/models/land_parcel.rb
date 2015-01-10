# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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


class LandParcel < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :area_measure, :allow_nil => true
  validates_length_of :name, :number, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  attr_readonly :company_id
  belongs_to :area_unit, :class_name=>"Unit"
  belongs_to :company
  belongs_to :group, :class_name=>"LandParcelGroup"
  has_many :operations, :as=>:target
  has_many :parent_kinships, :class_name=>"LandParcelKinship", :foreign_key=>:child_land_parcel_id, :dependent=>:destroy
  has_many :child_kinships, :class_name=>"LandParcelKinship", :foreign_key=>:parent_land_parcel_id, :dependent=>:destroy
  validates_presence_of :area_unit
  
  before_validation do
    #self.master = false if self.master.nil?
    #self.polygon ||= "-"
    self.started_on ||= Date.today
  end

  before_validation(:on=>:update) do
    if self.operations.count <= 0
      # We can't change the area of a parcel if operations has been made on it
      old = self.class.find(self.id)
      self.area_measure = old.area_measure
      self.area_unit_id = old.area_unit_id
    end
  end

  
  def divide(subdivisions, divided_on)
    if (total = subdivisions.collect{|s| s[:area_measure].to_f}.sum) != self.area_measure.to_f
      errors.add :area_measure, :invalid, :measure=>total, :expected_measure=>self.area_measure, :unit=>self.area_unit.name
      return false
    end
    return false unless divided_on.is_a? Date
    return false unless divided_on > self.started_on
    for subdivision in subdivisions
      child = self.company.land_parcels.create!(subdivision.merge(:started_on=>divided_on+1, :group_id=>self.group_id, :area_unit_id=>self.area_unit_id))
      self.company.land_parcel_kinships.create!(:parent_land_parcel=>self, :child_land_parcel=>child, :nature=>"divide")
    end
    self.update_attribute(:stopped_on, divided_on)
  end
  
  def merge(other_parcels, merged_on)
    return false unless other_parcels.size > 0
    return false unless merged_on.is_a? Date
    return false unless merged_on > self.started_on
    parcels, area = [self]+other_parcels, 0.0
    parcels.each{|p| area += p.area(self.area_unit) }
    child = self.company.land_parcels.create!(:name=>parcels.collect{|p| p.name}.join("+"), :started_on=>merged_on+1, :group_id=>self.group_id, :area_unit_id=>self.area_unit_id, :area_measure=>area)
    for parcel in parcels
      self.company.land_parcel_kinships.create!(:parent_land_parcel=>parcel, :child_land_parcel=>child, :nature=>"merge")
      parcel.update_attribute(:stopped_on, merged_on)
    end
    return child
  end
  
  
  def area(unit=nil)
    # return Unit.convert(self.area_measure, self.area_unit, unit)
    return self.area_unit.convert_to(self.area_measure, unit)
  end
  
  def operations_on(viewed_on=Date.today)
    self.operations.find(:all, :conditions=>["(moved_on IS NULL AND planned_on=?) OR (moved_on IS NOT NULL AND moved_on=?)", viewed_on, viewed_on])
  end
  
end
