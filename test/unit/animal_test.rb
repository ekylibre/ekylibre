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
# == Table: animals
#
#  born_on               :date             
#  ceded_on              :date             
#  comment               :text             
#  created_at            :datetime         not null
#  creator_id            :integer          
#  description           :text             
#  father_id             :integer          
#  group_id              :integer          not null
#  id                    :integer          not null, primary key
#  identification_number :string(255)      not null
#  income_on             :date             
#  lock_version          :integer          default(0), not null
#  mother_id             :integer          
#  name                  :string(255)      not null
#  outgone_on            :date             
#  owner_id              :integer          
#  picture_content_type  :string(255)      
#  picture_file_name     :string(255)      
#  picture_file_size     :integer          
#  picture_updated_at    :datetime         
#  purchased_on          :date             
#  race_id               :integer          
#  sex                   :string(16)       default("male"), not null
#  updated_at            :datetime         not null
#  updater_id            :integer          
#  working_number        :string(255)      
#
require 'test_helper'

class AnimalTest < ActiveSupport::TestCase

  # Replace this with your real tests.'
  test "the truth" do
    assert true
  end

end
