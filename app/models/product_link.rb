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
# == Table: product_links
#
#  carried_id        :integer          not null
#  carrier_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  operation_task_id :integer          
#  started_at        :datetime         
#  stopped_at        :datetime         
#  updated_at        :datetime         not null
#  updater_id        :integer          
#
class ProductLink < Ekylibre::Record::Base
  belongs_to :carrier, class_name: 'Product'
  belongs_to :carried, class_name: 'Product'
  belongs_to :operation_task
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :carried, :carrier
  #]VALIDATORS]

  scope :at, lambda { |at| where("? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?)", at, at, at) }

end
