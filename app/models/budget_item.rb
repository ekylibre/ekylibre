# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: budget_items
#
#  amount             :float
#  budget_id          :integer
#  computation_method :string(255)
#  created_at         :datetime         not null
#  creator_id         :integer
#  direction          :string(255)
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  measure_unit       :string(255)
#  unit_amount        :float
#  updated_at         :datetime         not null
#  updater_id         :integer
#  working_unit       :string(255)
#
class BudgetItem < Ekylibre::Record::Base
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :unit_amount, allow_nil: true
  validates_length_of :computation_method, :direction, :measure_unit, :working_unit, allow_nil: true, maximum: 255
  #]VALIDATORS]
  enumerize :direction, in: [:revenue, :expense]
  enumerize :computation_method, in: [:per_production, :per_production_support, :per_working_unit]
  belongs_to :budget, inverse_of: :items
end
