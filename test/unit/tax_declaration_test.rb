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
# == Table: tax_declarations
#
#  accounted_at             :datetime         
#  acquisition_amount       :decimal(16, 2)   
#  address                  :string(255)      
#  amount                   :decimal(16, 2)   
#  assimilated_taxes_amount :decimal(16, 2)   
#  balance_amount           :decimal(16, 2)   
#  collected_amount         :decimal(16, 2)   
#  company_id               :integer          not null
#  created_at               :datetime         not null
#  creator_id               :integer          
#  declared_on              :date             
#  deferred_payment         :boolean          
#  financial_year_id        :integer          
#  id                       :integer          not null, primary key
#  journal_entry_id         :integer          
#  lock_version             :integer          default(0), not null
#  nature                   :string(255)      default("normal"), not null
#  paid_amount              :decimal(16, 2)   
#  paid_on                  :date             
#  started_on               :date             
#  stopped_on               :date             
#  updated_at               :datetime         not null
#  updater_id               :integer          
#


