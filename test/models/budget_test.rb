# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: budgets
#
#  computation_method :string(255)
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string(255)
#  direction          :string(255)      not null
#  global_amount      :float
#  global_quantity    :float
#  homogeneous_values :boolean
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  name               :string(255)
#  production_id      :integer
#  unit_amount        :float
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer
#  working_indicator  :string(255)
#  working_unit       :string(255)
#
require 'test_helper'

class BudgetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
