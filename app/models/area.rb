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
# == Table: areas
#
#  city         :string(255)      
#  city_name    :string(255)      
#  code         :string(255)      
#  company_id   :integer          not null
#  country      :string(2)        default("??")
#  created_at   :datetime         not null
#  creator_id   :integer          
#  district_id  :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  postcode     :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Area < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :country, :allow_nil => true, :maximum => 2
  validates_length_of :city, :city_name, :code, :name, :postcode, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  belongs_to :company
  belongs_to :district
  has_many :contacts

  attr_readonly :company_id

  before_validation do
    return false unless self.company
    self.name = self.name.gsub(/\s+/,' ').strip
    words = self.name.to_s.split(' ')
    start = words[0].to_s.ascii.length<=3 ? 2 : 1
    self.postcode, self.city, self.city_name = '', '', ''
    if words and words.size>0
      self.postcode = (words[0..start-1]||[]).join(" ")
      self.city = (words[start..-1]||[]).join(" ")
      self.city_name = self.city
      if self.city_name.match(/cedex/i)
        self.city_name = self.city_name.split(/\scedex/i)[0].strip 
      end
    end
  end

  def self.exportable_columns
    self.content_columns.delete_if{|c| ![:city, :postcode].include?(c.name.to_sym)}
  end


end


