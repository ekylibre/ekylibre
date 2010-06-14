# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
# == Table: invoices
#
#  accounted_at       :datetime         
#  amount             :decimal(16, 2)   default(0.0), not null
#  amount_with_taxes  :decimal(16, 2)   default(0.0), not null
#  annotation         :text             
#  client_id          :integer          not null
#  company_id         :integer          not null
#  contact_id         :integer          
#  created_at         :datetime         not null
#  created_on         :date             
#  creator_id         :integer          
#  credit             :boolean          not null
#  currency_id        :integer          
#  downpayment_amount :decimal(16, 2)   default(0.0), not null
#  has_downpayment    :boolean          not null
#  id                 :integer          not null, primary key
#  journal_record_id  :integer          
#  lock_version       :integer          default(0), not null
#  lost               :boolean          not null
#  nature             :string(1)        not null
#  number             :string(64)       not null
#  origin_id          :integer          
#  paid               :boolean          not null
#  payment_delay_id   :integer          not null
#  payment_on         :date             not null
#  sale_order_id      :integer          
#  updated_at         :datetime         not null
#  updater_id         :integer          
#

require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
