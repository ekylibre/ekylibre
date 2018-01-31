# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: accounts
#
#  created_at    :datetime         not null
#  creator_id    :integer
#  custom_fields :jsonb
#  debtor        :boolean          default(FALSE), not null
#  description   :text
#  id            :integer          not null, primary key
#  label         :string           not null
#  last_letter   :string
#  lock_version  :integer          default(0), not null
#  name          :string           not null
#  number        :string           not null
#  reconcilable  :boolean          default(FALSE), not null
#  updated_at    :datetime         not null
#  updater_id    :integer
#  usages        :text
#
require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test_model_actions

  test 'load the accounts' do
    Account.accounting_systems.each do |accounting_system|
      Account.accounting_system = accounting_system
      Account.load_defaults
    end
  end

  test 'merge' do
    main = Account.first
    double = Account.second
    main.merge_with(double)
    assert_nil Account.find_by(id: double.id)
  end
end
