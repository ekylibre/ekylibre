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
# == Table: budget_items
#
#  budget_id             :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  currency              :string(255)
#  global_amount         :decimal(19, 4)   default(0.0), not null
#  id                    :integer          not null, primary key
#  lock_version          :integer          default(0), not null
#  production_support_id :integer
#  quantity              :decimal(19, 4)   default(1.0), not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#
class BudgetItem < Ekylibre::Record::Base
  belongs_to :budget, inverse_of: :items
  belongs_to :production_support, inverse_of: :budget_items
  has_one :production, through: :budget

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :global_amount, :quantity, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 255
  validates_presence_of :budget, :global_amount, :quantity
  #]VALIDATORS]
  validates_uniqueness_of :production_support_id, scope: :budget_id

  delegate :computation_method, to: :budget
  delegate :direction, :unit_amount, to: :budget
  delegate :working_unit, :working_indicator, to: :production_support

  enumerize :currency, in: Nomen::Currencies.all, default: Preference[:currency]

  scope :of_budgets, lambda { |budgets| where(budget_id: budgets) }
  scope :of_budget_direction, lambda { |direction| joins(:budget).where("budgets.direction" => direction.to_sym) }
  scope :of_supports, lambda { |supports| where(production_support_id: supports) }

  before_validation do
    self.global_amount = self.unit_amount * self.quantity * self.production_support.working_indicator_measure.value rescue 0.0
  end


  def global_amount_per_working_indicator
    if self.production and self.production_support and working_indicator = self.production.working_indicator
      if indicator_value = self.production_support.storage.send(working_indicator)
        return self.global_amount / indicator_value.to_d(self.production.working_unit)
      end
      return nil
    end
    return nil
  end



end
