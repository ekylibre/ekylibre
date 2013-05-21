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
# == Table: operation_tasks
#
#  created_at         :datetime         not null
#  creator_id         :integer          
#  detailled          :boolean          not null
#  id                 :integer          not null, primary key
#  indicator_datum_id :integer          
#  lock_version       :integer          default(0), not null
#  operand_id         :integer          
#  operand_quantity   :decimal(19, 4)   
#  operand_unit_id    :integer          
#  operation_id       :integer          not null
#  parent_id          :integer          
#  string             :string(255)      not null
#  subject_id         :integer          not null
#  updated_at         :datetime         not null
#  updater_id         :integer          
#  verb               :string(255)      not null
#
require 'test_helper'

class OperationTaskTest < ActiveSupport::TestCase

  test "presence of fixtures" do
    # assert_equal 2, OperationTask.count
  end

end
