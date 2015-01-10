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
# == Table: products
#
#  active                     :boolean          default(TRUE), not null
#  catalog_description        :text             
#  catalog_name               :string(255)      not null
#  category_id                :integer          not null
#  code                       :string(16)       
#  code2                      :string(64)       
#  comment                    :text             
#  company_id                 :integer          not null
#  created_at                 :datetime         not null
#  creator_id                 :integer          
#  critic_quantity_min        :decimal(16, 4)   default(1.0)
#  deliverable                :boolean          not null
#  description                :text             
#  ean13                      :string(13)       
#  for_immobilizations        :boolean          not null
#  for_productions            :boolean          not null
#  for_purchases              :boolean          not null
#  for_sales                  :boolean          default(TRUE), not null
#  id                         :integer          not null, primary key
#  immobilizations_account_id :integer          
#  lock_version               :integer          default(0), not null
#  name                       :string(255)      not null
#  nature                     :string(8)        not null
#  number                     :integer          not null
#  price                      :decimal(16, 2)   default(0.0)
#  published                  :boolean          not null
#  purchases_account_id       :integer          
#  quantity_max               :decimal(16, 4)   default(0.0)
#  quantity_min               :decimal(16, 4)   default(0.0)
#  reduction_submissive       :boolean          not null
#  sales_account_id           :integer          
#  service_coeff              :decimal(16, 4)   
#  stockable                  :boolean          not null
#  subscription_nature_id     :integer          
#  subscription_period        :string(255)      
#  subscription_quantity      :integer          
#  trackable                  :boolean          not null
#  unit_id                    :integer          not null
#  unquantifiable             :boolean          not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer          
#  weight                     :decimal(16, 3)   
#  with_tracking              :boolean          not null
#


require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
