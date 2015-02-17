# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
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
#  computation_method :string
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string
#  direction          :string
#  global_amount      :decimal(19, 4)   default(0.0)
#  global_quantity    :decimal(19, 4)   default(0.0)
#  homogeneous_values :boolean
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  name               :string
#  production_id      :integer
#  unit_amount        :decimal(19, 4)   default(0.0)
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer
#  working_indicator  :string
#  working_unit       :string
#
class Budget < Ekylibre::Record::Base
  enumerize :currency, in: Nomen::Currencies.all, default: Preference[:currency]
  enumerize :direction, in: [:revenue, :expense]
  enumerize :computation_method, in: [:per_production, :per_production_support, :per_working_unit], default: :per_working_unit
  enumerize :working_indicator, in: Production.working_indicator.values
  enumerize :working_unit, in: Nomen::Units.all.sort

  has_many :items, -> {order(:production_support_id)}, class_name: 'BudgetItem', inverse_of: :budget, foreign_key: :budget_id, dependent: :destroy
  has_many :orphaned_items, -> {where(production_support_id: nil)}, class_name: 'BudgetItem'
  has_many :supports, through: :production, class_name: 'ProductionSupport'
  belongs_to :production
  belongs_to :variant, class_name: 'ProductNatureVariant'

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :global_amount, :global_quantity, :unit_amount, allow_nil: true
  #]VALIDATORS]
  validates_presence_of :variant, :production


  accepts_nested_attributes_for :items, allow_destroy: true

  scope :revenues, -> {where direction: :revenue}
  scope :expenses, -> {where direction: :expense}


  before_validation do
    if self.name.blank?
      self.name = self.production.name
    end
  end

  validate do
    if ((self.direction == :revenue) && (self.production.homogeneous_revenues) || (self.direction == :expense) && (self.production.homogeneous_expenses))
      self.homogeneous_values = true
    end
  end

  after_create do
    supports_missing_item = (self.supports.pluck(:id) - self.items.pluck(:production_support_id)).reverse
    self.orphaned_items.each do |item|
      item.update(production_support_id: supports_missing_item.pop)
    end
  end
  after_validation do
    if self.computation_method.to_sym == :per_production
      self.global_amount = self.unit_amount * self.global_quantity
    elsif self.computation_method.to_sym == :per_working_unit
      self.global_amount = self.items.sum(:global_amount)
      self.global_quantity = self.items.sum(:quantity)
    end
  end
end
