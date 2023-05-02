# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: master_budgets
#
#  activity_family    :string           not null
#  budget_category    :string           not null
#  direction          :string           not null
#  frequency          :string           not null
#  mode               :string
#  proportionnal_key  :string
#  quantity           :decimal(8, 2)    not null
#  repetition         :integer(4)       not null
#  start_month        :integer(4)       not null
#  tax_rate           :decimal(8, 2)    not null
#  unit               :string           not null
#  unit_pretax_amount :decimal(8, 2)    not null
#  variant            :string           not null
#

class MasterBudget < LexiconRecord
  extend Enumerize
  include Lexiconable
  enumerize :direction, in: %i[revenue expense], predicates: true
  enumerize :frequency, in: %i[per_year per_month], predicates: true
  enumerize :mode, in: %i[uo output global production], default: 'uo', predicates: true
  scope :of_family, ->(family) { where(activity_family: Onoma::ActivityFamily.all(family)) }

  def first_used_on(year)
    Date.new(year, start_month, 0o1)
  end

  def year_repetition
    if per_year?
      repetition
    elsif per_month?
      repetition * 12
    else
      1
    end
  end

  def day_gap
    if year_repetition != 0
      360 / year_repetition
    else
      360
    end
  end

  # link to computation_method in budget_item [per_campaign per_production per_working_unit]
  def computation_method
    case mode
    when 'uo'
      'per_working_unit'
    when 'global'
      'per_campaign'
    when 'production'
      'per_production'
    when 'output'
      'per_working_unit'
    else
      'per_campaign'
    end
  end

end
