# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
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
#  already_existing          :boolean          default(FALSE), not null
#  auxiliary_number          :string
#  centralizing_account_name :string
#  created_at                :datetime         not null
#  creator_id                :integer
#  custom_fields             :jsonb
#  debtor                    :boolean          default(FALSE), not null
#  description               :text
#  id                        :integer          not null, primary key
#  label                     :string           not null
#  last_letter               :string
#  lock_version              :integer          default(0), not null
#  name                      :string           not null
#  nature                    :string
#  number                    :string           not null
#  reconcilable              :boolean          default(FALSE), not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#  usages                    :text
#
require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test_model_actions

  test 'load the accounts' do
    (Account.accounting_systems - ['pt_snc']).each do |accounting_system|
      Account.accounting_system = accounting_system
      Account.load_defaults
    end
  end

  test 'merge' do
    main = create :account
    double = create :account
    main.merge_with(double)
    assert_nil Account.find_by(id: double.id)
  end

  test 'already existing account can get updated with any number' do
    account_1 = create(:account, already_existing: true)
    account_1.update(number: '123')
    assert account_1.number, '123'
    account_2 = create(:account, already_existing: true)
    account_2.update(number: '123456789')
    assert account_2.number, '123456789'
  end

  test 'number of auxiliary account is the concatenation of the centralizing account number and auxiliary number' do
    client = create(:account, :client)
    assert client.number, client.centralizing_account.send(Account.accounting_system) + client.auxiliary_number
  end

  test 'invalid numbers' do
    account_1 = build(:account, number: '41123')
    account_2 = build(:account, number: '40123456789')
    account_3 = build(:account, number: '012345')
    account_4 = build(:account, number: '1')
    refute account_1.valid?
    refute account_2.valid?
    refute account_3.valid?
    refute account_4.valid?
  end
end
