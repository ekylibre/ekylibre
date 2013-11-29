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
# == Table: product_linkages
#
#  carried_id   :integer          
#  carrier_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  nature       :string(255)      not null
#  operation_id :integer          
#  point        :string(255)      not null
#  started_at   :datetime         
#  stopped_at   :datetime         
#  updated_at   :datetime         not null
#  updater_id   :integer          
#
class ProductLinkage < Ekylibre::Record::Base
  include Taskable, TimeLineable
  belongs_to :carrier, class_name: 'Product'
  belongs_to :carried, class_name: 'Product'
  enumerize :nature, in: [:available, :unavailable, :occupied], default: :available, predicates: true
  enumerize :point, in: [:rear, :front]
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :originator_type, :point, allow_nil: true, maximum: 255
  validates_presence_of :carrier, :nature, :point
  #]VALIDATORS]
  validates_presence_of :carried, :if => :occupied?

  scope :with, lambda { |point| where(point: point) }

  private

  # Returns all siblings in the chronological line
  def siblings
    self.carrier.linkages.with(self.point)
  end

end
