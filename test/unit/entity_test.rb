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
# == Table: entities
#
#  active                    :boolean          default(TRUE), not null
#  activity_code             :string(32)       
#  attorney                  :boolean          not null
#  attorney_account_id       :integer          
#  authorized_payments_count :integer          
#  born_on                   :date             
#  category_id               :integer          
#  client                    :boolean          not null
#  client_account_id         :integer          
#  code                      :string(64)       
#  comment                   :text             
#  company_id                :integer          not null
#  country                   :string(2)        
#  created_at                :datetime         not null
#  creator_id                :integer          
#  dead_on                   :date             
#  deliveries_conditions     :string(60)       
#  discount_rate             :decimal(8, 2)    
#  ean13                     :string(13)       
#  excise                    :string(15)       
#  first_met_on              :date             
#  first_name                :string(255)      
#  full_name                 :string(255)      not null
#  hashed_password           :string(64)       
#  id                        :integer          not null, primary key
#  invoices_count            :integer          
#  language                  :string(3)        default("???"), not null
#  last_name                 :string(255)      not null
#  lock_version              :integer          default(0), not null
#  locked                    :boolean          not null
#  name                      :string(32)       
#  nature_id                 :integer          not null
#  origin                    :string(255)      
#  payment_delay_id          :integer          
#  payment_mode_id           :integer          
#  photo                     :string(255)      
#  proposer_id               :integer          
#  prospect                  :boolean          not null
#  reduction_rate            :decimal(8, 2)    
#  reflation_submissive      :boolean          not null
#  responsible_id            :integer          
#  salt                      :string(64)       
#  siren                     :string(9)        
#  soundex                   :string(4)        
#  supplier                  :boolean          not null
#  supplier_account_id       :integer          
#  transporter               :boolean          not null
#  updated_at                :datetime         not null
#  updater_id                :integer          
#  vat_number                :string(15)       
#  vat_submissive            :boolean          default(TRUE), not null
#  webpass                   :string(255)      
#  website                   :string(255)      
#


require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
