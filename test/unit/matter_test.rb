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
# == Table: products
#
#  active                   :boolean          not null
#  address_id               :integer          
#  area_measure             :decimal(19, 4)   
#  area_unit_id             :integer          
#  asset_id                 :integer          
#  born_at                  :datetime         
#  comment                  :text             
#  content_maximal_quantity :decimal(19, 4)   default(0.0), not null
#  content_nature_id        :integer          
#  content_unit_id          :integer          
#  created_at               :datetime         not null
#  creator_id               :integer          
#  dead_at                  :datetime         
#  description              :text             
#  external                 :boolean          not null
#  father_id                :integer          
#  id                       :integer          not null, primary key
#  lock_version             :integer          default(0), not null
#  maximal_quantity         :decimal(19, 4)   default(0.0), not null
#  minimal_quantity         :decimal(19, 4)   default(0.0), not null
#  mother_id                :integer          
#  name                     :string(255)      not null
#  nature_id                :integer          not null
#  number                   :string(255)      
#  owner_id                 :integer          
#  parent_warehouse_id      :integer          
#  picture_content_type     :string(255)      
#  picture_file_name        :string(255)      
#  picture_file_size        :integer          
#  picture_updated_at       :datetime         
#  producer_id              :integer          
#  reproductor              :boolean          not null
#  reservoir                :boolean          not null
#  serial_number            :string(255)      
#  sex                      :string(255)      
#  shape                    :spatial({:srid=> 
#  type                     :string(255)      not null
#  unit_id                  :integer          not null
#  updated_at               :datetime         not null
#  updater_id               :integer          
#
require 'test_helper'

class MatterTest < ActiveSupport::TestCase

  # Replace this with your real tests.'
  test "the truth" do
    assert true
  end

end
