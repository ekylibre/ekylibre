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
# == Table: entities
#
#  active                              :boolean          default(TRUE), not null
#  activity_code                       :string(32)       
#  admin                               :boolean          not null
#  attorney                            :boolean          not null
#  attorney_account_id                 :integer          
#  authorized_payments_count           :integer          
#  born_on                             :date             
#  category_id                         :integer          
#  client                              :boolean          not null
#  client_account_id                   :integer          
#  code                                :string(64)       
#  comment                             :text             
#  connected_at                        :datetime         
#  country                             :string(2)        
#  created_at                          :datetime         not null
#  creator_id                          :integer          
#  currency                            :string(255)      not null
#  dead_on                             :date             
#  deliveries_conditions               :string(60)       
#  department_id                       :integer          
#  ean13                               :string(13)       
#  employed                            :boolean          not null
#  employment                          :string(255)      
#  establishment_id                    :integer          
#  first_met_on                        :date             
#  first_name                          :string(255)      
#  full_name                           :string(255)      not null
#  hashed_password                     :string(64)       
#  id                                  :integer          not null, primary key
#  invoices_count                      :integer          
#  language                            :string(3)        default("???"), not null
#  last_name                           :string(255)      not null
#  left_on                             :date             
#  lock_version                        :integer          default(0), not null
#  locked                              :boolean          not null
#  loggable                            :boolean          not null
#  maximum_grantable_reduction_percent :decimal(19, 4)   
#  nature_id                           :integer          not null
#  of_company                          :boolean          not null
#  office                              :string(255)      
#  origin                              :string(255)      
#  payment_delay_id                    :integer          
#  payment_mode_id                     :integer          
#  photo                               :string(255)      
#  profession_id                       :integer          
#  proposer_id                         :integer          
#  prospect                            :boolean          not null
#  recruited_on                        :date             
#  reduction_rate                      :decimal(19, 10)  
#  reflation_submissive                :boolean          not null
#  responsible_id                      :integer          
#  rights                              :text             
#  role_id                             :integer          
#  salt                                :string(64)       
#  siren                               :string(9)        
#  soundex                             :string(4)        
#  supplier                            :boolean          not null
#  supplier_account_id                 :integer          
#  transporter                         :boolean          not null
#  updated_at                          :datetime         not null
#  updater_id                          :integer          
#  username                            :string(32)       
#  vat_number                          :string(15)       
#  vat_submissive                      :boolean          default(TRUE), not null
#  webpass                             :string(255)      
#


require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
