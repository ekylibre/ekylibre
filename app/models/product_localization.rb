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
# == Table: product_localizations
#
#  container_id :integer          
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  nature       :string(255)      not null
#  product_id   :integer          not null
#  started_at   :datetime         not null
#  stopped_at   :datetime         not null
#  transfer_id  :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#

class ProductLocalization < Ekylibre::Record::Base
  enumerize :nature, :in => [:transfer, :interior, :exterior], :default => :interior
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :allow_nil => true, :maximum => 255
  validates_presence_of :nature, :started_at, :stopped_at
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values
end
