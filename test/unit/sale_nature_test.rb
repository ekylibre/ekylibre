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
# == Table: sale_natures
#
#  active                  :boolean          default(TRUE), not null
#  comment                 :text             
#  company_id              :integer          not null
#  created_at              :datetime         not null
#  creator_id              :integer          
#  downpayment             :boolean          not null
#  downpayment_minimum     :decimal(16, 2)   default(0.0), not null
#  downpayment_rate        :decimal(16, 2)   default(0.0), not null
#  expiration_id           :integer          not null
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  name                    :string(255)      not null
#  payment_delay_id        :integer          not null
#  payment_mode_complement :text             
#  payment_mode_id         :integer          
#  updated_at              :datetime         not null
#  updater_id              :integer          
#


require 'test_helper'

class SaleNatureTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
