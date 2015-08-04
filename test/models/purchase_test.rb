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
# == Table: purchases
#
#  accounted_at        :datetime
#  affair_id           :integer
#  amount              :decimal(19, 4)   default(0.0), not null
#  confirmed_at        :datetime
#  created_at          :datetime         not null
#  creator_id          :integer
#  currency            :string           not null
#  delivery_address_id :integer
#  description         :text
#  id                  :integer          not null, primary key
#  invoiced_at         :datetime
#  journal_entry_id    :integer
#  lock_version        :integer          default(0), not null
#  nature_id           :integer
#  number              :string           not null
#  planned_at          :datetime
#  pretax_amount       :decimal(19, 4)   default(0.0), not null
#  reference_number    :string
#  responsible_id      :integer
#  state               :string
#  supplier_id         :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#

require 'test_helper'

class PurchaseTest < ActiveSupport::TestCase
  # Add tests here...
end
