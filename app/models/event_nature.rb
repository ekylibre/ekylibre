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
# == Table: event_natures
#
#  active       :boolean          default(TRUE), not null
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  duration     :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#  usage        :string(64)       
#


class EventNature < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :duration, :allow_nil => true, :only_integer => true
  validates_length_of :usage, :allow_nil => true, :maximum => 64
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :in => [true, false]
  validates_presence_of :company, :name
  #]VALIDATORS]
  attr_readonly :company_id, :name 
  belongs_to :company
  has_many :events, :foreign_key=>:nature_id

  protect_on_destroy do
    self.events.size <= 0 
  end

  def self.usages
    [:manual, :sale, :purchase, :sales_invoice].collect{|x| [tc('usages.'+x.to_s), x] }
  end
  
  def text_usage
    self.usage.blank? ? "" :   tc('usages.'+self.usage.to_s)
  end

end
