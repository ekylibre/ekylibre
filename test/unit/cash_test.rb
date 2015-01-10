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
# == Table: cashes
#
#  account_id   :integer          not null
#  address      :text             
#  agency_code  :string(255)      
#  bank_code    :string(255)      
#  bank_name    :string(50)       
#  bic          :string(16)       
#  by_default   :boolean          not null
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  currency_id  :integer          not null
#  entity_id    :integer          
#  iban         :string(34)       
#  iban_label   :string(48)       
#  id           :integer          not null, primary key
#  journal_id   :integer          not null
#  key          :string(255)      
#  lock_version :integer          default(0), not null
#  mode         :string(255)      default("IBAN"), not null
#  name         :string(255)      not null
#  nature       :string(16)       default("bank_account"), not null
#  number       :string(255)      
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


require 'test_helper'

class CashTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
