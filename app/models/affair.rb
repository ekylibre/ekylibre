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
# == Table: affairs
#
#  accounted_at     :datetime         
#  closed           :boolean          not null
#  closed_at        :datetime         
#  created_at       :datetime         not null
#  creator_id       :integer          
#  credit           :decimal(19, 4)   default(0.0), not null
#  currency         :string(3)        not null
#  debit            :decimal(19, 4)   default(0.0), not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  lock_version     :integer          default(0), not null
#  origin_id        :integer          not null
#  origin_type      :string(255)      not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#
class Affair < ActiveRecord::Base
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :credit, :debit, :allow_nil => true
  validates_length_of :currency, :allow_nil => true, :maximum => 3
  validates_length_of :origin_type, :allow_nil => true, :maximum => 255
  validates_inclusion_of :closed, :in => [true, false]
  validates_presence_of :credit, :currency, :debit, :origin_type
  #]VALIDATORS]
end
