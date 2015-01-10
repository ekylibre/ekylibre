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
# == Table: sales
#
#  accounted_at        :datetime         
#  amount              :decimal(16, 2)   default(0.0), not null
#  annotation          :text             
#  client_id           :integer          not null
#  comment             :text             
#  company_id          :integer          not null
#  conclusion          :text             
#  confirmed_on        :date             
#  contact_id          :integer          
#  created_at          :datetime         not null
#  created_on          :date             not null
#  creator_id          :integer          
#  credit              :boolean          not null
#  currency_id         :integer          
#  delivery_contact_id :integer          
#  downpayment_amount  :decimal(16, 2)   default(0.0), not null
#  expiration_id       :integer          
#  expired_on          :date             
#  function_title      :string(255)      
#  has_downpayment     :boolean          not null
#  id                  :integer          not null, primary key
#  initial_number      :string(64)       
#  introduction        :text             
#  invoice_contact_id  :integer          
#  invoiced_on         :date             
#  journal_entry_id    :integer          
#  letter_format       :boolean          default(TRUE), not null
#  lock_version        :integer          default(0), not null
#  lost                :boolean          not null
#  nature_id           :integer          
#  number              :string(64)       not null
#  origin_id           :integer          
#  paid_amount         :decimal(16, 2)   not null
#  payment_delay_id    :integer          not null
#  payment_on          :date             
#  pretax_amount       :decimal(16, 2)   default(0.0), not null
#  reference_number    :string(255)      
#  responsible_id      :integer          
#  state               :string(64)       default("O"), not null
#  subject             :string(255)      
#  sum_method          :string(8)        default("wt"), not null
#  transporter_id      :integer          
#  updated_at          :datetime         not null
#  updater_id          :integer          
#


require 'test_helper'

class SaleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
