# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Merigon
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
# == Table: transports
#
#  amount            :decimal(16, 2)   default(0.0), not null
#  comment           :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  created_on        :date             
#  creator_id        :integer          
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  number            :string(255)      
#  pretax_amount     :decimal(16, 2)   default(0.0), not null
#  purchase_order_id :integer          
#  reference_number  :string(255)      
#  responsible_id    :integer          
#  transport_on      :date             
#  transporter_id    :integer          not null
#  updated_at        :datetime         not null
#  updater_id        :integer          
#  weight            :decimal(16, 4)   
#


class Transport < ActiveRecord::Base
  acts_as_numbered
  attr_readonly :company_id
  belongs_to :company
  belongs_to :responsible, :class_name=>User.name
  belongs_to :transporter, :class_name=>Entity.name
  has_many :deliveries, :dependent=>:nullify, :class_name=>OutgoingDelivery.name

  before_validation(:on=>:create) do
    self.created_on ||= Date.today
  end

  before_validation do
    self.weight = 0
    for delivery in self.deliveries
      self.weight += delivery.weight
    end
  end

  def refresh
    self.save
  end

  def address
    a = self.transporter.full_name+"\n"
    a += self.transporter.default_contact.address.gsub(/\s*\,\s*/, "\n") if !self.transporter.default_contact.nil?
    a
  end
  

end
