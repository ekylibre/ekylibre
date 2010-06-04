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
# == Table: purchase_payments
#
#  accounted_at   :datetime         
#  amount         :decimal(16, 2)   default(0.0), not null
#  check_number   :string(255)      
#  company_id     :integer          not null
#  created_at     :datetime         not null
#  created_on     :date             
#  creator_id     :integer          
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  mode_id        :integer          not null
#  number         :string(255)      
#  paid_on        :date             
#  parts_amount   :decimal(16, 2)   default(0.0), not null
#  payee_id       :integer          not null
#  responsible_id :integer          not null
#  to_bank_on     :date             not null
#  updated_at     :datetime         not null
#  updater_id     :integer          
#

class PurchasePayment < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :company
  belongs_to :responsible, :class_name=>User.name
  belongs_to :payee, :class_name=>Entity.name
  belongs_to :mode, :class_name=>PurchasePaymentMode.name
  has_many :parts, :class_name=>PurchasePaymentPart.name
  has_many :purchase_orders, :through=>:parts

end
