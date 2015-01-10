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
# == Table: entity_natures
#
#  active       :boolean          default(TRUE), not null
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  description  :text             
#  format       :string(255)      
#  id           :integer          not null, primary key
#  in_name      :boolean          default(TRUE), not null
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  physical     :boolean          not null
#  title        :string(255)      
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class EntityNature < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :format, :name, :title, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :in_name, :physical, :in => [true, false]
  validates_presence_of :company, :name
  #]VALIDATORS]
  attr_readonly :company_id
  belongs_to :company
  has_many :entities, :foreign_key=>:nature_id 
  validates_uniqueness_of :name, :scope=>:company_id

  before_validation do
    self.in_name = false if self.physical
    if self.physical
      self.format ||= '[title] [last_name] [first_name]'
    else
      self.format ||= '[last_name]'
    end
  end

  protect_on_destroy do
    self.entities.size <= 0
  end

end
