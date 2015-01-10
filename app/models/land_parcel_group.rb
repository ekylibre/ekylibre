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
# == Table: land_parcel_groups
#
#  color        :string(6)        default("000000"), not null
#  comment      :text             
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class LandParcelGroup < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :color, :allow_nil => true, :maximum => 6
  validates_length_of :name, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  attr_readonly :company_id
  belongs_to :company
  has_many :land_parcels, :foreign_key=>:group_id, :order=>:name
  validates_uniqueness_of :name, :scope=>:company_id

  def area(computed_on=Date.today, unit=nil)
    sum = 0
    parcels = self.land_parcels_on(computed_on)
    unit ||= parcels[0].area_unit
    for land_parcel in parcels
      sum += land_parcel.area(unit)
    end
    return sum
  end

  def land_parcels_on(computed_on=Date.today)
    self.land_parcels.find(:all, :conditions=>["? BETWEEN started_on AND COALESCE(stopped_on, ?)", computed_on, computed_on])
  end

end
