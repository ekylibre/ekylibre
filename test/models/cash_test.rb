# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: cashes
#
#  account_id           :integer          not null
#  bank_account_key     :string
#  bank_account_number  :string
#  bank_agency_address  :text
#  bank_agency_code     :string
#  bank_code            :string
#  bank_identifier_code :string
#  bank_name            :string
#  container_id         :integer
#  country              :string
#  created_at           :datetime         not null
#  creator_id           :integer
#  currency             :string           not null
#  custom_fields        :jsonb
#  iban                 :string
#  id                   :integer          not null, primary key
#  journal_id           :integer          not null
#  last_number          :integer
#  lock_version         :integer          default(0), not null
#  mode                 :string           default("iban"), not null
#  name                 :string           not null
#  nature               :string           default("bank_account"), not null
#  owner_id             :integer
#  spaced_iban          :string
#  updated_at           :datetime         not null
#  updater_id           :integer
#

require 'test_helper'

class CashTest < ActiveSupport::TestCase
  test_model_actions

  test "next reconciliation letters on a cash without bank statements starts from 'A'" do
    cash = cashes(:cashes_003)
    assert_equal %w(A B C), cash.next_reconciliation_letters.take(3)
  end

  test 'next reconciliation letters on a cash with bank statements starts from the letter succeeding the last reconciliation letter of the cash' do
    cash = cashes(:cashes_001)
    assert_equal %w(G), cash.next_reconciliation_letters.take(1)
  end

  test 'next reconciliation letters on a cash with bank statements can skip a letter if its already present' do
    cash = cashes(:cashes_001)
    assert_equal %w(G I J), cash.next_reconciliation_letters.take(3)
  end
end
