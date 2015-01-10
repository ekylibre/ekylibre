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
# == Table: document_templates
#
#  active       :boolean          not null
#  by_default   :boolean          default(TRUE), not null
#  cache        :text             
#  code         :string(32)       
#  company_id   :integer          not null
#  country      :string(2)        
#  created_at   :datetime         not null
#  creator_id   :integer          
#  family       :string(32)       
#  filename     :string(255)      
#  id           :integer          not null, primary key
#  language     :string(3)        default("???"), not null
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(64)       
#  source       :text             
#  to_archive   :boolean          
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


require 'test_helper'

class PrintTemplateTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
