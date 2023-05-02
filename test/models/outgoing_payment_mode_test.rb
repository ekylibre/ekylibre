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
# == Table: outgoing_payment_modes
#
#  active          :boolean          default(FALSE), not null
#  cash_id         :integer(4)
#  created_at      :datetime         not null
#  creator_id      :integer(4)
#  id              :integer(4)       not null, primary key
#  lock_version    :integer(4)       default(0), not null
#  name            :string           not null
#  position        :integer(4)
#  sepa            :boolean          default(FALSE), not null
#  updated_at      :datetime         not null
#  updater_id      :integer(4)
#  with_accounting :boolean          default(FALSE), not null
#

require 'test_helper'

class OutgoingPaymentModeTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'valid if sepa and  with iban and account owner present' do
    outgoing_payment_mode = outgoing_payment_modes(:outgoing_payment_modes_003)
    assert outgoing_payment_mode.valid?
  end

  test 'invalid if sepa and with iban missing' do
    outgoing_payment_mode = outgoing_payment_modes(:outgoing_payment_modes_003)
    outgoing_payment_mode.cash.iban = ''
    assert_not outgoing_payment_mode.valid?
  end

  test 'invalid if sepa and with account owner missing' do
    outgoing_payment_mode = outgoing_payment_modes(:outgoing_payment_modes_003)
    outgoing_payment_mode.cash.bank_account_holder_name = ''
    assert_not outgoing_payment_mode.valid?
  end

  test 'valid if not sepa with iban and account owner missing' do
    outgoing_payment_mode = outgoing_payment_modes(:outgoing_payment_modes_003)
    outgoing_payment_mode.sepa = false
    outgoing_payment_mode.cash.iban = ''
    outgoing_payment_mode.cash.bank_account_holder_name = ''

    assert outgoing_payment_mode.valid?
  end
end
