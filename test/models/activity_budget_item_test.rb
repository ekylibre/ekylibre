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
# == Table: activity_budget_items
#
#  activity_budget_id            :integer(4)       not null
#  amount                        :decimal(19, 4)
#  computation_method            :string           not null
#  created_at                    :datetime         not null
#  creator_id                    :integer(4)
#  currency                      :string           not null
#  direction                     :string           not null
#  frequency                     :string           default("per_year"), not null
#  global_amount                 :decimal(19, 4)
#  global_pretax_amount          :decimal(19, 4)
#  id                            :integer(4)       not null, primary key
#  lock_version                  :integer(4)       default(0), not null
#  locked                        :boolean          default(FALSE)
#  main_output                   :boolean          default(FALSE), not null
#  nature                        :string
#  origin                        :string
#  paid_on                       :date
#  pretax_amount                 :decimal(19, 4)   default(0.0)
#  product_parameter_id          :integer(4)
#  quantity                      :decimal(19, 4)   default(0.0)
#  repetition                    :integer(4)       default(1), not null
#  tax_id                        :integer(4)
#  transfer_price                :float
#  transfered_activity_budget_id :integer(4)
#  unit_amount                   :decimal(19, 4)   default(0.0)
#  unit_currency                 :string           not null
#  unit_id                       :integer(4)
#  unit_population               :decimal(19, 4)
#  updated_at                    :datetime         not null
#  updater_id                    :integer(4)
#  use_transfer_price            :boolean          default(FALSE)
#  used_on                       :date
#  variant_id                    :integer(4)
#  variant_indicator             :string
#  variant_unit                  :string
#
require 'test_helper'

class ActivityBudgetItemTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
end
