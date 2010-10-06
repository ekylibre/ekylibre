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
# == Table: production_chain_tokens
#
#  comment             :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  number              :string(255)      not null
#  production_chain_id :integer          not null
#  started_at          :datetime         not null
#  stopped_at          :datetime         
#  story               :text             
#  updated_at          :datetime         not null
#  updater_id          :integer          
#  where_id            :integer          not null
#  where_type          :string(255)      not null
#

class ProductionChainToken < ActiveRecord::Base
  attr_readonly :company_id, :number
  belongs_to :company
  belongs_to :production_chain
  has_many :operations, :dependent=>:nullify

  validates_uniqueness_of :number, :scope=>:company_id

  def prepare_on_create
    self.code = self.company.production_chain_token.max(:number)
    self.code = (self.code.blank? ? "AAAAAA" : self.code.succ)
  end

end
