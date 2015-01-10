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
# == Table: outgoing_payments
#
#  accounted_at     :datetime         
#  amount           :decimal(16, 2)   default(0.0), not null
#  check_number     :string(255)      
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  created_on       :date             
#  creator_id       :integer          
#  delivered        :boolean          default(TRUE), not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  lock_version     :integer          default(0), not null
#  mode_id          :integer          not null
#  number           :string(255)      
#  paid_on          :date             
#  payee_id         :integer          not null
#  responsible_id   :integer          not null
#  to_bank_on       :date             not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#  used_amount      :decimal(16, 2)   default(0.0), not null
#


require 'test_helper'

class OutgoingPaymentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
