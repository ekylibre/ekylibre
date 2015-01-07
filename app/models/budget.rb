# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: budgets
#
#  computation_method :string(255)
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string(255)
#  direction          :string(255)
#  global_amount      :decimal(19, 4)   default(0.0)
#  global_quantity    :decimal(19, 4)   default(0.0)
#  homogeneous_values :boolean
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  name               :string(255)
#  production_id      :integer
#  unit_amount        :decimal(19, 4)   default(0.0)
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer
#  working_indicator  :string(255)
#  working_unit       :string(255)
#
class Budget < Ekylibre::Record::Base
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :global_amount, :global_quantity, :unit_amount, allow_nil: true
  validates_length_of :computation_method, :currency, :direction, :name, :working_indicator, :working_unit, allow_nil: true, maximum: 255
  #]VALIDATORS]
  has_many :items, class_name: 'BudgetItem', inverse_of: :budget, foreign_key: :budget_id
  has_many :supports, through: :production
  belongs_to :production
  belongs_to :variant, class_name: 'ProductNatureVariant'

  enumerize :currency, in: Nomen::Currencies.all, default: Preference[:currency]
  enumerize :direction, in: [:revenue, :expense]
  enumerize :computation_method, in: [:per_production_support, :per_working_unit]
  enumerize :working_indicator, in: (Nomen::Indicators.all << 'work_duration')
  enumerize :working_unit, in: Nomen::Units.all

  accepts_nested_attributes_for :items

  scope :revenues, -> {where direction: :revenue}
  scope :expenses, -> {where direction: :expense}

  validate do
    Budget.all.each do |budget|
      budget.destroy unless budget.variant.present?
    end
  end
end
