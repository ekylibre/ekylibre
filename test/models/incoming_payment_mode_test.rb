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
# == Table: incoming_payment_modes
#
#  active                  :boolean
#  cash_id                 :integer
#  commission_account_id   :integer
#  commission_base_amount  :decimal(19, 4)   default(0.0), not null
#  commission_percentage   :decimal(19, 4)   default(0.0), not null
#  created_at              :datetime         not null
#  creator_id              :integer
#  depositables_account_id :integer
#  depositables_journal_id :integer
#  detail_payments         :boolean          not null
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  name                    :string           not null
#  position                :integer
#  updated_at              :datetime         not null
#  updater_id              :integer
#  with_accounting         :boolean          not null
#  with_commission         :boolean          not null
#  with_deposit            :boolean          not null
#


require 'test_helper'

class IncomingPaymentModeTest < ActiveSupport::TestCase
  test_fixtures
end
