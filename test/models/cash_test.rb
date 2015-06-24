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
  # Add tests here...
end
