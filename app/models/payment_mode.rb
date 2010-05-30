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
# == Table: payment_modes
#
#  account_id            :integer          
#  cash_id               :integer          
#  commission_account_id :integer          
#  commission_percent    :decimal(16, 2)   default(0.0), not null
#  company_id            :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer          
#  direction             :string(64)       default("received"), not null
#  id                    :integer          not null, primary key
#  lock_version          :integer          default(0), not null
#  name                  :string(50)       not null
#  nature                :string(16)       
#  published             :boolean          
#  updated_at            :datetime         not null
#  updater_id            :integer          
#  with_accounting       :boolean          not null
#  with_commission       :boolean          not null
#  with_embankment       :boolean          not null
#

class PaymentMode < ActiveRecord::Base
  @@natures = [:card, :cash, :check, :other, :transfer] 
  attr_readonly :company_id, :direction
  belongs_to :account
  belongs_to :cash
  belongs_to :company
  has_many :entities, :dependent=>:nullify
  has_many :payments, :foreign_key=>:mode_id
  validates_inclusion_of :direction, :in=>%w( received given )
  validates_inclusion_of :nature, :in=>@@natures.collect{|x| x.to_s}

  # validates_presence_of :account_id

  def self.nature_label(nat)
    tc('natures.'+nat.to_s)
  end

  def self.direction_label(dir)
    tc('directions.'+dir.to_s)
  end

  def self.natures
    @@natures.collect{|x| [nature_label(x), x]}
  end

  def nature_label
    self.class.nature_label(self.nature)
  end
  
  def embankable_payments
    self.payments.find(:all, :conditions=>["embankment_id IS NULL AND entity_id!=?", self.company.entity_id])
  end

  def destroyable?
    self.payments.size <= 0
  end
  
end
