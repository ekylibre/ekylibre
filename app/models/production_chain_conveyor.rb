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
# == Table: production_chain_conveyors
#
#  check_state         :boolean          not null
#  comment             :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  flow                :decimal(16, 4)   default(0.0), not null
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  product_id          :integer          not null
#  production_chain_id :integer          not null
#  source_id           :integer          
#  source_quantity     :decimal(16, 4)   default(0.0), not null
#  target_id           :integer          
#  target_quantity     :decimal(16, 4)   default(0.0), not null
#  unique_tracking     :boolean          not null
#  unit_id             :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer          
#


class ProductionChainConveyor < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :flow, :source_quantity, :target_quantity, :allow_nil => true
  validates_inclusion_of :check_state, :unique_tracking, :in => [true, false]
  validates_presence_of :company, :flow, :product, :production_chain, :source_quantity, :target_quantity, :unit
  #]VALIDATORS]
  attr_readonly :company_id
  belongs_to :company
  belongs_to :product
  belongs_to :production_chain
  belongs_to :source, :class_name=>"ProductionChainWorkCenter"
  belongs_to :target, :class_name=>"ProductionChainWorkCenter"
  belongs_to :unit

  @@check_events = [:none, :input, :output, :both]
  def self.check_events_list
    @@check_events.collect{|x| [tc("check_events.#{x}"), x.to_s]}
  end

  before_validation do
    self.company_id = self.production_chain.company_id if self.production_chain
    self.unit ||= self.product.unit if self.product
    self.target_quantity = 0 unless self.target
    self.source_quantity = 0 unless self.source
  end
  
end
