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
# == Table: sales
#
#  accounted_at        :datetime
#  address_id          :integer
#  affair_id           :integer
#  amount              :decimal(19, 4)   default(0.0), not null
#  annotation          :text
#  client_id           :integer          not null
#  computation_method  :string           not null
#  conclusion          :text
#  confirmed_at        :datetime
#  created_at          :datetime         not null
#  creator_id          :integer
#  credit              :boolean          default(FALSE), not null
#  credited_sale_id    :integer
#  currency            :string           not null
#  delivery_address_id :integer
#  description         :text
#  downpayment_amount  :decimal(19, 4)   default(0.0), not null
#  expiration_delay    :string
#  expired_at          :datetime
#  function_title      :string
#  has_downpayment     :boolean          default(FALSE), not null
#  id                  :integer          not null, primary key
#  initial_number      :string
#  introduction        :text
#  invoice_address_id  :integer
#  invoiced_at         :datetime
#  journal_entry_id    :integer
#  letter_format       :boolean          default(TRUE), not null
#  lock_version        :integer          default(0), not null
#  nature_id           :integer
#  number              :string           not null
#  payment_at          :datetime
#  payment_delay       :string           not null
#  pretax_amount       :decimal(19, 4)   default(0.0), not null
#  reference_number    :string
#  responsible_id      :integer
#  state               :string           not null
#  subject             :string
#  transporter_id      :integer
#  type                :string
#  updated_at          :datetime         not null
#  updater_id          :integer
#
require 'test_helper'

class SaleCreditTest < ActiveSupport::TestCase

  test_fixtures

end
